#!/bin/bash

source _liferay_common.sh

function add_jira_ticket_comment {
	local ref_data=$(
		cat <<- END
		{
			"body": {
				"content": [
					{
						"content": [
							{
								"text": "${1}",
								"type": "text"
							}
						],
						"type": "paragraph"
					}
				],
				"type": "doc",
				"version": 1
			}
		}
		END
	)

	local http_response=$(curl \
		"https://liferay.atlassian.net/rest/api/3/issue/${2}/comment" \
		--data "${ref_data}" \
		--header 'Accept: application/json' \
		--header 'Content-Type: application/json' \
		--request POST \
		--user "${LIFERAY_RELEASE_JIRA_USER}:${LIFERAY_RELEASE_JIRA_TOKEN}")

	if [ "$(echo "${http_response}" | jq --exit-status '.id?')" != "null" ]
	then
		return "${LIFERAY_COMMON_EXIT_CODE_OK}"
	fi

	return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
}

function create_jira_ticket {
	local ref_data=$(
		cat <<- END
		{
			"fields": {
				"assignee": {
					"id": "${1}"
				},
				"components": [
					{
					"name": "${2}"
					}
				],
				"issuetype": {
					"name": "${3}"
				},
				"project": {
					"key": "${5}"
				},
				"summary": "${4}",
				"${6}": "${7}"
			}
		}
		END
	)

	local http_response=$(curl \
		"https://liferay.atlassian.net/rest/api/3/issue/" \
		--data "${ref_data}" \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--request POST \
		--user "${LIFERAY_RELEASE_JIRA_USER}:${LIFERAY_RELEASE_JIRA_TOKEN}")

	if [ "$(echo "${http_response}" | jq --exit-status '.id?')" != "null" ]
	then
		echo "${http_response}" | jq --raw-output '.key'

		return "${LIFERAY_COMMON_EXIT_CODE_OK}"
	fi

	return "${LIFERAY_COMMON_EXIT_CODE_BAD}"
}