#!/bin/bash

source _github.sh
source _test_common.sh

function main {
	set_up

	test_tag_release_dxp

	tear_down
}

function set_up {
	export LIFERAY_COMMON_EXIT_CODE_SKIPPED=4
	export LIFERAY_RELEASE_REPOSITORY_OWNER="natocesarrego"
	export LIFERAY_RELEASE_VERSION="test-tag"
}

function tear_down {
	invoke_github_api_delete "liferay-portal-ee/git/refs/tags/${LIFERAY_RELEASE_VERSION}"

	unset LIFERAY_COMMON_EXIT_CODE_SKIPPED
	unset LIFERAY_RELEASE_REPOSITORY_OWNER
	unset LIFERAY_RELEASE_VERSION
}

function test_tag_release_dxp {
	local ref_data=$(
		cat <<- END
		{
			"message": "",
			"ref": "refs/tags/${LIFERAY_RELEASE_VERSION}",
			"sha": "d4e20d5ccbd8dd3ca5d9a9e03f80e293256b5560"
		}
		END
	)
	local tag_data=$(
		cat <<- END
		{
			"message": "",
			"object": "d4e20d5ccbd8dd3ca5d9a9e03f80e293256b5560",
			"tag": "${LIFERAY_RELEASE_VERSION}",
			"type": "commit"
		}
		END
	)

	assert_equals $(invoke_github_api_post "liferay-portal-ee/git/tags" "${tag_data}") 0 $(invoke_github_api_post "liferay-portal-ee/git/refs" "${ref_data}") 0
}

main