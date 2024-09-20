#!/bin/bash

function assert_equals {
	local arguments=()

	for argument in ${@}
	do
		arguments+=(${argument})
	done

	local assertion_result="false"

	for index in ${!arguments[@]}
	do
		if [ $((index % 2)) -ne 0 ]
		then
			continue
		fi

		if [ -f "${arguments[${index}]}" ] &&
		   [ -f "${arguments[${index} + 1]}" ]
		then
			diff "${arguments[${index}]}" "${arguments[${index} + 1]}"

			if [ "${?}" -eq 0 ]
			then
				assertion_result="true"
			else
				assertion_result="false"

				break
			fi
		else
			if [ "${arguments[${index}]}" == "${arguments[${index} + 1]}" ]
			then
				assertion_result="true"
			else
				assertion_result="false"

				break
			fi
		fi
	done

	if [ "${assertion_result}" == "true" ]
	then
		echo -e "${FUNCNAME[1]} \e[1;32mSUCCESS\e[0m\n"
	else
		echo -e "${FUNCNAME[1]} \e[1;31mFAILED\e[0m\n"
	fi
}

function main {
	if [ -n "${BASH_SOURCE[3]}" ]
	then
		echo -e "Running ${BASH_SOURCE[3]}...\n"
	elif [ -n "${BASH_SOURCE[2]}" ]
	then
		echo -e "Running ${BASH_SOURCE[2]}...\n"
	fi
}

main