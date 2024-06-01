#!/bin/bash

function invoke_github_api {
	local curl_response=$(\
		curl \
			"https://api.github.com/repos/kiwm/${1}" \
			--data "${2}" \
			--header "Accept: application/vnd.github+json" \
			--header "Authorization: Bearer ${LIFERAY_RELEASE_GITHUB_PAT}" \
			--header "X-GitHub-Api-Version: 2022-11-28" \
			--include \
			--max-time 10 \
			--request POST \
			--retry 3 \
			--silent)

	if [ $(echo "${curl_response}" | awk '/^HTTP/{print $2}') -ne 201 ]
	then
		lc_log ERROR "Unable to invoke GitHub API:"
		lc_log ERROR "${curl_response}"

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi
}

function invoke_github_api_with_response {
	local curl_response=$(\
		curl \
			"https://api.github.com/repos/kiwm/${1}" \
            --data "${2}" \
			--fail \
			--header "Accept: application/vnd.github+json" \
			--header "Authorization: Bearer ${LIFERAY_RELEASE_GITHUB_PAT}" \
			--header "X-GitHub-Api-Version: 2022-11-28" \
			--max-time 10 \
            --include \
			--request GET \
			--retry 3 \
			--silent)
	if [ $(echo "${curl_response}" | awk '/^HTTP/{print $2}') -ne 200 ]
	then
		echo "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	else
        echo "${curl_response}" | awk '/^\{/{flag=1} flag'
    fi
}