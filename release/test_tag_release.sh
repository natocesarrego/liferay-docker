#!/bin/bash

source _test_util.sh
source release_gold.sh --source-only

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
	export LIFERAY_COMMON_EXIT_CODE_SKIPPED=4
	export LIFERAY_RELEASE_PRODUCT_NAME="dxp"
	export LIFERAY_RELEASE_REPOSITORY_NAME="liferay-portal-ee"
	export LIFERAY_RELEASE_REPOSITORY_OWNER="lucasmiranda0"
	export LIFERAY_RELEASE_VERSION="2024.q2.0"
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
	run_test tag_release
}

main