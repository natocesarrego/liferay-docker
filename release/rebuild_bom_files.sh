#!/bin/bash

source _bom.sh
source _git.sh
source _hotfix.sh
source _jdk.sh
source _liferay_common.sh
source _package.sh
source _patcher.sh
source _product.sh
source _publishing.sh

	#
	# TODO Remove once all systems are using LIFERAY_RELEASE_GIT_REF instead of LIFERAY_RELEASE_GIT_SHA
	#
function check_usage {
	if [ -z "${LIFERAY_RELEASE_GIT_REF}" ]
	then
		print_help
	fi

	if [ -z "${LIFERAY_RELEASE_PRODUCT_NAME}" ]
	then
		LIFERAY_RELEASE_PRODUCT_NAME=dxp
	fi

	_BUILD_TIMESTAMP=$(date +%s)

	_RELEASE_TOOL_DIR=$(dirname "$(readlink /proc/$$/fd/255 2>/dev/null)")

	lc_cd "${_RELEASE_TOOL_DIR}"

	mkdir -p release-data

	lc_cd release-data

	_RELEASE_ROOT_DIR="${PWD}"

	_BUILD_DIR="${_RELEASE_ROOT_DIR}"/build
	_BUILDER_SHA=$(git rev-parse HEAD)
	_BUNDLES_DIR="${_RELEASE_ROOT_DIR}"/dev/projects/bundles
	_PROJECTS_DIR="${_RELEASE_ROOT_DIR}"/dev/projects
	_RELEASES_DIR="${_RELEASE_ROOT_DIR}"/releases
	_TEST_RELEASE_DIR="${_RELEASE_ROOT_DIR}"/test_release

	LIFERAY_COMMON_LOG_DIR="${_BUILD_DIR}"

	_PRODUCT_VERSION="${LIFERAY_RELEASE_GIT_REF}"
	_TIMESTAMPED_VERSION="${_PRODUCT_VERSION}-${_BUILD_TIMESTAMP}"
}

function clean_up {
	for file in *.pom; do
   		new_name="${file/$_TIMESTAMPED_VERSION/$_PRODUCT_VERSION}"
   		mv "$file" "$new_name"
   		echo "Renamed $file to $new_name"
	done

	sed -i "s#<version>${_TIMESTAMPED_VERSION}</version>#<version>${_PRODUCT_VERSION}</version>#" ./*.pom
}

function print_help {
	echo "Usage: LIFERAY_RELEASE_GIT_REF=<git sha> ${0}"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_RELEASE_GIT_REF: Git SHA to build from"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD (optional): Nexus user's password"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_USER (optional): Nexus user with the right to upload BOM files"
	echo "    LIFERAY_RELEASE_UPLOAD (optional): Set this to \"true\" to upload artifacts"
	echo ""
	echo "Example: LIFERAY_RELEASE_GIT_REF=release-2023.q3 ${0}"

	exit "${LIFERAY_COMMON_EXIT_CODE_HELP}"
}

function main {
	check_usage

	lc_background_run clone_repository liferay-binaries-cache-2020
	lc_background_run clone_repository liferay-portal-ee
	lc_background_run clone_repository liferay-release-tool-ee

	lc_wait

	lc_time_run clean_portal_repository

	lc_background_run init_gcs
	lc_background_run update_portal_repository

	lc_wait

	lc_time_run set_git_sha

	lc_wait

	lc_time_run set_product_version

	lc_time_run update_release_info_date

	lc_time_run set_up_profile

	lc_time_run generate_api_jars

	lc_time_run generate_api_source_jar

	lc_time_run generate_poms_from_scratch

	clean_up

	lc_time_run upload_boms liferay-public-releases
}

main
