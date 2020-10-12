#!/bin/sh
# 実行したディレクトリにある全ての.llファイルをコンパイルする

RXLLC="${HOME}/llvm-project/_build_rx/bin/llc"

echo "$RXLLC\n"

TEST_NUM=0
ERROR_NUM=0
for llfile in *.ll; do
	TEST_NUM=$((TEST_NUM+1))
	# debugオプションを外すと少し速くなる
	MSG=$($RXLLC -mtriple=rxv1 --fatal-warnings -debug $llfile 2>&1)
	if [ $? -ne 0 ]; then
		ERROR_NUM=$((ERROR_NUM+1))
		echo "Error: $llfile"
		#echo "$MSG"
	else
		echo "Ok:    $llfile"
		#echo "$MSG"
	fi
done

echo "\nError: $ERROR_NUM/$TEST_NUM"
