#!/bin/bash

source _github.sh
source _test_common.sh
source _test_util.sh

function delete_tag {
	local curl_response=$(\
		curl "https://api.github.com/repos/${LIFERAY_RELEASE_REPOSITORY_OWNER}/${LIFERAY_RELEASE_REPOSITORY_NAME}/git/refs/tags/${LIFERAY_RELEASE_VERSION}" \
			--header "Accept: application/vnd.github+json" \
			--header "Authorization: Bearer ${LIFERAY_RELEASE_GITHUB_PAT}" \
			--include \
			--request DELETE \
			--silent)

	if [ $(echo "${curl_response}" | awk '/^HTTP/{print $2}') -ne 204 ]
	then
		echo "Failed to delete tag ${LIFERAY_RELEASE_VERSION}."

		exit
	fi

	echo "Deleted tag ${LIFERAY_RELEASE_VERSION}."
}

function main {
	set_up

	test_tag_dxp_release

	tear_down
}

function set_up {
	export _PRODUCT_VERSION="2024.q2.0"

	export git_hash="d4e20d5ccbd8dd3ca5d9a9e03f80e293256b5560"
	# export LIFERAY_RELEASE_GITHUB_PAT
	export LIFERAY_COMMON_EXIT_CODE_SKIPPED=4
	export LIFERAY_RELEASE_PRODUCT_NAME="dxp"
	export LIFERAY_RELEASE_REPOSITORY_NAME="liferay-portal-ee"
	export LIFERAY_RELEASE_REPOSITORY_OWNER="lucasmiranda0"
	export LIFERAY_RELEASE_VERSION="2024.q2.0"
	export repository="liferay-portal-ee"

	export tag_data=$(
		cat <<- END
		{
			"message": "",
			"object": "${git_hash}",
			"tag": "${_PRODUCT_VERSION}",
			"type": "commit"
		}
		END
	)

	export ref_data=$(
		cat <<- END
		{
			"message": "",
			"ref": "refs/tags/${_PRODUCT_VERSION}",
			"sha": "${git_hash}"
		}
		END
	)
}

function tear_down {
	delete_tag

	unset _PRODUCT_VERSION
	unset _PROJECTS_DIR
	unset LIFERAY_COMMON_EXIT_CODE_SKIPPED
	unset LIFERAY_RELEASE_GITHUB_PAT
	unset LIFERAY_RELEASE_PRODUCT_NAME
	unset LIFERAY_RELEASE_REPOSITORY_NAME
	unset LIFERAY_RELEASE_REPOSITORY_OWNER
	unset LIFERAY_RELEASE_VERSION
}

function test_tag_dxp_release {
	assert_equals $(invoke_github_post_api "${repository}/git/tags" "${tag_data}") 0

	assert_equals $(invoke_github_post_api "${repository}/git/refs" "${ref_data}") 0
}

main