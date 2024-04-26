FROM --platform=${TARGETPLATFORM} ubuntu:jammy AS ubuntu-jammy

COPY resources/etc/created-date /etc/created-date

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes build-essential ca-certificates curl jq less libnghttp2-dev libnss3 libssl-dev nghttp2 telnet tini tree unzip && \
	apt-get upgrade --yes && \
	apt-get clean

	RUN VERSION=8.7.1 && \
	curl https://curl.se/download/curl-${VERSION}.tar.gz --output curl-${VERSION}.tar.gz && \
	tar -xzvf curl-${VERSION}.tar.gz && \
	rm -f curl-${VERSION}.tar.gz && \
	cd curl-${VERSION} && \
	apt-get remove curl -y && \
	rm -rf /usr/bin/curl* && \
	./configure --prefix=/usr/local --with-ssl --with-nghttp2 --enable-static && \
	make -j4 && \
	make install && \
	ldconfig && \
	cd .. && \
	rm -rf curl-${VERSION} && \
	apt-get remove build-essential libnghttp2-dev libssl-dev nghttp2 -y

RUN VERSION=5.2 && \
	curl https://ftp.gnu.org/gnu/bash/bash-${VERSION}.tar.gz --output bash-${VERSION}.tar.gz && \
	tar -xzvf bash-${VERSION}.tar.gz && \
	rm -f bash-${VERSION}.tar.gz && \
	cd bash-${VERSION} && \
	./configure --prefix=/usr && \
	make -j4 && \
	make install && \
	cd .. && \
	rm -rf bash-${VERSION}

RUN adduser --disabled-password --home /home/liferay liferay --uid 1000 && \
	addgroup liferay liferay && \
	usermod -g 1000 liferay

FROM ubuntu-jammy

ARG LABEL_BUILD_DATE
ARG LABEL_NAME
ARG LABEL_VCS_REF
ARG LABEL_VCS_URL
ARG LABEL_VERSION
ARG TARGETPLATFORM

ENV LANG="C.UTF-8"

LABEL org.label-schema.build-date="${LABEL_BUILD_DATE}"
LABEL org.label-schema.name="${LABEL_NAME}"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vcs-ref="${LABEL_VCS_REF}"
LABEL org.label-schema.vcs-url="${LABEL_VCS_URL}"
LABEL org.label-schema.vendor="Liferay, Inc."
LABEL org.label-schema.version="${LABEL_VERSION}"