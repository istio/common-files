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

# Get the current release of the build-tools image by looking at IMAGE_VESION in
# ../files/common/scripts/setup_env.sh
imageRelease=$(grep IMAGE_VERSION= files/common/scripts/setup_env.sh | sed -e 's/^.*=//' | cut -f1,2 -d'-')

# If this isn't a release- branch, cut after the first -
if [[ "$imageRelease" != "release-"* ]]; then
  imageRelease=$(echo "$imageRelease" | cut -f1 -d'-')
fi

# Get the latest build-tools image for the given release
newBuildImage=$(curl -sL https://gcr.io/v2/istio-testing/build-tools/tags/list | jq '."manifest"[]["tag"]' | awk '/'$imageRelease'/ && !/latest/' | sort -r | sed  -e 's/^[[:space:]]*"//' -e 's/".*//' | head -n 1)
echo Updating IMAGE_VERSION to "$newBuildImage"

# Update the setup_env script with the new image name
# Since common-files doesn't use a build image, make this sed work on both Mac and Ubuntu
sed -i.bak -e "s/IMAGE_VERSION=.*/IMAGE_VERSION=$newBuildImage/" files/common/scripts/setup_env.sh && rm files/common/scripts/setup_env.sh.bak
