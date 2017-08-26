#! /usr/bin/env bash

# For quieter output, run this with -Q as an argument

ARGS=$@
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAKE=./make.sh

dir_make () {
	if [ ! -d $1 ]; then
		echo "`pwd`/$1 is not a directory"
		exit 1
	fi
	echo $1/
	cd $1

	$MAKE $ARGS

	RET=$?
	if [ $RET -ne 0 ]; then
		echo "============================"
		echo "Failure: ${RET}"
		echo "pwd: `pwd`"
		echo "============================"
	fi

	echo

	cd $DIR
}

example_dirs=( . ain asynch config dio dio_ef ethernet i2c list_all spi stream testing utilities watchdog wifi )
for i in "${example_dirs[@]}"; do
	dir_make $i
done
