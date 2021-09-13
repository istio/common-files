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
set -euxo pipefail

# This script needs two istio repositories, tools and common-files, expecting
# both will be cloned into a common parent directory. This script will
# traverse to the tools repository to build new build-tools images and then
# return.
ROOT="$(cd -P "$(dirname -- "$0")" && pwd -P)"

# pushd to the tools repo and build the images. Use tee so we can see
# the build output as well as saving it to get the IMAGE_VERSION.
pushd ${ROOT}/../../tools
make containers 2>&1 | tee make.out
IMAGE_VERSION=$(grep "+ VERSION" make.out | sed -e 's/.*=//')
popd

# Update the common files with the image version. As noted above, the expectation is
# that common-files and tools are both in a parent directory. In the case of the build
# pipeline this is true (both are under ~/prow/go/srd/istio.io). However, the pipeline
# has cloned a copy of the common-files repository to /tmp/./src/istio.io/common-files
# to watch for changes.
# In the case of the pipeline, we want to run the bin/update_build_image.sh from the
# automator cloned directory ($AUTOMATOR_REPO_DIR).
if [ -n "$AUTOMATOR_REPO_DIR" ]; then ROOT=${AUTOMATOR_REPO_DIR}/bin; fi
${ROOT}/update-build-image.sh --image $IMAGE_VERSION
