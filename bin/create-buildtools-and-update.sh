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

# This script needs two istio repositories, tools and common-files, expecting
# both will be cloned into a common parent directory. This script will
# traverse to the tools repository to build new build-tools images and then
# return, finally running the script to update the IMAGE_VERSION.
ROOT="$(cd -P "$(dirname -- "$0")" && pwd -P)"

# pushd to the tools repo and build the images. Use tee so we can see
# the build output as well as saving it to get the IMAGE_VERSION.
pushd ${ROOT}/../../tools
make containers 2>&1 | tee make.out
IMAGE_VERSION=$(grep "+ VERSION" make.out | sed -e 's/.*=//')
popd

# Update the common files with the image version
${ROOT}/update-build-image.sh --image $IMAGE_VERSION
