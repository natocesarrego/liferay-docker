#!/bin/bash

function run_test {
	${1}

	if [ $? -ne 0 ]
	then
		echo "Test failed."

		exit
	fi

	echo "Test passed."
}