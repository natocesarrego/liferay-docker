#!/bin/bash

source _bom.sh
source _git.sh
source _liferay_common.sh
source _package.sh
source _product.sh
source _publishing.sh
source release_gold.sh

function check_usage {
	if [ -z "${LIFERAY_RELEASE_VERSION}" ]
	then
		print_help
	fi

	if [ -z "${LIFERAY_RELEASE_PRODUCT_NAME}" ]
	then
		LIFERAY_RELEASE_PRODUCT_NAME=dxp
	fi

	_BUILD_TIMESTAMP=$(date +%s)

	_PRODUCT_VERSION="${LIFERAY_RELEASE_VERSION}"

	_ARTIFACT_RC_VERSION="${_PRODUCT_VERSION}-${_BUILD_TIMESTAMP}"

	_RELEASE_TOOL_DIR=$(dirname "$(readlink /proc/$$/fd/255 2>/dev/null)")

	lc_cd "${_RELEASE_TOOL_DIR}"

	mkdir -p release-data

	lc_cd release-data

	_RELEASE_ROOT_DIR="${PWD}"

	_BUILD_DIR="${_RELEASE_ROOT_DIR}"/build

	_PROMOTION_DIR="${_BUILD_DIR}"/release

	_PROJECTS_DIR=../..

	_BUNDLES_DIR="${_PROJECTS_DIR}"/bundles

	LIFERAY_COMMON_LOG_DIR="${_BUILD_DIR}"
	LIFERAY_RELEASE_RC_BUILD_TIMESTAMP="${_BUILD_TIMESTAMP}"
	LIFERAY_RELEASE_UPLOAD="true"
}

function main {
	check_usage

	lc_background_run update_portal_repository

	lc_wait

	lc_time_run compile_product

	lc_time_run build_product

	lc_wait

	lc_time_run generate_api_jars

	lc_time_run generate_api_source_jar

	lc_time_run generate_distro_jar

	lc_time_run generate_poms

	rm -fr "${_BUILD_DIR}/release"

	mkdir -p "${_BUILD_DIR}/release"

	lc_time_run package_boms

	lc_time_run generate_checksum_files

	lc_time_run promote_boms
}

function print_help {
	echo "Usage: LIFERAY_RELEASE_VERSION=<version> ${0}"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD (optional): Nexus user's password"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_USER (optional): Nexus user with the right to upload BOM files"
	echo "    LIFERAY_RELEASE_UPLOAD (optional): Set this to \"true\" to upload artifacts"
	echo "    LIFERAY_RELEASE_VERSION: DXP or Portal version of the release to publish"
	echo ""
	echo "Example: LIFERAY_RELEASE_VERSION=2023.q3.0 ${0}"

	exit "${LIFERAY_COMMON_EXIT_CODE_HELP}"
}

main
