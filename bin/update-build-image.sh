#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -e

ROOT="$(cd -P "$(dirname -- "$0")" && pwd -P)"
TOOLS_IMAGE_REGISTRY_LIST_URL="${TOOLS_IMAGE_REGISTRY_LIST_URL:-https://gcr.io/v2/istio-testing/build-tools/tags/list}"

# Allow passing in the new IMAGE_VERSION using that as an environment variable
# or using --image <IMAGE_VERSION>. The parameter has a higher priority.
# Did not use getopts to parse parameters and yield errors since this script
# should run on Macs as there is no build container used in this repo.
newBuildImage=$IMAGE_VERSION
if [[ "$1" == "--image" ]]; then
  newBuildImage=$2
fi

# If IMAGE_VERSION isn't specified, get the latest tag for the currently used release in
# ../files/common/scripts/setup_env.sh
if [ -z "$newBuildImage" ] ; then
  imageRelease=$(grep IMAGE_VERSION= ${ROOT}/../files/common/scripts/setup_env.sh | sed -e 's/^.*=//' | cut -f1,2 -d'-')

  # If this isn't a release- branch, cut after the first -
  if [[ "$imageRelease" != "release-"* ]]; then
    imageRelease=$(echo "$imageRelease" | cut -f1 -d'-')
  fi

  # Get the latest build-tools image for the given release
  newBuildImage=$(curl -sL $TOOLS_IMAGE_REGISTRY_LIST_URL | jq '."manifest"[]["tag"]' | awk '/'$imageRelease'/ && !/latest/' | sort -r | sed  -e 's/^[[:space:]]*"//' -e 's/".*//' | head -n 1)

# If no IMAGE_VERSION is specified and one is not found, output an error
  if [ -z "$newBuildImage" ] ; then
    echo No valid IMAGE_VERSION found to replace the current value
    exit 1
  fi
fi

# Update the setup_env script with the new image name
# Since common-files doesn't use a build image, make this sed work on both Mac and Ubuntu
echo Updating IMAGE_VERSION to "$newBuildImage"
sed -i.bak -e "s/IMAGE_VERSION=.*/IMAGE_VERSION=$newBuildImage/" ${ROOT}/../files/common/scripts/setup_env.sh && rm ${ROOT}/../files/common/scripts/setup_env.sh.bak
