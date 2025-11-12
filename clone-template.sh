#!/bin/bash

function clone_latest_commit {
	local temp_dir=${1}

	git clone --single-branch --branch=master --depth 1 https://github.com/liferay/liferay-portal.git ${temp_dir}
}

function extract_template {
	local temp_dir=${1}
	local template=${2}
	local destiny=${3}

	local template_origin="${temp_dir}/modules/integrations/vercel/templates/${template}"

	echo -e "extracting ${template_origin} to ${destiny}"

	if [[ ! -d ${destiny} ]]
	then
		mkdir -p ${destiny}
	fi

	mv -v ${template_origin} ${destiny}
}

function main {
	local template=${1}
	local destiny=${2:-"$(pwd)"}

	local temp_dir=$(mktemp -d)

	clone_latest_commit ${temp_dir}

	extract_template ${temp_dir} ${template} ${destiny}

	make_destiny_a_git_repo "${destiny}/${template}"
}

function make_destiny_a_git_repo {
	local destiny=${1}

	cd ${destiny} && git init && git add . && git commit -m "chore: clone template"
}

main "${@}"