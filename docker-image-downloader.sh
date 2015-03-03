#!/bin/bash
# Copyright 2015 James 'J.C.' Jones https://github.com/jcjones/
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Docker Signed Image Downloader

usage() {
  >&2 echo "Usage:"
  >&2 echo " $0 [signature repository] [image name]"
  >&2 echo ""
  >&2 echo " $0 http://192.168.2.30/files debian"
}

die () {
  >&2 echo "[Fatal] $*"
  exit 1
}

if [ $# -ne 2 ] ; then
  usage
  exit 1
fi

DOWNLOADED_STORAGE=/var/docker-image-downloader/

IMAGE_REPOSITORY=$1
IMAGE_NAME=$2
IMAGE_SAFENAME=$(echo ${IMAGE_NAME} | tr "/: " .)


# Ensure the storage location exists
mkdir -p ${DOWNLOADED_STORAGE} || die "Could not create storage location"
pushd ${DOWNLOADED_STORAGE} > /dev/null

# Dowmload to the image store
curl -s -z ${IMAGE_SAFENAME}.pkg -o ${IMAGE_SAFENAME}.pkg \
  ${IMAGE_REPOSITORY}/${IMAGE_SAFENAME} \
  --write-out "%{size_download} b downloaded in %{time_total} s from %{url_effective}\n" ||
  die "Could not download a package for ${IMAGE_NAME}."

# Make a subdir for that image, if it doesn't already exist.
mkdir -p ${IMAGE_SAFENAME}
pushd ${IMAGE_SAFENAME} > /dev/null

tar zxf ../${IMAGE_SAFENAME}.pkg

# Clean up
popd > /dev/null
popd > /dev/null