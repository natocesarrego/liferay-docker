#!/bin/bash

source build_bundle_image.sh --test
source _test_common.sh

function main {
	set_up

	test_set_parent_image_2025_q1_0
	test_set_parent_image_2024_q3_0
	test_set_parent_image_2024_q2_0
	test_set_parent_image_7_4_13_u124
	test_set_parent_image_7_4_13_u125
	test_set_parent_image_7_4_3_120_ga120
	test_set_parent_image_7_4_3_125_ga125
	test_set_parent_image_7_3_10_u36
	test_set_parent_image_7_2_10_8

	tear_down
}

function set_dockerfile {
	echo -e "FROM --platform=amd64 liferay/${1}:latest AS liferay-${1}\n" > "${4}"
	echo -e "FROM liferay-${2}\n" >> "${4}"
	echo "${3}" >> "${4}"
}

function set_up {
	export TEMP_DIR="${PWD}"
}

function tear_down {
	unset TEMP_DIR
}

function test_set_parent_image_2025_q1_0 {
	LIFERAY_DOCKER_RELEASE_VERSION="2025.q1.0"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_2024_q3_0 {
	LIFERAY_DOCKER_RELEASE_VERSION="2024.q3.0"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_2024_q2_0 {
	LIFERAY_DOCKER_RELEASE_VERSION="2024.q2.0"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk11" "jdk11" "" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_4_13_u124 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.4.13-u124"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk11" "jdk11" "" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_4_13_u125 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.4.13-u125"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_4_3_120_ga120 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.4.3.120-ga120"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk11" "jdk11" "" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_4_3_125_ga125 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.4.3.125-ga125"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_3_10_u36 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.3.10-u36"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk11-jdk8" "jdk11" "" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

function test_set_parent_image_7_2_10_8 {
	LIFERAY_DOCKER_RELEASE_VERSION="7.2.10.8"

	set_dockerfile "jdk21" "jdk21" "RUN rm -fr /opt/liferay/data/elasticsearch7" "Dockerfile"

	set_parent_image

	set_dockerfile "jdk11-jdk8" "jdk11" "" "expected.Dockerfile"

	assert_equals Dockerfile expected.Dockerfile

	rm -f Dockerfile
	rm -f expected.Dockerfile
}

main