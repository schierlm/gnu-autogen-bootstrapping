#!/usr/bin/perl

# Copyright (C) 2022 Michael Schierl
#
# AutoGen is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Script to build indirect templates (depending on getdefs output).
# These are directive.h, functions.h, expr.h and expr.ini.

use warnings;
use strict;

my @directives = ();

open(my $in, "<", "directive_in.def") or die $!;
while(my $L=<$in>) {
	chomp $L;
	push @directives, $L;
}
close $in;

open(my $out, ">", "directive.h") or die $!;
print $out <<'_EOF_';
typedef enum {
    DIR_INVALID = 0,
_EOF_
print $out "    DIR_" . (uc $_) . ",\n" for @directives;
print $out <<'_EOF_';
    DIR_COUNT
} directive_enum_t;

static char const * const directive_nm_table[] = {
_EOF_
print $out '    [DIR_' . (uc $_) . '] = "' . $_ .'",' . $/ for @directives;
print $out <<'_EOF_';
    [DIR_COUNT] = ""
};

typedef char * (doDir_hdl_t)(directive_enum_t, char const *, char *);

doDir_hdl_t
_EOF_
print $out "    doDir_" . $_ . ",\n" for @directives;
print $out <<'_EOF_';
    doDir_invalid;

static doDir_hdl_t * const directive_dispatch[] = {
_EOF_
print $out "    [DIR_" . (uc $_) . "] = doDir_" . $_ .",\n" for @directives;
print $out <<'_EOF_';
    [DIR_INVALID] = doDir_invalid
};

static unsigned int directive_keywd_len[] = {
_EOF_
print $out "    [DIR_" . (uc $_) . "] = " . (length $_) .",\n" for @directives;
print $out <<'_EOF_';
    [DIR_INVALID] = 0
};
_EOF_

close $out;

my @functions = ();
my %function_attrs = ();
my %function_load_procs = ('Ending' => 1);
my %function_hdlr_procs = ();
my %function_unld_procs = ();
my %function_aliases = ();
my %function_names = ();

open($in, "<", "functions.def") or die $!;
my $L = <$in>;
while($L !~ /^autogen definitions/) {
	$L = <$in>;
}
while($L=<$in>) {
	chomp $L;
	next if $L eq '' or $L =~ '^#line';
	die $L unless $L eq 'macfunc = {';
	chomp ($L=<$in>);
	die $L unless $L =~ /^    name    = '([A-Z]+)';$/;
	my $name = $1;
	push @functions, $name;
	while($L=<$in>) {
		chomp $L;
		if ($L =~ /^    (what|srcfile|linenum|cindex) = '.*';$/) {
			# ignore
		} elsif ($L =~ /^    desc =$/) {
			# skip description
			chomp ($L=<$in>);
			while ($L !~ /';$/) {
				chomp ($L=<$in>);
			}
		} elsif ($L =~ /^    (unnamed|in[_-]context);$/) {
			my $key = $1; $key =~ s/-/_/g;
			$function_attrs{$name.':'.$key} = 1;
		} elsif ($L =~ /^    (handler[_-]proc|(?:un)?load[_-]proc);$/) {
			my $key = $1; $key =~ s/-/_/g;
			$function_attrs{$name.':'.$key} = ucfirst(lc($name));
		} elsif ($L =~ /^    (handler[_-]proc|(?:un)?load[_-]proc) = '(.*)';$/) {
			my $key = $1; my $value=$2; $key =~ s/-/_/g;
			$function_attrs{$name.':'.$key} = $value;
		} elsif ($L =~ /^    (alias) = (.*);$/) {
			my $value = $2;
			my @aliases = ();
			my $idx = 1;
			while($idx < length $value) {
				my $char = substr($value, $idx, 1);
				push @aliases, $char;
				$function_aliases{$char} = $name;
				$idx += 4;
			}
			$function_attrs{$name.':aliascount'} = scalar @aliases;
		} elsif ($L eq '};') {
			last;
		} else {
			die $L;
		}
	}
	$function_load_procs{$function_attrs{$name.':load_proc'}} = 1 if (defined $function_attrs{$name.':load_proc'});
	$function_hdlr_procs{$function_attrs{$name.':handler_proc'}} = 1 if (defined $function_attrs{$name.':handler_proc'});
	$function_unld_procs{$function_attrs{$name.':unload_proc'}} = 1 if (defined $function_attrs{$name.':unload_proc'});
	$function_names{$name} = 1 unless defined $function_attrs{$name.':unnamed'} or defined $function_attrs{$name.':aliascount'};
	die $L unless $L =~ /^\};$/;
}
close $in;

open($out, ">", "functions.h") or die $!;
print $out '#define FUNC_CT ' . (scalar @functions) . $/;
print $out "\ntypedef enum {\n";
print $out '    FTYP_' . $_ . ",\n" for @functions;
print $out "} mac_func_t;\n\n";
my @list = sort keys %function_hdlr_procs;
print $out 'hdlr_proc_t mFunc_' . ucfirst(lc($_)) . ";\n" for @list;
print $out $/;
@list = sort keys %function_load_procs;
print $out 'load_proc_t mLoad_' . ucfirst(lc($_)) . ";\n" for @list;
print $out "\nstatic load_proc_p_t const base_load_table[FUNC_CT] = {\n";
for(@functions) {
	my $lp = 'Unknown /*default*/';
	if (defined $function_attrs{$_.':load_proc'}) {
		$lp = $function_attrs{$_.":load_proc"};

	} elsif (defined $function_attrs{$_.':in_context'}) {
		$lp = 'Bogus /*dynamic*/';
	}
	print $out "    /* ".$_." */ mLoad_". $lp . ",\n";
}
print $out "};\n\nload_proc_p_t const * load_proc_table = base_load_table;\n\n";
print $out "typedef struct fn_name_type fn_name_type_t;\nstruct fn_name_type {\n    size_t cmpLen;\n    char const * pName;\n    mac_func_t fType;\n};\n\n";
print $out "#define FUNC_ALIAS_LOW_INDEX 0\n";
print $out "#define FUNC_ALIAS_HIGH_INDEX " . ((scalar %function_aliases) - 1) . "\n";
print $out "#define FUNC_NAMES_LOW_INDEX " . (scalar %function_aliases) . "\n";
print $out "#define FUNC_NAMES_HIGH_INDEX " . ((scalar %function_aliases) + (scalar %function_names) - 1) . "\n";
print $out "#define FUNCTION_NAME_CT " . ((scalar %function_aliases) + (scalar %function_names)) . "\n\n";
print $out "static fn_name_type_t const fn_name_types[FUNCTION_NAME_CT] = {\n";
@list = sort keys %function_aliases;
for(@list) {
	my $n = $_;
	$n = '\"' if $n eq '"';
	print $out "    { " . (length $_) . ', "' . $n . '", FTYP_' . $function_aliases{$_} . " },\n";
}
print $out $/;
@list = sort keys %function_names;
print $out "    { " . (length $_) . ', "' . $_ . '", FTYP_' . $_ . " },\n" for @list;
print $out "};\n\nstatic char const * const ag_fun_names[FUNC_CT] = {\n";
for(@functions) {
	my $n = $_;
	$n = ucfirst(lc($n)) if defined $function_attrs{$_.":unnamed"};
	print $out '    "'. $n . '",'.$/;
}
print $out "};\n\nstatic hdlr_proc_p_t const load_procs[FUNC_CT] = {\n";
for(@functions) {
	my $lp = 'Bogus';
	if (defined $function_attrs{$_.':handler_proc'}) {
		$lp = $function_attrs{$_.":handler_proc"};
	}
	print $out "    /* ".$_." */ mFunc_". $lp . ",\n";
}
print $out "};\n\n";
@list = sort keys %function_unld_procs;
print $out "unload_proc_t mUnload_".$_.";\n" for @list;
print $out "\nstatic unload_proc_p_t const unload_procs[FUNC_CT] = {\n";
for(@functions) {
	if (defined $function_attrs{$_.':unload_proc'}) {
		print $out "    mUnload_". $function_attrs{$_.':unload_proc'} . ",\n";
	} else {
		print $out "    NULL,\n";
	}
}
print $out "};\n\n#define FUNCTION_CKSUM 0xFFFF\n";
close $out;

my @expressions = ();
my %expression_attrs = ();

open($in, "<", "expr.def") or die $!;
$L = <$in>;
while($L !~ /^addtogroup += "autogen";/) {
	$L = <$in>;
}
while($L=<$in>) {
	chomp $L;
	next if $L eq '' or $L =~ '^#line';
	die $L unless $L eq 'gfunc = {';
	chomp ($L=<$in>);
	die $L unless $L =~ /^    name    = '([a-z_]+)';$/;
	my $name = $1;
	push @expressions, $name;
	$expression_attrs{$name.":argcount"} = 0;
	$expression_attrs{$name.":optcount"} = 0;
	$expression_attrs{$name.":restcount"} = 0;
	while($L=<$in>) {
		chomp $L;
		if ($L =~ /^    (what|srcfile) = '.*';$/) {
			# ignore
		} elsif ($L =~ /^    general[-_]use;$/) {
			# ignore
		} elsif ($L =~ /^    string = "([^"]+)";$/) {
			$expression_attrs{$name.':string'} = $1;
		} elsif ($L =~ /^    (doc|NOTE) =( ["'].*)?$/) {
			# skip description
			chomp ($L=<$in>);
			while ($L !~ /['"];$/) {
				chomp ($L=<$in>);
			}
		} elsif ($L eq "    exparg = {") {
			$expression_attrs{$name.":argcount"}++;
			my $optional = 0;
			my $list = 0;
			chomp ($L=<$in>);
			while ($L ne "    };") {
				$list = 1 if $L =~ /arg[-_]list = '/;
				$optional = 1 if $L =~ /arg[-_]optional = '/;
				chomp ($L=<$in>);
			}
			if ($list) {
				$expression_attrs{$name.":restcount"}++;
			} elsif ($optional) {
				$expression_attrs{$name.":optcount"}++;
			}
		} elsif ($L eq '};') {
			last;
		} else {
			die $L;
		}
	}
	die $L unless $L =~ /^\};$/;
}
close $in;

open($out, ">", "expr.h") or die $!;
for(@expressions) {
	my $argcount = $expression_attrs{$_.":argcount"};
	my $args="void";
	if ($argcount > 0) {
		$args="SCM";
		$args .= ", SCM" for(2..$argcount);
	}
	print $out "extern SCM ag_scm_".$_."(".$args.");\n";
}
close $out;

open($out, ">", "expr.ini") or die $!;
print $out "#define NEW_PROC(_As, _Ar, _Ao, _Ax, _An) scm_c_define_gsubr((char *)(_As), _Ar, _Ao, _Ax, (scm_callback_t)VOIDP(ag_scm_ ## _An))\n\n";
print $out "void ag_init(void) {\n";
for(@expressions) {
	my $scmname = $_;
	$scmname =~ s/_p$/?/;
	$scmname =~ s/_x$/!/;
	$scmname =~ s/_/-/g;
	$scmname =~ s/-to-/->/;
	$scmname = $expression_attrs{$_.":string"} if defined $expression_attrs{$_.":string"};
	my $argcount = $expression_attrs{$_.":argcount"};
	my $optcount = $expression_attrs{$_.":optcount"};
	my $restcount = $expression_attrs{$_.":restcount"};
	print $out '    NEW_PROC("' . $scmname. '", ' . ($argcount-$optcount-$restcount) . ", " . $optcount . ", " . $restcount .", " . $_ . ");\n";
}
print $out "}\n#undef NEW_PROC\n";
close $out;
