#!/bin/bash

function invoke_github_get_api {
	invoke_github_api "${1}" "${2}" "GET"
}

function invoke_github_api {
	local curl_response=$(\
		curl \
			"https://api.github.com/repos/${LIFERAY_RELEASE_REPOSITORY_OWNER}/${1}" \
			--data "${2}" \
			--fail \
			--header "Accept: application/vnd.github+json" \
			--header "Authorization: Bearer ${LIFERAY_RELEASE_GITHUB_PAT}" \
			--header "X-GitHub-Api-Version: 2022-11-28" \
			--max-time 10 \
			--include \
			--request "${3}" \
			--retry 3 \
			--silent)

	if ! [[ $(echo "${curl_response}" | awk '/^HTTP/{print $2}') =~ ^2 ]]
	then
		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	if [ "${3}" == "GET" ]
	then
		echo "${curl_response}" | awk '/^\{/{flag=1} flag'
	fi

	return 0
}

function invoke_github_post_api {
	invoke_github_api "${1}" "${2}" "POST"

	echo $?
}