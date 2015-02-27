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
  >&2 echo " MIN_SIGNATURES=2 $0 [image tar file]"
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

# Main

if [ $# -ne 1 ] || [ "x${MIN_SIGNATURES}" == "x" ] ; then
  usage
  exit 1
fi

IMAGE_FILE=$1

KEYS_ARRAY=()

for sig in ${IMAGE_FILE}.*.sig; do
  echo "Verifying ${sig}..."

  result=$(gpg --verbose --verify ${sig} ${IMAGE_FILE} 2>&1) ||
    die "Invalid signature ${sig}"

  echo ${result} | grep SHA512 > /dev/null ||
    die "Invalid digest"

  echo ${result} | grep Good > /dev/null ||
    die "Not Good."

  echo ${result} | grep WARNING > /dev/null &&
    die "WARNING caught: ${result}"

  keyID=$(echo ${result} | sed -e "s/.*key ID \([A-z0-9]*\).*/\1/")

  if containsElement ${keyID} ${KEYS_ARRAY}; then
    die "Duplicate signing keyID: ${keyID}!"
  fi

  echo "Good signature from ${keyID} in file ${sig}"

  # push this key ID onto the array
  KEYS_ARRAY+=(${keyID})
done

if [ ${#KEYS_ARRAY[@]} -lt ${MIN_SIGNATURES} ]; then
  die "Too few sigatures! ${MIN_SIGNATURES} required, ${#KEYS_ARRAY[@]} provided."
fi

echo "Importing into Docker..."

# We haven't aborted, so let's instruct docker to load the signed image.
docker load --input=${IMAGE_FILE} ||
  die "Failed to load into Docker"

echo "Load complete."