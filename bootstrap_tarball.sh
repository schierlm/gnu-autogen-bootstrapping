#!/bin/sh -e

mkdir -p build/tarball build/stage1/bin build/stage1/lib/autogen build/prefix
PREFIX="$(pwd)/build/stage1"
FINALPREFIX="${FINALPREFIX:-$(pwd)/build/prefix}"
GUILE_VERSION="${GUILE_VERSION:-3.0}"

## Get the tarball, remove generated files, and patch required files.

if ! [ -f build/autogen-5.18.16.tar.xz ]; then
	echo "=== Downloading tarball ==="
	curl https://mirrors.kernel.org/gnu/autogen/rel5.18.16/autogen-5.18.16.tar.xz -o build/autogen-5.18.16.tar.xz
fi

if ! [ -d build/src ]; then
	echo "=== Retrieving missing files from repository ==="
	cd build
	curl https://git.savannah.gnu.org/cgit/autogen.git/snapshot/autogen-5.18.16.tar.gz -o autogen-5.18.16.tar.gz
	tar -xf autogen-5.18.16.tar.gz
	mv autogen-5.18.16 src
	cd src
	rm -f add-on/char-mapper/cm.tar
	cd ../..
fi

if ! [ -f build/autogen-5.18.16/ZZJUNK ]; then
	echo "=== Preparing tarball ==="
	tar -C build -xJf build/autogen-5.18.16.tar.xz
	cd build/autogen-5.18.16

	# copy char-mapper from git
	mkdir add-on
	cp -R ../src/add-on/char-mapper add-on

	# apply patches
	patch -p1 -i ../../mk-tpl-config.patch
	patch -p1 -i ../../mk-opt-table.patch

	# make guile-iface work with Guile 3
	sed -i "s/i-end = '203'/i-end = '400'/g" agen5/guile-iface.def

	# remove generated files
	rm aclocal.m4 ChangeLog config-h.in configure configure.ac COPYING Makefile.in NEWS TODO VERSION
	rm -f agen5/ag-text.c agen5/ag-text.h agen5/autogen.1 agen5/cgi-fsm.h agen5/defParse-fsm.c agen5/defParse-fsm.h
	rm -f agen5/directive.c agen5/directive.h agen5/expr.h agen5/expr.ini agen5/functions.h agen5/guile-iface.h
	rm -f agen5/invoke-autogen.texi agen5/Makefile.am agen5/Makefile.in agen5/opts.c agen5/opts.h agen5/proto.h
	rm -f agen5/pseudo-fsm.h agen5/test/Makefile.in
	rm -f autoopts/ag-char-map.h autoopts/ao_string_tokenize.3 autoopts/ao-strs.c autoopts/ao-strs.h
	rm -Rf autoopts/autoopts autoopts/po
	rm -f autoopts/autoopts-config.1 autoopts/autoopts-config.in autoopts/configFileLoad.3 autoopts/funcs.def
	rm -f autoopts/genshell.c autoopts/genshell.h autoopts/gettext.h autoopts/intprops.h autoopts/Makefile.am
	rm -f autoopts/Makefile.in autoopts/mk-autoopts-pc.in autoopts/_Noreturn.h autoopts/optionFileLoad.3
	rm -f autoopts/optionFindNextValue.3 autoopts/optionFindValue.3 autoopts/optionFree.3 autoopts/optionGetValue.3
	rm -f autoopts/optionLoadLine.3 autoopts/optionMemberList.3 autoopts/optionNextValue.3 autoopts/optionOnlyUsage.3
	rm -f autoopts/optionPrintVersion.3 autoopts/optionPrintVersionAndReturn.3 autoopts/optionProcess.3
	rm -f autoopts/optionRestore.3 autoopts/optionSaveFile.3 autoopts/optionSaveState.3 autoopts/optionUnloadNested.3
	rm -f autoopts/option-value-type.c autoopts/option-value-type.h autoopts/optionVersion.3 autoopts/option-xat-attribute.c
	rm -f autoopts/option-xat-attribute.h autoopts/parse-duration.c autoopts/parse-duration.h autoopts/proto.h
	rm -f autoopts/save-flags.c autoopts/save-flags.h autoopts/stdnoreturn.in.h autoopts/strequate.3 autoopts/streqvcmp.3
	rm -f autoopts/streqvmap.3 autoopts/strneqvcmp.3 autoopts/strtransform.3 autoopts/test/Makefile.in
	rm -f columns/Makefile.in columns/opts.c columns/opts.h
	rm -f compat/Makefile.in compat/strsignal.h
	rm -f config/asm-underscore.m4 config/compile config/config.guess config/config.rpath config/config.sub config/depcomp
	rm -f config/extensions.m4 config/gendocs.sh config/gnulib-cache.m4 config/gnulib-comp.m4 config/guile.m4
	rm -f config/host-cpu-c-abi.m4 config/install-sh config/lib-ld.m4 config/lib-link.m4 config/lib-prefix.m4 config/libtool.m4
	rm -f config/ltmain.sh config/lt~obsolete.m4 config/ltoptions.m4 config/ltsugar.m4 config/ltversion.m4 config/missing
	rm -f config/onceonly.m4 config/pkg.m4 config/snprintfv.m4 config/stdnoreturn.m4 config/test-driver config/texinfo.tex
	rm -f doc/agdoc.texi doc/autogen.info doc/autogen.info-1 doc/autogen.info-2 doc/autogen.texi doc/gendocs_template
	rm -f doc/invoke-autogen.texi doc/invoke-bitmaps.texi doc/invoke-columns.texi doc/invoke-getdefs.texi doc/invoke-snprintfv.texi
	rm -f doc/invoke-xml2ag.texi doc/libopts.texi doc/Makefile.in
	rm -f getdefs/Makefile.in getdefs/proto.h getdefs/test/defs getdefs/test/Makefile.in
	rm -f pkg/libopts/stdnoreturn.mk pkg/Makefile.am pkg/Makefile.in
	rm -f snprintfv/filament.h snprintfv/filament.stamp snprintfv/Makefile.in snprintfv/printf.h snprintfv/printf.stamp
	rm -f snprintfv/stream.h snprintfv/stream.stamp
	rm -f xml2ag/fork.c xml2ag/Makefile.in xml2ag/test/Makefile.in xml2ag/xmlopts.c

	# clean up partially generated files
	sed -n '/\/\* START/,/\/\* END/p' -i agen5/cgi-fsm.c

	# we need to copy some files from git ...
	cp ../src/agen5/functions.tpl ../src/agen5/Makefile.am.pre agen5
	cp ../src/autoopts/aoconf.def ../src/autoopts/aoconf.tpl ../src/autoopts/Makefile.am.pre ../src/autoopts/options_h.tpl \
	   ../src/autoopts/opt-state.def ../src/autoopts/proc-state.def ../src/autoopts/save-flags.def ../src/autoopts/usage-txt.def \
	   ../src/autoopts/usage-txt.tpl autoopts
	cp ../src/columns/bootstrap.dir columns
	cp ../src/getdefs/bootstrap.dir getdefs
	cp ../src/configure.ac.pre  ../src/NEWS.pre ../src/TODO-top ../src/VERSION.pre .
	cp ../src/pkg/Makefile.am.pre pkg
	cp ../src/snprintfv/bootstrap.dir ../src/snprintfv/snprintfv.m4 snprintfv

	# tag the source
	echo '5.18.987' > ZZJUNK
	cd ../..
fi

echo "=== Bootstrapping columns ==="

rm -R build/tarball
cp -ar build/autogen-5.18.16 build/tarball
cd build/tarball
patch -p1 -i ../../columns.patch
cd columns
gcc columns.c -o "${PREFIX}/bin/columns"
cd ../../..

echo "=== Bootstrapping getdefs ==="

rm -R build/tarball
cp -ar build/autogen-5.18.16 build/tarball
cd build/tarball
patch -p1 -i ../../getdefs.patch
cd getdefs
gcc -std=gnu99 getdefs.c -I ../../.. -o "${PREFIX}/bin/getdefs"
cd ../../..

echo "=== Bootstrapping autogen ==="

rm -R build/tarball
cp -ar build/autogen-5.18.16 build/tarball
cd build/tarball
patch -p1 -i ../../autogen.patch
cd snprintfv
bash bootstrap.dir
cd ../agen5
perl ../../../build-ag-text.pl
"${PREFIX}/bin/getdefs" output=functions.def template=functions.tpl srcfile linenum defs=macfunc listattr=alias $(grep -l '/\*=macfunc' *.c)
"${PREFIX}/bin/getdefs" load=expr.cfg
sed -n '/^doDir_invalid/d;/^doDir_[a-z]*(/{;s@(.*@@;s@^doDir_@@;p;}' defDirect.c | sort >directive_in.def
perl ../../../build-indirect-templates.pl
gcc ../../../getGuileVersion.c $(pkg-config guile-"${GUILE_VERSION}" --cflags) -o getGuileVersion
gcc -std=gnu99 -DGUILE_VERSION=$(./getGuileVersion) -DLIBDATADIR=\"$PREFIX/lib/autogen\" ../../../agBootstrap.c -I . -I .. -I ../../.. $(pkg-config guile-"${GUILE_VERSION}" --cflags) -o $PREFIX/bin/autogen $(pkg-config guile-"${GUILE_VERSION}" --libs)
cd ../../..

echo "=== Bootstrapping tpl-config.tlib ==="

export PATH="$PREFIX/bin:$PATH"

rm -R build/tarball
cp -ar build/autogen-5.18.16 build/tarball
cd build/tarball
sed 's/@EGREP@/egrep/g;s/@GREP@/grep/g' <autoopts/tpl/tpl-config-tlib.in >"${PREFIX}/lib/autogen/tpl-config.tlib"
cp autoopts/tpl/*.lic "${PREFIX}/lib/autogen"
SOURCE_DIR="$(pwd)" ./config/bootstrap
./configure --prefix="$PREFIX" --disable-dependency-tracking
cd autoopts
make tpl-config-stamp
cp tpl/tpl-config.tlib "${PREFIX}/lib/autogen/tpl-config.tlib"
cd ../../..

echo "=== Compiling and testing package ==="

rm -R build/tarball
cp -ar build/autogen-5.18.16 build/tarball
cd build/tarball
SOURCE_DIR="$(pwd)" ./config/bootstrap
./configure --prefix="$FINALPREFIX" --disable-dependency-tracking
touch doc/agdoc.texi # build later
make CFLAGS=-Wno-error
make check
make install
cd doc
PATH="$FINALPREFIX/bin:$PATH"
rm agdoc.texi
make
make install
cd ../../..

echo "=== BOOTSTRAP COMPLETE ==="
