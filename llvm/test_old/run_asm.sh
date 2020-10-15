#!/bin/sh
# 引数の.sファイルをアセンブル、リンクし、gdb simで実行する
# 実行時./asm/start.sファイルが存在する必要がる

RXPREFIX="${HOME}/rx-binutils/bin/rx-elf-"
RXAS="${RXPREFIX}as"
RXLD="${RXPREFIX}ld"
RXGDB="${RXPREFIX}gdb"
RXSTART="./asm/start.s"

if [ $# -ne 1 ]; then
    echo "Error: args"
    echo "Usage: ./run_asm.sh <asm-file>"
    exit 1
fi

SRC="$1"
OBJ="$(basename $SRC).o"
ELF="$(basename $SRC).elf"

set -e

# temp dir
atexit() {
  test -n "$tmpdir" && rm -rf "$tmpdir"
}
trap atexit EXIT
tmpdir=$(mktemp -d)

# build
$RXAS $RXSTART -o $tmpdir/start.o
$RXAS $SRC -o $tmpdir/$OBJ
$RXLD $tmpdir/start.o $tmpdir/$OBJ -o $tmpdir/$ELF

# simulator
$RXGDB -q $tmpdir/$ELF \
       -ex "set pagination off" \
       -ex "set confirm off" \
       -ex "target sim" \
       -ex "load" \
       -ex "run" \
       -ex "i r" \
       -ex "q"
