#!/bin/sh

RXLLC="${HOME}/llvm-project/_build_rx/bin/llc"

echo "$RXLLC\n"

TEST_NUM=0
ERROR_NUM=0
for llfile in *.ll; do
	TEST_NUM=$((TEST_NUM+1))
	ERR_MSG=$($RXLLC --fatal-warnings $llfile 2>&1)
	if [ $? -ne 0 ]; then
		ERROR_NUM=$((ERROR_NUM+1))
		echo "Error: $llfile"
		#echo "$ERR_MSG"
	else
		echo "Ok:    $llfile"
	fi
done

echo "\nError: $ERROR_NUM/$TEST_NUM"
