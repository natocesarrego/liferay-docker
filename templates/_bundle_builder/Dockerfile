FROM --platform=${TARGETPLATFORM} liferay/base:latest

RUN mkdir /build

# Common
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes build-essential ca-certificates curl libfreetype6-dev libjpeg-dev liblzma-dev libpng-dev libtiff-dev pkg-config zlib1g-dev

# Ffmpeg
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --yes libass-dev libfaac-dev libmp3lame-dev libopus-dev libsdl2-dev libtheora-dev libvorbis-dev libvpx-dev libx264-dev libx265-dev yasm

RUN curl -L -o /build/ffmpeg.tar.gz https://ffmpeg.org/releases/ffmpeg-7.1.tar.gz && \
    cd /build && \
    tar -xvzf ffmpeg.tar.gz && \
    cd ffmpeg-* && \
    mkdir build && \
    cd build && \
    ../configure --enable-gpl --enable-libass --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --enable-nonfree --enable-sdl2 --enable-shared --enable-version3 && \
    make -j$(nproc) && \
    make install && \
    rm -rf /build/*

# Ghostscript
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes libcups2-dev

RUN curl -L -o /build/ghostscript.tar.gz https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs10040/ghostscript-10.04.0.tar.gz && \
    cd /build && \
    tar -xvzf ghostscript.tar.gz && \
    cd ghostscript-* && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    rm -rf /build/*

# Libheif (Required for ImageMagick)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes cmake libde265-dev ninja-build x265

RUN mkdir -p /build && \
    curl -L -o /build/libheif.tar.gz https://github.com/strukturag/libheif/releases/download/v1.19.5/libheif-1.19.5.tar.gz && \
    cd /build && \
    tar -xvzf libheif.tar.gz && \
    cd libheif-* && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -G Ninja && \
    ninja && \
    ninja install && \
    ldconfig /usr/local/lib && \
    rm -rf /build/*

# ImageMagick
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes libgif-dev libltdl-dev libwebp-dev libx11-dev libxext-dev libxml2-dev

RUN curl -L -o /build/ImageMagick.tar.gz https://download.imagemagick.org/ImageMagick/download/releases/ImageMagick-7.1.1-43.tar.gz && \
    cd /build && \
    tar -xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    ldconfig /usr/local/lib && \
    rm -rf /build/*

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --no-install-recommends --yes bc file fonts-dejavu google-perftools gifsicle libtcnative-1 && \
    apt-get upgrade --yes && \
    apt-get clean


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