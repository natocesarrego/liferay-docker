#!/bin/bash

source _liferay_common.sh

function invoke_github_api {
	if [ -z "${LIFERAY_RELEASE_REPOSITORY_OWNER}" ]
	then
		LIFERAY_RELEASE_REPOSITORY_OWNER=liferay
	fi

	local curl_response=$(\
		curl \
			"https://api.github.com/repos/${LIFERAY_RELEASE_REPOSITORY_OWNER}/${1}" \
			--data "${2}" \
			--fail \
			--header "Accept: application/vnd.github+json" \
			--header "Authorization: Bearer ${LIFERAY_RELEASE_GITHUB_PAT}" \
			--header "X-GitHub-Api-Version: 2022-11-28" \
			--include \
			--max-time 10 \
			--request "${3}" \
			--retry 3 \
			--silent)

	if ! [[ $(echo "${curl_response}" | awk '/^HTTP/{print $2}') =~ ^2 ]]
	then
		if [ "${3}" == "DELETE" ]
		then
			echo "Failed to delete tag ${LIFERAY_RELEASE_VERSION}."
		fi

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	if [ "${3}" == "DELETE" ]
	then
		echo "Tag ${LIFERAY_RELEASE_VERSION} deleted."
	fi

	return "${LIFERAY_COMMON_EXIT_CODE_OK}"
}

function invoke_github_api_delete {
	invoke_github_api "${1}" "${2}" "DELETE"

	echo $?
}

function invoke_github_api_post {
	invoke_github_api "${1}" "${2}" "POST"

	echo $?
}