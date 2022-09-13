#!/usr/bin/perl

# Copyright (C) 2022 Michael Schierl
#
# AutoGen is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Script to build ag-text string table.

use warnings;
use strict;

my $offs = 10;
my @definitions = ();
my %prevvalues = ();

sub countunescaped {
	my $str = $_[0];
	$str =~ s/\\\\/x/g;
	$str =~ s/\\n/x/g;
	$str =~ s/\\t/x/g;
	$str =~ s/\\t/x/g;
	$str =~ s/\\"/x/g;
	die $str if $str =~ /\\/;
	return length $str;
}

push @definitions, '#define AG_TEXT_STRTABLE_FILE        (ag_text_strtable+0)'.$/, '#define AG_TEXT_STRTABLE_FILE_LEN    9'.$/;

open(my $out, ">", "ag-text.c") or die $!;
print $out <<'_EOF_';
#include "ag-text.h"

char const ag_text_strtable[] =
/*     0 */ "ag-text.c\0"
_EOF_

open(my $in, "<", "ag-text.def") or die $!;
while(my $l=<$in>) {
	next if $l !~ /^string = /;
	$l =~ s/\}; \/\/[a-zA-Z0-9 ]+$/\};/;
	OUTER:
	while ($l !~ /\};$/) {
		chomp $l;
		for my $marker ("EOF", "EOStr", "GP_Script") {
			if ($l =~ /<<- _${marker}_$/) {
				$l =~ s/<<- _${marker}_/"/;
				my $n = <$in>;
				$n =~ s/\\/\\\\/g;
				$n =~ s/"/\\"/g;
				$n =~ s/\t/\\t/g;
				$n =~ s/^\\t//;
				while ($n !~ /^_${marker}_/) {
					chomp $n;
					$l = $l . $n . "\\n";
					$n = <$in>;
					$n =~ s/\\/\\\\/g;
					$n =~ s/"/\\"/g;
					$n =~ s/\t/\\t/g;
					$n =~ s/^(\\t|\\n)*(\\\\)?//;
				}
				$n =~ s/^_${marker}_/"/;
				$l =~ s/\\n$//;
				$n =~ s/^_${marker}_ /"/;
				$l = $l . $n;
				next OUTER;
			}
		}
		$l = $l . <$in>;
		$l =~ s/\}; \/\/[a-zA-Z0-9 ]+$/\};/;
	}
	$l =~ s/"[ \t]+"([^;])/$1/g;
	my $nm;
	my $st;
	if ($l =~ m/^string = \{ nm = ([A-Za-z0-9_]+);[ \t]*str = ([A-Za-z_]+); ?\};$/) {
		$nm=$1; $st=$2;
	} elsif ($l =~ m/^string = \{ nm = ([A-Za-z0-9_]+);[ \t]*str = *"((?:[^"\\]|\\\\|\\t|\\n|\\")*)"; ?\};$/) {
		$nm = $1; $st = $2;
	} elsif ($l =~ m/string = \{ nm = ([A-Za-z0-9_]+); define-line-no; str = `([^`]*)`; };/) {
		$nm = $1;
		my $script = $2;
		$script =~s/\$\{AG_VERSION\}/5.18.16/g;
		$script =~s/\$\{srcdir\}/./g;
		$script =~s/\\ / /g;
		$st = `$script`;
		$st =~ s/\\/\\\\/g;
		$st =~ s/\n/\\n/g;
		$st =~ s/\t/\\t/g;
		$st =~ s/"/\\"/g;
	} else {
		die $l;
	}
	my $slen = countunescaped($st);
	if (exists $prevvalues{$st}) {
		my $def1 = sprintf '#define %-28s (ag_text_strtable+%d)'.$/, $nm, $prevvalues{$st};
		my $def2 = sprintf '#define %-28s %d'.$/, $nm."_LEN", $slen;
		push @definitions, ($def1, $def2);
		next;
	}
	$prevvalues{$st} = $offs;
	#print $nm . " = " . $st . $/;
	printf $out '/* %5d */ "', $offs;
	$st =~ s/\\t/\t/g;
	while ($st =~ /\\n(?=[^\\])/) {
		my ($st1, $st2) = split(/\\n(?=[^\\])/, $st, 2);
		last if $st2 eq '';
		$st1 =~ s/\t/\\t/g;
		printf $out '%s\\n"'.$/.'            "', $st1;
		$st = $st2;
	}
	$st =~ s/\t/\\t/g;
	printf $out '%s\\0"'.$/, $st;
	my $def1 = sprintf '#define %-28s (ag_text_strtable+%d)'.$/, $nm, $offs;
	my $def2 = sprintf '#define %-28s %d'.$/, $nm."_LEN", $slen;
	push @definitions, ($def1, $def2);
	$offs += $slen + 1;
}
close $in;
print $out "/* $offs".' */ "";'.$/.$/.'/* end of ag-text.c */'.$/;
close $out;

open($out, ">", "ag-text.h") or die $!;
print $out <<'_EOF_';
#ifndef STRINGS_AG_TEXT_H_GUARD
#define STRINGS_AG_TEXT_H_GUARD 1
/*
_EOF_
print $out " * ". (scalar(@definitions) / 2) . " strings in ag_text_strtable string table".$/." */".$/;
print $out sort @definitions;
print $out "extern char const ag_text_strtable[".($offs+1)."];".$/;
print $out <<'_EOF_';

#define SCHEME_INIT_TEXT_LINENO         434

#endif /* STRINGS_AG_TEXT_H_GUARD */
_EOF_
close $out;
