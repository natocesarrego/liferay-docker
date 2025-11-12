#!/bin/bash

function clone_latest_commit {
	git clone \
		--branch=master \
		--depth 1 \
		--single-branch \
		https://github.com/liferay/liferay-portal.git "${TEMP_DIR}"
}

function extract_template {
	local template_origin="${TEMP_DIR}/modules/integrations/vercel/templates/${TEMPLATE}"

	echo -e "extracting ${template_origin} to ${DESTINATION}"

	if [ ! -d "${DESTINATION}" ]
	then
		mkdir --parents "${DESTINATION}"
	fi

	mv --verbose "${template_origin}" "${DESTINATION}"
}

function main {
	TEMPLATE="${1}"

	DESTINATION=$(pwd)

	if [ -n "${2}" ]
	then
		DESTINATION="${2}"
	fi

	TEMP_DIR=$(mktemp -d)

	clone_latest_commit

	extract_template

	make_destination_a_git_repo
}

function make_destination_a_git_repo {
	cd "${DESTINATION}/${TEMPLATE}"	 && git init && git add . && git commit --message "chore: clone TEMPLATE"
}

main "${@}"