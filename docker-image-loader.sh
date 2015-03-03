#!/bin/bash
# Copyright 2015 James 'J.C.' Jones https://github.com/jcjones/
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Verifies with GPG and loads Docker images
usage() {
  >&2 echo "Verify a Docker image has been signed by a certain number of"
  >&2 echo "trusted GPG keys, and if so, load it into Docker."
  >&2 echo ""
  >&2 echo "Usage:"
  >&2 echo " MIN_SIGNATURES=2 $0 [image name]"
  >&2 echo ""
  >&2 echo " MIN_SIGNATURES=2 $0 [full path to image tar file]"
}

die () {
  >&2 echo "[Fatal] $*"
  exit 1
}

containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# Arg1: Signature file
# Arg2: Signed image file
verifySignature() {
  local sig=$1
  local image=$2
  local result

  if ! result=$(gpg --verbose --verify ${sig} ${image} 2>&1) ; then
    echo "Invalid signature ${sig}"
    return 1
  fi

  # Require SHA512
  if ! echo ${result} | grep SHA512 > /dev/null ; then
    echo "Invalid digest"
    return 1
  fi

  # Require good signature
  if ! echo ${result} | grep "Good signature" > /dev/null ; then
    echo "Not Good."
    return 1
  fi

  # We don't want a WARNING
  if echo ${result} | grep WARNING > /dev/null; then
    echo "WARNING caught: ${result}"
    return 1
  fi

  local keyID=$(echo ${result} | sed -e "s/.*key ID \([A-z0-9]*\).*/\1/")

  if containsElement ${keyID} ${KEYS_ARRAY}; then
    # Duplicate keys are not OK.
    echo "Duplicate signing keyID: ${keyID}!"
    return 1
  fi

  echo "Good signature from ${keyID} in file ${sig}"

  # push this key ID onto the array
  KEYS_ARRAY+=(${keyID})

  return 0
}

# Main

if [ $# -ne 1 ] || [ "x${MIN_SIGNATURES}" == "x" ] ; then
  usage
  exit 1
fi

# If the argument provided begins with ./ or / then assume it's a
# complete path.
if echo "$1" | egrep '^[\.]*/' ; then
  IMAGE_FILE=$1
else
  # Otherwise, assume it's relative to the docker-image-downloader.
  DOWNLOADED_STORAGE=/var/docker-image-downloader
  IMAGE_SAFENAME=$(echo $1 | tr "/: " .)
  IMAGE_FILE=${DOWNLOADED_STORAGE}/${IMAGE_SAFENAME}/${IMAGE_SAFENAME}.tar
fi

[ -r ${IMAGE_FILE} ] || die "Could not read file ${IMAGE_FILE}"

KEYS_ARRAY=()

for sig in ${IMAGE_FILE}.*.sig; do
  echo "Verifying ${sig}..."

  verifySignature ${sig} ${IMAGE_FILE}
done

if [ ${#KEYS_ARRAY[@]} -lt ${MIN_SIGNATURES} ]; then
  die "Too few signatures! ${MIN_SIGNATURES} required, ${#KEYS_ARRAY[@]} provided."
fi

echo "${#KEYS_ARRAY[@]} signatures are good, ${MIN_SIGNATURES} required. Importing into Docker..."

# We haven't aborted, so let's instruct docker to load the signed image.
docker load --input=${IMAGE_FILE} ||
  die "Failed to load into Docker"

echo "Load complete."