# gnu-autogen-bootstrapping
Bootstrapping GNU Autogen without relying on pre-expanded code

This code is, as the original project, licensed under GNU General Public Licence, version 3 or later.

## Challenge

GNU Autogen is a template processor which is used extensively for creating its own source code.
The included bootstrapping script requires that the binaries `autogen`, `getdefs` and `columns`
(using an older version is possible), as well as the template library `tpl-config.tlib`, are already present.

These binaries are then used to bootstrap the source code, which is later packaged to become the
release tarball.

There are (at least) two files in the source tree (copyright update tool and CGI support), where the output file
is at the same time one of the input file; tagged lines in the file are copied from the (old) output file
to the (new) output file during template processing.

All the programs in the Autogen package use AutoOpts, which is also written in AutoGen, as command line
parsing library. They also use generated `proto.h` files which include the prototypes extracted from the `.c`
files.

To complicate matters more, the bootstrap scripts require the current source to be committed to git, with
an annotated tag attached to the HEAD commit whose name has to follow autogen's version conventions. And
the scripts depend on some lines that get generated in the autoconf scripts, which are not there in the same
order when regenerating those files using the Autoconf versions included in Debian bullseye.

Comparably trivial: To build some parts of Autogen, GUILE_VERSION needs to be defined as a decimal constant,
using two digits for the minor and three digits for the patch version. Just have a small C program output
the required definition after reading the version number from `<libguile/version.h>`.

## Bootstrap binaries

To work around these challenges, we first build bootstrap versions of the three binaries with reduced
functionality, yet powerful enough to run the bootstrap scripts.

The initial template library is built using a `sed` script (initial bootstrap does not need many parts of it) and is
regenerated as soon as the configure scripts have run successfully.

The source code is patched to work around the autoconf line order issue, and committed to (local) git with tag `v5.18.987`.

All required `.c` files are all included in one main C file, and prototype headers are written manually (only including those
prototypes that are actually required as forward declarations)

## `columns`

Starting with the easiest binary, `columns`. This binary "just" uses AutoOpts and very few prototypes.

## `getdefs`

`getdefs` also depends on prototypes and AutoOpts (including the streqvcmp function, which fortunately can be `#include`d directly);
it also uses the Char Mapper, which is a huge lookup table for faster character classification and scanning. As the Char Mapper is
also required extensively in `autogen`, its logic has been rewritten in pure C (with some preprocessor magic) without requiring
any code generation, as `agCharMap.c`. It is obviously slower than the lookup table approach, but in my opinion easier to read than
the original templates (and of course easier to read than the generated lookup tables).

## `autogen`

Prototypes and autoopts and streqvcmp and char mapper have to be handled here as well. As prototypes are used a bit more than in the
previous programs, they have been put into a separate "agProto.h" file, and bootstrap defines (usually coming from autoconf) went
to `agBootstrap.c` alongside to the definitions used by the remaining parts of AutoOpts. If you are using an unusual setup, you
may have to change some defines in there, but the compile errors are obvious enough to find out what to change.

`snprintfv` comes with its own bootstrap script, which fortunately does not depend on the autogen binary.

Then there is `ag-text.[hc]`, a huge string table generated by autogen. The generation has been replaced by a Perl script.

There are also two state machines (`defParse.def`, `pseudo.def`) containing huge sparse transition arrays. They have been replaced
by implementing the logic in pure C (like the char mapper).

Last but not least, there are files generated from three generated lists (list of directives, list of functions, list of expressions).
The list of expressions is generated by a sed script, the other two are generated by `getdefs` (already bootstrapped).
The files generated from these files were bootstrapped by another Perl script.
