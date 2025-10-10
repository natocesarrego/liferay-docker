#!/bin/bash

source ../_github.sh
source ../_liferay_common.sh
source ../_release_common.sh
source ./_git.sh
source ./_jdk.sh
source ./_jira.sh
source ./_product.sh
source ./_product_info_json.sh
source ./_promotion.sh
source ./_releases_json.sh

function add_property {
	local new_key="${1}"
	local new_value="${2}"
	local search_key="${3}"

	sed --in-place "/${search_key}/a\	\\${new_key}=${new_value}" "build-shared.properties"
}

function check_supported_versions {
	local supported_version="$(get_product_group_version)"

	if [ -z $(grep "${supported_version}" "${_RELEASE_ROOT_DIR}"/supported-"${LIFERAY_RELEASE_PRODUCT_NAME}"-versions.txt) ]
	then
		lc_log ERROR "Unable to find ${supported_version} in supported-${LIFERAY_RELEASE_PRODUCT_NAME}-versions.txt."

		exit "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

function check_usage {
	if [ -z "${LIFERAY_RELEASE_PREPARE_NEXT_RELEASE_BRANCH}" ] || [ -z "${LIFERAY_RELEASE_RC_BUILD_TIMESTAMP}" ] || [ -z "${LIFERAY_RELEASE_VERSION}" ]
	then
		print_help
	fi

	if [ -z "${LIFERAY_RELEASE_PRODUCT_NAME}" ]
	then
		LIFERAY_RELEASE_PRODUCT_NAME=dxp
	fi

	set_product_version "${LIFERAY_RELEASE_VERSION}" "${LIFERAY_RELEASE_RC_BUILD_TIMESTAMP}"

	lc_cd "$(dirname "$(readlink /proc/$$/fd/255 2>/dev/null)")"

	_RELEASE_ROOT_DIR="${PWD}"

	_BASE_DIR="$(dirname "${_RELEASE_ROOT_DIR}")"

	_PROJECTS_DIR="/opt/dev/projects/github"

	if [ ! -d "${_PROJECTS_DIR}" ]
	then
		_PROJECTS_DIR="${_RELEASE_ROOT_DIR}/dev/projects"
	fi

	_PROMOTION_DIR="${_RELEASE_ROOT_DIR}/release-data/promotion/files"

	rm --force --recursive "${_PROMOTION_DIR}"

	mkdir --parents "${_PROMOTION_DIR}"

	lc_cd "${_PROMOTION_DIR}"

	LIFERAY_COMMON_LOG_DIR="${_PROMOTION_DIR%/*}"
}

function main {
	if [[ "${BASH_SOURCE[0]}" != "${0}" ]]
	then
		return
	fi

	check_usage

	check_supported_versions

	init_gcs

	lc_time_run set_jdk_version_and_parameters

	# lc_time_run promote_packages

	# lc_time_run tag_release

	# promote_boms xanadu

	# if (! is_quarterly_release && ! is_7_4_release)
	# then
	# 	lc_log INFO "Do not update product_info.json for quarterly and 7.4 releases."

	# 	lc_time_run generate_product_info_json

	# 	lc_time_run upload_product_info_json
	# fi

	lc_time_run generate_releases_json "regenerate"

	# lc_time_run reference_new_releases

	# lc_time_run test_boms

	# lc_time_run update_salesforce_product_version

	# if [ -d "${_RELEASE_ROOT_DIR}/dev/projects" ]
	# then
	# 	lc_background_run clone_repository liferay-portal-ee

	# 	lc_wait
	# fi

	# lc_time_run clean_portal_repository

	# lc_time_run prepare_next_release_branch

	# lc_time_run add_patcher_project_version

	# lc_time_run upload_to_docker_hub "release-gold"
}

function prepare_next_release_branch {
	if ! is_quarterly_release ||
	   [ ! $(echo "${LIFERAY_RELEASE_PREPARE_NEXT_RELEASE_BRANCH}" | grep --ignore-case "true") ] ||
	   [[ "$(get_release_patch_version)" -eq 0 ]]
	then
		lc_log INFO "Skipping the preparation of the next release branch."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local product_group_version="$(get_product_group_version)"

	local latest_quarterly_product_version="$(\
		jq --raw-output ".[] | \
			select(.productGroupVersion == \"${product_group_version}\" and .promoted == \"true\") | \
			.targetPlatformVersion" ${_PROMOTION_DIR}/*releases.json)"

	if [ "$(get_product_version_without_lts_suffix)" != "${latest_quarterly_product_version}" ]
	then
		lc_log INFO "The ${_PRODUCT_VERSION} is not the latest quarterly release. Skipping the preparation of the next release branch."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	if [ -z "${LIFERAY_RELEASE_TEST_MODE}" ]
	then
		local quarterly_release_branch="release-${product_group_version}"

		prepare_branch_to_commit "${_PROJECTS_DIR}/liferay-portal-ee" "liferay-portal-ee" "${quarterly_release_branch}"

		if [ "${?}" -eq "${LIFERAY_COMMON_EXIT_CODE_BAD}" ]
		then
			lc_log ERROR "Unable to prepare the next release branch."

			return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
		fi
	fi

	local next_release_patch_version=$(($(get_release_patch_version) + 1))

	if is_lts_release
	then
		next_release_patch_version="${next_release_patch_version} LTS"
	fi

	set_next_release_version_display_name "${product_group_version}" "${next_release_patch_version}"

	set_next_release_date
	
	if [ -z "${LIFERAY_RELEASE_TEST_MODE}" ]
	then
		prepare_next_release_pull_request "${quarterly_release_branch}"
	fi
}

function prepare_next_release_pull_request {
	local issue_key="$( \
		add_jira_issue \
			"712020:69064438-1c54-4f6a-8740-64505ce4ebed" \
			"Release" \
			"Task" \
			"LPD" \
			"${_PRODUCT_VERSION} Patch release" \
			"customfield_10001" \
			"04c03e90-c5a7-4fda-82f6-65746fe08b83")"

	if [[ "${issue_key}" != LPD-* ]]
	then
		lc_log ERROR "Unable to create a Jira issue for ${_PRODUCT_VERSION}."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	commit_to_branch_and_send_pull_request \
		"${_PROJECTS_DIR}/liferay-portal-ee/release.properties" \
		"${issue_key} prep next" \
		"${1}" \
		"brianchandotcom/liferay-portal-ee" \
		"${issue_key} prep next | ${1}"

	local exit_code="${?}"

	if [ "${exit_code}" -eq "${LIFERAY_COMMON_EXIT_CODE_BAD}" ]
	then
		lc_log ERROR "Unable to commit to the release branch."
	else
		lc_log INFO "The next release branch was prepared successfully."

		add_jira_issue_comment_with_mention "Related pull request: $(get_pull_request_url brianchandotcom/liferay-portal-ee). cc " "${issue_key}"
	fi

	return "${exit_code}"
}

function print_help {
	echo "Usage: LIFERAY_RELEASE_RC_BUILD_TIMESTAMP=<timestamp> LIFERAY_RELEASE_VERSION=<version> ./$(basename ${0})"
	echo ""
	echo "The script reads the following environment variables:"
	echo ""
	echo "    LIFERAY_RELEASE_GCS_TOKEN (optional): *.json file containing the token to authenticate with Google Cloud Storage"
	echo "    LIFERAY_RELEASE_GITHUB_PAT (optional): GitHub personal access token used to tag releases"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_PASSWORD (optional): Nexus user's password"
	echo "    LIFERAY_RELEASE_NEXUS_REPOSITORY_USER (optional): Nexus user with the right to upload BOM files"
	echo "    LIFERAY_RELEASE_PATCHER_PORTAL_EMAIL_ADDRESS: Email address to the release team's Liferay Patcher user"
	echo "    LIFERAY_RELEASE_PATCHER_PORTAL_PASSWORD: Password to the release team's Liferay Patcher user"
	echo "    LIFERAY_RELEASE_PREPARE_NEXT_RELEASE_BRANCH: Set to \"true\" to prepare the next release branch. The default is \"false\"."
	echo "    LIFERAY_RELEASE_PRODUCT_NAME (optional): Set to \"portal\" for CE. The default is \"DXP\"."
	echo "    LIFERAY_RELEASE_RC_BUILD_TIMESTAMP: Timestamp of the build to publish"
	echo "    LIFERAY_RELEASE_VERSION: DXP or portal version of the release to publish"
	echo ""
	echo "Example: LIFERAY_RELEASE_PREPARE_NEXT_RELEASE_BRANCH=true LIFERAY_RELEASE_RC_BUILD_TIMESTAMP=1695892964 LIFERAY_RELEASE_VERSION=2023.q3.0 ./$(basename ${0})"

	exit "${LIFERAY_COMMON_EXIT_CODE_HELP}"
}

function reference_new_releases {
	if ! is_quarterly_release
	then
		lc_log INFO "Skipping the update to the references in the liferay-jenkins-ee repository."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local issue_key=""

	if [ -z "${LIFERAY_RELEASE_TEST_MODE}" ]
	then
		issue_key="$(\
			add_jira_issue \
				"60a3f462391e56006e6b661b" \
				"Release Tester" \
				"Task" \
				"LRCI" \
				"Add release references for ${_PRODUCT_VERSION}" \
				"customfield_10001" \
				"04c03e90-c5a7-4fda-82f6-65746fe08b83")"

		if [ "${issue_key}" == "${LIFERAY_COMMON_EXIT_CODE_BAD}" ]
		then
			lc_log ERROR "Unable to create a Jira issue to add release references for ${_PRODUCT_VERSION}."

			return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
		fi

		prepare_branch_to_commit "${_PROJECTS_DIR}/liferay-jenkins-ee/commands" "liferay-jenkins-ee"
	fi

	if [ "${?}" -ne 0 ]
	then
		lc_log ERROR "Unable to prepare the next release references branch."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	local base_url="http://mirrors.lax.liferay.com/releases.liferay.com"

	local latest_quarterly_release="false"

	local product_group_version="$(get_product_group_version)"

	local previous_product_version="$(\
		grep "portal.latest.bundle.version\[${product_group_version}" \
			"build-shared.properties" | \
			tail -1 | \
			cut --delimiter='=' --fields=2)"

	if [ -z "${previous_product_version}" ]
	then
		latest_quarterly_release="true"
		previous_product_version="$(grep "portal.latest.bundle.version\[master\]=" "build-shared.properties" | cut --delimiter='=' --fields=2)"
	fi

	for component in osgi sql tools
	do
		add_property \
			"portal.${component}.zip.url\[${_PRODUCT_VERSION}\]" \
			"${base_url}/${LIFERAY_RELEASE_PRODUCT_NAME}/${_PRODUCT_VERSION}/liferay-${LIFERAY_RELEASE_PRODUCT_NAME}-${component}-${_PRODUCT_VERSION}-${LIFERAY_RELEASE_RC_BUILD_TIMESTAMP}.zip" \
			"portal.${component}.zip.url\[${previous_product_version}\]="
	done

	add_property \
		"plugins.war.zip.url\[${_PRODUCT_VERSION}\]" \
		"http://release-master.liferay.com/userContent/liferay-release-tool/7413/plugins.war.latest.zip" \
		"plugins.war.zip.url\[${previous_product_version}\]="

	add_property \
		"	portal.bundle.tomcat\[${_PRODUCT_VERSION}\]" \
		"${base_url}/${LIFERAY_RELEASE_PRODUCT_NAME}/${_PRODUCT_VERSION}/liferay-${LIFERAY_RELEASE_PRODUCT_NAME}-tomcat-${_PRODUCT_VERSION}-${LIFERAY_RELEASE_RC_BUILD_TIMESTAMP}.7z" \
		"portal.bundle.tomcat\[${previous_product_version}\]="

	add_property \
		"portal.license.url\[${_PRODUCT_VERSION}\]" \
		"http://www.liferay.com/licenses/license-portaldevelopment-developer-cluster-7.0de-liferaycom.xml" \
		"portal.license.url\[${previous_product_version}\]="

	add_property \
		"portal.version.latest\[${_PRODUCT_VERSION}\]" \
		"${_PRODUCT_VERSION}" \
		"portal.version.latest\[${previous_product_version}\]="

	add_property \
		"portal.war.url\[${_PRODUCT_VERSION}\]" \
		"${base_url}/${LIFERAY_RELEASE_PRODUCT_NAME}/${_PRODUCT_VERSION}/liferay-${LIFERAY_RELEASE_PRODUCT_NAME}-${_PRODUCT_VERSION}-${LIFERAY_RELEASE_RC_BUILD_TIMESTAMP}.war" \
		"portal.war.url\[${previous_product_version}\]="

	add_property \
		"portal.latest.bundle.version\[${_PRODUCT_VERSION}\]" \
		"${_PRODUCT_VERSION}" \
		"portal.latest.bundle.version\[${previous_product_version}\]="

	local latest_product_group_version="$(\
		grep "portal.latest.bundle.version\[master\]=" \
			"build-shared.properties" | \
			cut --delimiter='=' --fields=2 | \
			cut --delimiter='.' --fields=1,2)"

	if [ "${product_group_version}" == "${latest_product_group_version}" ] || [ "${latest_quarterly_release}" == "true" ] 
	then
		replace_property \
			"portal.latest.bundle.version\[master\]" \
			"${_PRODUCT_VERSION}" \
			"portal.latest.bundle.version\[master\]=${previous_product_version}"
	fi

	local previous_quarterly_release_branch="$(\
		grep "portal.latest.bundle.version" \
			"build-shared.properties" | \
			tail -1 | \
			cut --delimiter='[' --fields=2 | \
			cut --delimiter=']' --fields=1)"

	local quarterly_release_branch="release-$(get_product_group_version)"

	if [ "${latest_quarterly_release}" == "false" ]
	then
		replace_property \
			"portal.latest.bundle.version\[${quarterly_release_branch}\]" \
			"${_PRODUCT_VERSION}" \
			"portal.latest.bundle.version\[${quarterly_release_branch}\]=${previous_product_version}"

		replace_property \
			"portal.version.latest\[${quarterly_release_branch}\]" \
			"${_PRODUCT_VERSION}" \
			"portal.version.latest\[${quarterly_release_branch}\]=${previous_product_version}"
	else
		add_property \
			"portal.latest.bundle.version\[${quarterly_release_branch}\]" \
			"${_PRODUCT_VERSION}" \
			"portal.latest.bundle.version\[${previous_quarterly_release_branch}\]="

		add_property \
			"portal.version.latest\[${quarterly_release_branch}\]" \
			"${_PRODUCT_VERSION}" \
			"portal.version.latest\[${previous_quarterly_release_branch}\]="
	fi

	if [ -z "${LIFERAY_RELEASE_TEST_MODE}" ]
	then
		commit_to_branch_and_send_pull_request \
			"${_PROJECTS_DIR}/liferay-jenkins-ee/commands/build-shared.properties" \
			"${issue_key} Add release references for ${_PRODUCT_VERSION}" \
			"master" \
			"pyoo47/liferay-jenkins-ee" \
			"${issue_key} Add release references for ${_PRODUCT_VERSION}"

		local exit_code="${?}"

		if [ "${exit_code}" -eq "${LIFERAY_COMMON_EXIT_CODE_BAD}" ]
		then
			lc_log ERROR "Unable to send pull request with references to the next release."
		else
			lc_log INFO "Pull request with references to the next release was sent successfully."

			add_jira_issue_comment "Related pull request: $(get_pull_request_url pyoo47/liferay-jenkins-ee)" "${issue_key}"
		fi

		return "${exit_code}"
	fi
}

function replace_property {
	local new_key="${1}"
	local new_value="${2}"
	local search_key="${3}"

	sed --in-place "s/${search_key}/${new_key}=${new_value}/" "build-shared.properties"
}

function set_next_release_date {
	sed \
		--expression "s/release.info.date=.*/release.info.date=$(date -d $(echo "${LIFERAY_NEXT_RELEASE_DATE}" | sed "s/[^0-9-]//g") +"%B %-d, %Y")/" \
		--in-place \
		"${_PROJECTS_DIR}/liferay-portal-ee/release.properties"
}

function set_next_release_version_display_name {
	for branch in master-private release-private
	do
		sed \
			--expression "s/release.info.version.display.name\[${branch}\]=.*/release.info.version.display.name[${branch}]=${1^^}.${2}/" \
			--in-place \
			"${_PROJECTS_DIR}/liferay-portal-ee/release.properties"
	done
}

function tag_release {
	if [ -z "${LIFERAY_RELEASE_GITHUB_PAT}" ]
	then
		lc_log INFO "Set the environment variable \"LIFERAY_RELEASE_GITHUB_PAT\"."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local release_properties_file=$(lc_download "https://releases.liferay.com/${LIFERAY_RELEASE_PRODUCT_NAME}/${_PRODUCT_VERSION}/release.properties")

	if [ $? -ne 0 ]
	then
		lc_log ERROR "Unable to download release.properties."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local git_hash=$(lc_get_property "${release_properties_file}" git.hash.liferay-portal-ee)

	if [ -z "${git_hash}" ]
	then
		lc_log ERROR "Unable to get property \"git.hash.liferay-portal-ee.\""

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local product_version_without_lts_suffix="$(get_product_version_without_lts_suffix)"

	local repository=liferay-portal-ee

	if is_portal_release
	then
		repository=liferay-portal
	fi

	for repository_owner in brianchandotcom liferay
	do
		local tag_data=$(
			cat <<- END
			{
				"message": "",
				"object": "${git_hash}",
				"tag": "${product_version_without_lts_suffix}",
				"type": "commit"
			}
			END
		)

		if [ $(invoke_github_api_post "${repository_owner}" "${repository}/git/tags" "${tag_data}") -eq "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}" ]
		then
			lc_log ERROR "Unable to create tag ${product_version_without_lts_suffix} in ${repository_owner}/${repository}."

			return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
		fi

		local ref_data=$(
			cat <<- END
			{
				"message": "",
				"ref": "refs/tags/${product_version_without_lts_suffix}",
				"sha": "${git_hash}"
			}
			END
		)

		if [ $(invoke_github_api_post "${repository_owner}" "${repository}/git/refs" "${ref_data}") -eq "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}" ]
		then
			lc_log ERROR "Unable to create tag reference for ${product_version_without_lts_suffix} in ${repository_owner}/${repository}."

			return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
		fi
	done

	if is_7_4_u_release
	then
		local temp_branch="release-$(echo "${_PRODUCT_VERSION}" | sed --regexp-extended "s/-u/\./")"

		if [ $(invoke_github_api_delete "brianchandotcom" "${repository}/git/refs/heads/${temp_branch}") -eq "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}" ]
		then
			lc_log ERROR "Unable to delete temp branch ${temp_branch} in ${LIFERAY_RELEASE_REPOSITORY_OWNER}/${repository}."

			return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
		fi
	fi
}

function test_boms {
	if is_7_4_u_release
	then
		lc_log INFO "Skipping test BOMs for ${_PRODUCT_VERSION}."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	rm --force "${HOME}/.liferay/workspace/releases.json"

	mkdir --parents "temp_dir_test_boms"

	lc_cd "temp_dir_test_boms"

	blade update

	export LIFERAY_RELEASES_MIRRORS="https://releases.liferay.com"

	cat "${HOME}/.liferay/workspace/releases.json"

	if is_quarterly_release
	then
		blade init -v "${LIFERAY_RELEASE_PRODUCT_NAME}-${_PRODUCT_VERSION}"
	else
		local product_group_version="$(get_product_group_version)"
		local product_version_suffix=$(echo "${_PRODUCT_VERSION}" | cut --delimiter='-' --fields=2)

		blade init -v "${LIFERAY_RELEASE_PRODUCT_NAME}-${product_group_version}-${product_version_suffix}"
	fi

	for module in api mvc-portlet
	do
		blade create -t "${module}" "test-${module}"

		local build_result=$(blade gw build)

		if [[ "${build_result}" == *"BUILD SUCCESSFUL"* ]]
		then
			lc_log INFO "The BOMs for the module ${module} were successfully tested."
		else
			lc_log ERROR "The BOMs for the module ${module} were incorrectly generated."

			break
		fi
	done

	lc_cd ".."

	pgrep --full --list-name temp_dir_test_boms | awk '{print $1}' | xargs --no-run-if-empty kill -9

	rm --force --recursive "temp_dir_test_boms"

	if [[ "${build_result}" != *"BUILD SUCCESSFUL"* ]]
	then
		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi
}

function update_salesforce_product_version {
	if ! is_first_quarterly_release
	then
		lc_log INFO "Skipping the update of the Salesforce product version."

		return "${LIFERAY_COMMON_EXIT_CODE_SKIPPED}"
	fi

	local data=$(
		cat <<- END
		{
			"liferayVersion": "$(get_product_group_version)"
		}
		END
	)

	local http_code=$( \
		curl \
			"https://us-west2-is-sales-prd.cloudfunctions.net/liferay-version-api/liferay-versions" \
			--data "${data}" \
			--header "Authorization: Bearer $(gcloud auth print-identity-token)" \
			--header "Content-Type: application/json" \
			--output /dev/null \
			--request POST \
			--silent \
			--write-out "%{http_code}")

	if [ "${http_code}" != "200" ]
	then
		lc_log ERROR "Unable to update the Salesforce product version. HTTP response code was ${http_code}. Create a general request ticket in the SFDC Jira project and ask for the inclusion of version $(get_product_group_version) in Salesforce."

		return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
	fi

	lc_log INFO "The Salesforce product version was updated successfully."
}

main "${@}"