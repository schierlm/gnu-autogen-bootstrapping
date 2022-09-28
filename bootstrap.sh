#!/bin/sh -e

PREFIX="$(pwd)/build/stage1"
FINALPREFIX="${FINALPREFIX:-$(pwd)/build/prefix}"
GUILE_VERSION="${GUILE_VERSION:-3.0}"

main() {
	prepare_repository
	bootstrap_columns
	bootstrap_getdefs
	bootstrap_autogen
	bootstrap_tpl_config
	rebuild_autogen
}

prepare_repository() {
	## Get the git repository, remove generated files, and patch required files.

	if ! [ -f build/tagged-src ]; then
		echo "=== Preparing repository ==="
		mkdir -p build
		cd build
		rm -Rf src
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
}

bootstrap_columns() {
	echo "=== Bootstrapping columns ==="

	mkdir -p build/stage1/bin
	cd build/src
	git clean -fdx
	git restore --staged --worktree :/
	patch -p1 -i ../../columns.patch
	cd columns
	"${CC:-gcc}" ${CFLAGS} columns.c -o "${PREFIX}/bin/columns"
	cd ../../..
}

bootstrap_getdefs() {
	echo "=== Bootstrapping getdefs ==="

	cd build/src
	git clean -fdx
	git restore --staged --worktree :/
	patch -p1 -i ../../getdefs.patch
	cd getdefs
	"${CC:-gcc}" ${CFLAGS} -std=gnu99 getdefs.c -I ../../.. -o "${PREFIX}/bin/getdefs"
	cd ../../..
}

bootstrap_autogen() {
	echo "=== Bootstrapping autogen ==="

	cd build/src
	git clean -fdx
	git restore --staged --worktree :/
	patch -p1 -i ../../autogen.patch
	cd snprintfv
	bash bootstrap.dir
	cd ../agen5
	perl ../../../build-ag-text.pl
	"${PREFIX}/bin/getdefs" output=functions.def template=functions.tpl srcfile linenum defs=macfunc listattr=alias $(grep -l '/\*=macfunc' *.c)
	"${PREFIX}/bin/getdefs" load=expr.cfg
	sed -n '/^doDir_invalid/d;/^doDir_[a-z]*(/{;s@(.*@@;s@^doDir_@@;p;}' defDirect.c | sort >directive_in.def
	perl ../../../build-indirect-templates.pl
	"${CC:-gcc}" ${CFLAGS} ../../../getGuileVersion.c $(pkg-config guile-"${GUILE_VERSION}" --cflags) -o getGuileVersion
	"${CC:-gcc}" ${CFLAGS} -std=gnu99 -DGUILE_VERSION=$(./getGuileVersion) -DLIBDATADIR=\"$PREFIX/lib/autogen\" ../../../agBootstrap.c -I . -I .. -I ../../.. $(pkg-config guile-"${GUILE_VERSION}" --cflags "${GUILE_STATIC}") -o $PREFIX/bin/autogen $(pkg-config guile-"${GUILE_VERSION}" --libs "${GUILE_STATIC}")
	cd ../../..
}

bootstrap_tpl_config() {
	echo "=== Bootstrapping tpl-config.tlib ==="

	mkdir -p build/stage1/lib/autogen
	cd build/src
	export PATH="$PREFIX/bin:$PATH"

	git clean -fdx
	git restore --staged --worktree :/
	sed 's/@EGREP@/egrep/g;s/@GREP@/grep/g' <autoopts/tpl/tpl-config-tlib.in >"${PREFIX}/lib/autogen/tpl-config.tlib"
	cp autoopts/tpl/*.lic "${PREFIX}/lib/autogen"
	SOURCE_DIR="$(pwd)" ./config/bootstrap
	./configure --prefix="$PREFIX" --disable-dependency-tracking ${CONFIGURE_FLAGS}
	cd autoopts
	make tpl-config-stamp
	cp tpl/tpl-config.tlib "${PREFIX}/lib/autogen/tpl-config.tlib"
	cd ../../..
}

rebuild_autogen() {
	echo "=== Compiling and testing package ==="

	cd build/src
	git clean -fdx
	git restore --staged --worktree :/
	export MAN_PAGE_DATE=1970-01-01
	SOURCE_DIR="$(pwd)" ./config/bootstrap
	./configure --prefix="$FINALPREFIX" --disable-dependency-tracking --enable-timeout=15 ${CONFIGURE_FLAGS}
	touch doc/agdoc.texi # build later
	make CFLAGS=-Wno-error
	make check
	make DESTDIR="${DESTDIR}" install
	cd doc
	PATH="$FINALPREFIX/bin:$PATH"
	rm agdoc.texi
	make
	make DESTDIR="${DESTDIR}" install
	cd ../../..

	echo "=== BOOTSTRAP COMPLETE ==="
}

if [ -z "${SKIP_MAIN}" ]; then
    main "$@"
fi
