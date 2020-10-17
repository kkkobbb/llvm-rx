#!/bin/sh
# 引数の.sファイルをアセンブル、リンクし、gdb simで実行する
# 実行時./asm/start.sファイルが存在する必要がる

RXPREFIX="${HOME}/rx-binutils/bin/rx-elf-"
RXAS="${RXPREFIX}as"
RXLD="${RXPREFIX}ld"
RXGDB="${RXPREFIX}gdb"
RXSTART="$(dirname $0)/asm/start.s"

usage() {
    echo "Usage: ./run_asm.sh [options] <asm-file>"
    echo "Options:"
    echo "  -s        use stdin"
    echo "  -r N=V    initialize register N (0 <= N <= 15) (V 32bit)"
    echo "  -c FUNC   call FUNC"
    echo "  -b ASM    add ASM before call"
}

parse_opt_reg() {
    optarg=$1
    if echo $optarg | grep -v '='; then
        return 1
    fi
    reg_num=$(echo $optarg | sed 's/=.*//')
    if [ $reg_num -lt 0 -o $reg_num -gt 15 ]; then
        return 1
    fi
    reg_val=$(echo $optarg | sed 's/.*=//')
    # 下限は32bit signedの最小値、上限は32bit unsignedの最大値
    if [ $reg_val -lt -2147483648 -o $reg_val -gt 4294967296 ]; then
        return 1
    fi
    echo "mov #$reg_val, r$reg_num"
    return 0
}

# オプション解析

SRC_STDIN=false
REG_VAL=""
CALL_FUNC=""
ADD_ASM=""

while getopts "sr:c:b:h" OPT
do
    case $OPT in
        s) SRC_STDIN=true ;;
        r) regstr=$(parse_opt_reg $OPTARG)
           if [ $? -ne 0 ]; then
               echo "Error: -r\n"
               usage
               exit 1
           fi
           REG_VAL="$REG_VAL\t$regstr\n"
           ;;
        c) CALL_FUNC=$OPTARG ;;
        b) ADD_ASM="$ADD_ASM\t$OPTARG\n" ;;
        h) usage
           exit 0
           ;;
    esac
done

shift $((OPTIND - 1))

if [ "$SRC_STDIN" = "false" -a $# -ne 1 ]; then
    echo "Error: args\n"
    usage
    exit 1
fi

if $SRC_STDIN; then
    SRC="asm"
else
    SRC="$1"
fi
SRC_BASENAME="$(basename $SRC)"
OBJ="${SRC_BASENAME}.o"
ELF="${SRC_BASENAME}.elf"

set -e

# temp dir
atexit() {
  test -n "$tmpdir" && rm -rf "$tmpdir"
}
trap atexit EXIT
tmpdir=$(mktemp -d)

# コード調整
START_REG="$tmpdir/start_reg.s"
if [ -n "$CALL_FUNC" ]; then
    sed "/INIT REGS/c\\$REG_VAL" $RXSTART > $START_REG
else
    cat $RXSTART > $START_REG
fi
START_CALL="$tmpdir/start_call.s"
if [ -n "$CALL_FUNC" ]; then
    sed "/CALL EXTERNAL FUNCTION/c\\\tbsr $CALL_FUNC" $START_REG > $START_CALL
else
    cat $START_REG > $START_CALL
fi
START_="$tmpdir/start.s"
if [ -n "$ADD_ASM" ]; then
    sed "/ADDITIONAL CODE/c\\$ADD_ASM" $START_CALL > $START_
else
    cat $START_CALL > $START_
fi


# build
$RXAS $START_ -o $tmpdir/start.o
if $SRC_STDIN; then
    cat | $RXAS -o $tmpdir/$OBJ
else
    $RXAS $SRC -o $tmpdir/$OBJ
fi
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
