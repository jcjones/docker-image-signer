#!/bin/bash
# Copyright 2015 James 'J.C.' Jones https://github.com/jcjones/
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Signs Docker images with GnuPG

usage() {
  >&2 echo "Usage:"
  >&2 echo " $0 [image name] [GPG Key ID]"
}

die () {
  >&2 echo "[Fatal] $*"
  exit 1
}

saveCheckfile() {
  if [ ! -r ${IMAGE_SAFENAME}.tar ]; then
    >&2 echo "Copying from Docker..."
    docker save ${IMAGE_NAME} > ${IMAGE_SAFENAME}.tar ||
      die "Failed to save image ${IMAGE_NAME}"
  fi

  gpg --list-keys ${GPG_USER} > /dev/null ||
    die "Could not find secret key ID ${GPG_USER}"

  >&2 echo "Signing image ${IMAGE_NAME} to ${IMAGE_SAFENAME}.tar.${GPG_USER}.sig ..."
  gpg --local-user ${GPG_USER} --digest-algo SHA512 \
    --detach-sign ${IMAGE_SAFENAME}.tar ||
    die "Could not sign."
  mv ${IMAGE_SAFENAME}.tar.sig ${IMAGE_SAFENAME}.tar.${GPG_USER}.sig
}

# Main

if [ $# -ne 2 ] ; then
  usage
  exit 1
fi

IMAGE_NAME=$1
IMAGE_SAFENAME=$(echo ${IMAGE_NAME} | tr / .)
GPG_USER=$2

docker inspect ${IMAGE_NAME} > /dev/null ||
  die "Could not find docker image ${IMAGE_NAME}"

gpg --list-keys ${GPG_USER} > /dev/null ||
  die "Could not find secret key ID ${GPG_USER}"

saveCheckfile
