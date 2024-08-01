#!/bin/bash

source _bom.sh
source _git.sh
source _liferay_common.sh
source _package.sh
source _product.sh
source _promotion.sh

function check_usage {
	if [ -z "${LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD}" ] ||
	   [ -z "${LIFERAY_RELEASE_NEXUS_REPOSITORY_USER}" ] ||
	   [ -z "${LIFERAY_RELEASE_PRODUCT_NAME}" ] ||
	   [ -z "${LIFERAY_RELEASE_VERSION}" ]
	then
		print_help
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

	_PROJECTS_DIR="${_RELEASE_ROOT_DIR}"/../../..

	_BUNDLES_DIR="${_PROJECTS_DIR}"/bundles

	LIFERAY_COMMON_LOG_DIR="${_BUILD_DIR}"
	LIFERAY_RELEASE_RC_BUILD_TIMESTAMP="${_BUILD_TIMESTAMP}"
	LIFERAY_RELEASE_UPLOAD="true"
}

function checkout_product_version {
	lc_cd "${_PROJECTS_DIR}"/liferay-portal-ee

	git branch --delete "${_PRODUCT_VERSION}" &> /dev/null

	git fetch --no-tags upstream "${_PRODUCT_VERSION}":"${_PRODUCT_VERSION}" &> /dev/null

	git checkout --quiet "${_PRODUCT_VERSION}" &> /dev/null

	if [ "${?}" -ne 0 ]
	then
		lc_log ERROR "Unable to checkout to ${_PRODUCT_VERSION}."

		exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

function main {
	check_usage

	checkout_product_version

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
	echo "Usage: LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD=<password> LIFERAY_RELEASE_NEXUS_REPOSITORY_USER=<user> LIFERAY_RELEASE_PRODUCT_NAME=<product_name> LIFERAY_RELEASE_VERSION=<version> ${0}"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD: Nexus user's password"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_USER: Nexus user with the right to upload BOM files"
	echo "    LIFERAY_RELEASE_VERSION: Version name (DXP or Portal) of the published release"
	echo ""
	echo "Example: LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD=12345 LIFERAY_RELEASE_NEXUS_REPOSITORY_USER=joe.bloggs@liferay.com LIFERAY_RELEASE_PRODUCT_NAME=dxp LIFERAY_RELEASE_VERSION=2023.q3.0 ${0}"

	exit "${LIFERAY_COMMON_EXIT_CODE_HELP}"
}

main
