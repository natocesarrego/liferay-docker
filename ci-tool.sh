#!/bin/bash

function main {
	echo "Running local tests."
	echo ""

	echo "This script was generated on branch LRCI-7139 (ba04023) which is 29 commits ahead of upstream/master."
	echo ""

	durations=()
	failed_commands=0
	results=()
	total_start_time=${SECONDS}

	command_0=(
		"ant setup-sdk && cd portal-impl && ant format-source-current-branch"
		"./."
	)

	command_1=(
		"ant setup-profile-dxp compile install-portal-snapshots"
		"./."
	)

	command_2=(
		"../gradlew :test:jenkins-results-parser:deploy --parallel"
		"./modules"
	)

	command_3=(
		"../gradlew :test:jenkins-results-parser:test"
		"./modules"
	)

	commands_list=(
		"command_0"
		"command_1"
		"command_2"
		"command_3"
	)

	_execute_commands

	echo ""
	echo "================================================================================"
	echo "Summary of results (Total time: $(_format_duration $((${SECONDS} - ${total_start_time})))):"
	echo "Current branch is 29 commits ahead of upstream/master."
	echo "================================================================================"

	for i in "${!commands_list[@]}"
	do
		local command_name="${commands_list[${i}]}"

		local command_ref="${command_name}[0]"
		local dir_ref="${command_name}[1]"

		if [[ "${results[${i}]}" == "SUCCESS" ]]
		then
			local icon="✓"
		else
			local icon="✗"
		fi

		printf "[${icon}] %-7s (%s) - %s\n" "${results[${i}]}" "${durations[${i}]}" "${!dir_ref}"
		printf "    Command: %s\n\n" "${!command_ref}"
	done

	echo "================================================================================"

	echo ""

	if [[ ${failed_commands} -eq 0 ]]
	then
		echo "All commands executed successfully."

		exit 0
	else
		echo "${failed_commands} command(s) failed."

		exit 1
	fi
}

function _execute_commands {
	for i in "${!commands_list[@]}"
	do
		local command_name="${commands_list[${i}]}"
		local command_start_time=${SECONDS}
		local exit_code

		local command_ref="${command_name}[0]"
		local dir_ref="${command_name}[1]"

		echo "================================================================================"
		echo "Executing command [$((${i} + 1))/${#commands_list[@]}]: [${!dir_ref}] ${!command_ref}"
		echo "================================================================================"

		(
			if [[ "${!dir_ref}" != "./" ]]
			then
				cd "${!dir_ref}"
			fi

			eval "${!command_ref}"
		)

		exit_code=${?}

		durations[${i}]=$(_format_duration $((${SECONDS} - ${command_start_time})))

		if [[ ${exit_code} -eq 0 ]]
		then
			results[${i}]="SUCCESS"
		else
			results[${i}]="FAILED"

			failed_commands=$((${failed_commands} + 1))
		fi

		echo ""
	done
}

function _format_duration {
	if [[ $((${1} / 60)) -gt 0 ]]
	then
		echo "$((${1} / 60))m $((${1} % 60))s"
	else
		echo "$((${1} % 60))s"
	fi
}

main