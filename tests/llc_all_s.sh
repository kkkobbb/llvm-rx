#!/bin/sh

RXLLC="${HOME}/llvm-project/_build_rx/bin/llc"

for llfile in ./*.ll; do
	echo "llc $llfile"
	$RXLLC $llfile
done
