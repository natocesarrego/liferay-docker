#!/bin/bash

source ../_liferay_common.sh
source ../_releases_json.sh

function merge_json_snipets_test {
    local earliest_url
    local latest_url

   	if [ "${1}" == "dxp" ]
    then
        earliest_url="$(jq -r '.[0].url' < "$(find ./20*dxp*.json | head -n 1)")"
        latest_url="$(jq -r '.[0].url' < "$(find ./20*dxp*.json | sort -r | head -n 1)")"
    else
        earliest_url="$(jq -r '.[0].url' < "$(find ./20*ga*.json | head -n 1)")"
        latest_url="$(jq -r '.[0].url' < "$(find ./20*ga*.json | sort -r | head -n 1)")"
    fi

    local earliest_count="$(grep -c "${earliest_url}" releases.json)"
    local latest_count="$(grep -c "${latest_url}" releases.json)"

    if [[ "${earliest_count}" -eq 0 || "${latest_count}" -eq 0 ]]
    then
        echo Test failed

        exit
    fi

    echo Test passed
}

function promote_product_versions_test {
    local product_name=${1}

    while read -r group_version || [ -n "${group_version}" ]
	do
		# shellcheck disable=SC2010
		last_version=$(ls | grep "${product_name}-${group_version}" | tail -n 1 2>/dev/null)

		if [ -n "${last_version}" ]
		then
            if [ "$(jq -r '.[] | .promoted' "${last_version}")" = false ]
            then
                echo "Test failed. ""${last_version}"" should be promoted."

                exit
            fi
		fi
	done < "${_RELEASE_ROOT_DIR}/supported-${product_name}-versions.txt"

    echo Test passed
}

function setup {
    export _RELEASE_ROOT_DIR="$(dirname "${PWD}")"
}

function tear_down {
    unset _RELEASE_ROOT_DIR
    rm ./*.json
}

setup
_process_product dxp
_promote_product_versions dxp
_merge_json_snippets
merge_json_snipets_test dxp
promote_product_versions_test dxp
tear_down