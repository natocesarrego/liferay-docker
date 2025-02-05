#!/bin/bash

source ./_common.sh

function build_docker_image {
	local image_version=$(./release_notes.sh get-version)

	DOCKER_IMAGE_TAGS=()
	DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/bundle-builder:${image_version}-${TIMESTAMP}")
	DOCKER_IMAGE_TAGS+=("${LIFERAY_DOCKER_REPOSITORY}/bundle-builder")

	remove_temp_dockerfile_target_platform

	docker build \
		$(get_docker_image_tags_args "${DOCKER_IMAGE_TAGS[@]}") \
		"${TEMP_DIR}" || exit 1
}

function check_usage {
	if [ ! -n "${LIFERAY_DOCKER_RELEASE_FILE_URL}" ]
	then
		echo "Usage: ${0}"
		echo ""
		echo "The script reads the following environment variables:"
		echo ""
		echo "    LIFERAY_DOCKER_DEVELOPER_MODE (optional): If set to \"true\", all local images will be deleted before building a new one"
		echo "    LIFERAY_DOCKER_IMAGE_PLATFORMS (optional): Comma separated Docker image platforms to build when the \"push\" parameter is set"
		echo "    LIFERAY_DOCKER_RELEASE_VERSION (required): The version of liferay"
		echo ""
		echo "Example: LIFERAY_DOCKER_RELEASE_VERSION=2024.q4.4"

		exit 1
	fi
}

function main {
	check_usage "${@}"

	make_temp_directory templates/_bundle_builder

	set_parent_image

	delete_local_images "${LIFERAY_DOCKER_REPOSITORY}/bundle-builder"

	build_docker_image

	clean_up_temp_directory
}


function set_parent_image {
	if (echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | grep -q "q")
	then
		if [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1)" -gt 2024 ]]
		then
			return
		fi

		if [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1)" -eq 2024 ]] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 2 | tr -d q)" -ge 3 ]]
		then
			return
		fi

		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11:latest AS liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
	elif [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2)" == 7.4 ]
	then
		if [ "${LIFERAY_DOCKER_RELEASE_VERSION}" == "7.4.13.nightly" ]
		then
			return
		fi

		if [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2,3 | cut -d '-' -f 1)" == 7.4.13 ] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '-' -f 2 | tr -d u)" -ge 125 ]]
		then
			return
		fi

		if [ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2,3)" == 7.4.3 ] &&
		   [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '-' -f 2 | sed 's/ga//g')" -ge 125 ]]
		then
			return
		fi

		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11:latest AS liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11/g' "${TEMP_DIR}"/Dockerfile
	elif [[ "$(echo "${LIFERAY_DOCKER_RELEASE_VERSION}" | cut -d '.' -f 1,2 | tr -d .)" -le 73 ]]
	then
		sed -i 's/liferay\/jdk21:latest AS liferay-jdk21/liferay\/jdk11-jdk8:latest AS liferay-jdk11-jdk8/g' "${TEMP_DIR}"/Dockerfile
		sed -i 's/FROM liferay-jdk21/FROM liferay-jdk11-jdk8/g' "${TEMP_DIR}"/Dockerfile
	fi
}

main "${@}"