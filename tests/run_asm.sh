#!/bin/sh
# RX用の アセンブル、リンク、gdb simで実行

if [ $# -ne 1 ]; then
    echo "Error: arg (./run_asm.sh <asm-file>)"
    exit 1
fi

SRC="$1"
OBJ="${SRC}.o"

RXPREFIX="${HOME}/rx-binutils/bin/rx-elf-"
RXAS="${RXPREFIX}as"
RXLD="${RXPREFIX}ld"
RXGDB="${RXPREFIX}gdb"

set -e

# temp dir
atexit() {
  test -n "$tmpdir" && rm -rf "$tmpdir"
}
trap atexit EXIT
tmpdir=$(mktemp -d)

# build
$RXAS asm/start.s -o $tmpdir/start.o
$RXAS $SRC -o $tmpdir/$OBJ
$RXLD $tmpdir/start.o $tmpdir/$OBJ -o $tmpdir/a.out

# simulator
$RXGDB -q $tmpdir/a.out \
       -ex "set pagination off" \
       -ex "set confirm off" \
       -ex "target sim" \
       -ex "load" \
       -ex "run" \
       -ex "i r" \
       -ex "q"
