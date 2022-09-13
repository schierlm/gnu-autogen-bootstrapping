#!/bin/sh -e

mkdir -p build/src build/stage1/bin build/stage1/lib/autogen build/prefix
PREFIX="$(pwd)/build/stage1"
FINALPREFIX="${FINALPREFIX:-$(pwd)/build/prefix}"

## Get the git repository, remove generated files, and patch required files.

if ! [ -f build/tagged-src ]; then
	echo "=== Preparing repository ==="
	cd build
	rm -R src
	git clone --single-branch -b v5.18.16 https://git.savannah.gnu.org/git/autogen.git src
	cd src
	git checkout -b work
	patch -p1 -i ../../mk-tpl-config.patch
	patch -p1 -i ../../mk-opt-table.patch

	# make guile-iface work with Guile 3
	sed -i "s/i-end = '203'/i-end = '400'/g" agen5/guile-iface.def

	# add one more file to .gitignore (gnulib would add it and break the build)
	echo '/zzgnulib.m4' >>config/.gitignore

	# remove generated files
	git rm add-on/char-mapper/cm.tar agen5/agen5.tgz autoopts/gen-src.tgz
	git rm columns/columns-opts.tgz compat/strsignal.h.gz config/gen-files.tar.gz

	# clean up partially generated files
	sed -n '/\/\* START/,/\/\* END/p' -i add-on/cright-update/collapse.c agen5/cgi-fsm.c

	# tag the source
	GIT_AUTHOR_NAME='Boot Strap' GIT_AUTHOR_EMAIL='boot@strap' GIT_COMMITTER_NAME='Boot Strap' GIT_COMMITTER_EMAIL='boot@strap' git commit -a -m 'Commit code to be bootstrapped'
	GIT_AUTHOR_NAME='Boot Strap' GIT_AUTHOR_EMAIL='boot@strap' GIT_COMMITTER_NAME='Boot Strap' GIT_COMMITTER_EMAIL='boot@strap' git tag -a v5.18.987 -m 'Tag code to be bootstrapped'

	# source is done and tagged
	cd ..
	touch tagged-src
	cd ..
fi

cd build/src

echo "=== Bootstrapping columns ==="

git clean -fdx
git restore --staged --worktree :/
patch -p1 -i ../../columns.patch
cd columns
gcc columns.c -o $PREFIX/bin/columns
cd ..

echo "=== Bootstrapping getdefs ==="

git clean -fdx
git restore --staged --worktree :/
patch -p1 -i ../../getdefs.patch
cd getdefs
gcc getdefs.c -I ../../.. -o $PREFIX/bin/getdefs
cd ..

echo "=== Bootstrapping autogen ==="

git clean -fdx
git restore --staged --worktree :/
patch -p1 -i ../../autogen.patch
cd snprintfv
bash bootstrap.dir
cd ../agen5
perl ../../../build-ag-text.pl
$PREFIX/bin/getdefs output=functions.def template=functions.tpl srcfile linenum defs=macfunc listattr=alias $(grep -l '/\*=macfunc' *.c)
$PREFIX/bin/getdefs load=expr.cfg
sed -n '/^doDir_invalid/d;/^doDir_[a-z]*(/{;s@(.*@@;s@^doDir_@@;p;}' defDirect.c | sort >directive_in.def
perl ../../../build-indirect-templates.pl
gcc ../../../getGuileVersion.c $(pkg-config guile-3.0 --cflags) -o getGuileVersion
gcc -DGUILE_VERSION=$(./getGuileVersion) -DLIBDATADIR=\"$PREFIX/lib/autogen\" ../../../agBootstrap.c -I . -I .. -I ../../.. $(pkg-config guile-3.0 --cflags) -o $PREFIX/bin/autogen $(pkg-config guile-3.0 --libs)
cd ..

echo "=== Bootstrapping tpl-config.tlib ==="

export PATH="$PREFIX/bin:$PATH"

git clean -fdx
git restore --staged --worktree :/
sed 's/@EGREP@/egrep/g;s/@GREP@/grep/g' <autoopts/tpl/tpl-config-tlib.in >$PREFIX/lib/autogen/tpl-config.tlib
cp autoopts/tpl/*.lic $PREFIX/lib/autogen
SOURCE_DIR="$(pwd)" ./config/bootstrap
./configure --prefix=$PREFIX --disable-dependency-tracking
cd autoopts
make tpl-config-stamp
cp tpl/tpl-config.tlib $PREFIX/lib/autogen/tpl-config.tlib
cd ..

echo "=== Compiling and testing package ==="

git clean -fdx
git restore --staged --worktree :/
SOURCE_DIR="$(pwd)" ./config/bootstrap
./configure --prefix=$FINALPREFIX --disable-dependency-tracking
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
