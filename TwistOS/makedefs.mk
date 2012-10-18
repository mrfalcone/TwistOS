#=================================================
# Standard definitions for Twist OS makefiles
#=================================================

osBasePath=~/TwistOS

COMPILER=/usr/cross/i586-elf/bin/g++
COMPILERFLAGS=-fcheck-new -nostdinc -c -idirafter $(STDINCPATH)

LINKER=/usr/cross/i586-elf/bin/ld
LINKERFLAGS=-nostdlib

ASSEMBLER=nasm
ASSEMBLERFLAGS=-f elf32


EXT=ebc


CRTPATH=$(osBasePath)/src/_cstd/lib/CRT
STDOBJPATH=$(osBasePath)/src/_cstd/lib
STDINCPATH=$(osBasePath)/src/_cstd/include

