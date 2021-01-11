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

# This scripts obtains proto files used by the Istio project from upstream
# locations. The proto file's repository is pinned. The pinned protos
# are then copied into a directory called "protos".

set -x
REPODIR="$(pwd)"

# Temporary directories securely created
TEMPDIR_PROTOCOLBUFFERS="$(mktemp -d /tmp/google-XXXXXXXX)"
TEMPDIR_GOOGLEAPIS="$(mktemp -d /tmp/googleapis-XXXXXXXX)"
TEMPDIR_API="$(mktemp -d /tmp/api-XXXXXXXX)"
TEMPDIR_APIMACHINERY="$(mktemp -d /tmp/apimachinery-XXXXXXXX)"
TEMPDIR_GOGO="$(mktemp -d /tmp/gogo-XXXXXXXX)"
TEMPDIR_PROTOCGENVALIDATE="$(mktemp -d /tmp/genvalidate-XXXXXXXX)"
TEMPDIR_OPENCENSUS="$(mktemp -d /tmp/opencensus-XXXXXXXX)"
TEMPDIR_PROMETHEUS="$(mktemp -d /tmp/prometheus-XXXXXXXX)"

# Upstream GIT tags or branches used for protobufs by repo
PROTOCOLBUFFERS_TAG="fde7cf7358ec7cd69e8db9be4f1fa6a5c431386a"
GOOGLEAPIS_TAG="1d5522ad1056f16a6d593b8f3038d831e64daeea"
API_TAG="94c4f9061bc5a4b826b39418fc2ea3422505d25f"
APIMACHINERY_TAG="2a282836017bf9a6d16c6bbc8ac3d4fdddc6a418"
GOGO_TAG="0ca988a254f991240804bf9821f3450d87ccbb1b"

rm -fr common-protos
mkdir common-protos

# Copy istio extension protobufs
echo "istio.io/*"
cp -a "${REPODIR}"/protos/istio.io "${REPODIR}"/common-protos/istio.io

# Retrieve a copy of Googles's protobufs
echo "google/*"
pushd "${TEMPDIR_PROTOCOLBUFFERS}" >/dev/null || exit
git clone -q --single-branch --branch master https://github.com/protocolbuffers/protobuf.git
pushd protobuf >/dev/null || exit
git checkout -q "${PROTOCOLBUFFERS_TAG}"
popd >/dev/null || exit
pushd protobuf/src/google  >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/google
popd >/dev/null || exit
popd >/dev/null || exit

# Retrieve a copy of Googles's protobufs including api, rpc, and type
echo "google/*/*"
pushd "${TEMPDIR_GOOGLEAPIS}" >/dev/null || exit
git clone -q --single-branch --branch master https://github.com/googleapis/googleapis.git
pushd googleapis >/dev/null || exit
git checkout -q "${GOOGLEAPIS_TAG}"
popd >/dev/null || exit
pushd googleapis/google/api >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/google/api
popd >/dev/null || exit
pushd googleapis/google/rpc >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/google/rpc
popd >/dev/null || exit
pushd googleapis/google/type >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/google/type
popd >/dev/null || exit
popd >/dev/null || exit

# Retrieve a copy of K8s api proto files
echo "kubernetes/api"
pushd "${TEMPDIR_API}" >/dev/null || exit
git clone -q --single-branch --branch master https://github.com/kubernetes/api.git
git checkout -q "${API_TAG}"
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/k8s.io
popd >/dev/null || exit

# Retrieve a copy of K8s apimachinery proto files
echo "kubernetes/apimachinery"
pushd "${TEMPDIR_APIMACHINERY}" >/dev/null || exit
git clone -q --single-branch --branch master https://github.com/kubernetes/apimachinery.git
git checkout -q ${APIMACHINERY_TAG}
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/k8s.io
popd >/dev/null || exit

# Retrieve a copy of gogo's proto files
echo "gogo"
pushd "${TEMPDIR_GOGO}" >/dev/null || exit
git clone -q --single-branch --branch master https://github.com/gogo/protobuf.git
pushd protobuf >/dev/null || exit
git checkout -q ${GOGO_TAG}
pushd protobuf >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/github.com/gogo/protobuf/protobuf
popd >/dev/null || exit
popd >/dev/null || exit
pushd protobuf/gogoproto/ >/dev/null || exit
find . -name \*proto | cpio --quiet -pdm "${REPODIR}"/common-protos/gogoproto
popd >/dev/null || exit
popd >/dev/null || exit

# Clean up junk that is not needed
find common-protos -name vendor -exec rm -rf {} \; > /dev/null 2>&1
find common-protos -name \*test\* -exec rm -rf {} \; > /dev/null 2>&1
find common-protos -name \*ruby\* -exec rm -rf {} \; > /dev/null 2>&1

# Clean up temporary directories
rm -rf "${TEMPDIR_GOOGLE}" > /dev/null 2>&1
rm -rf "${TEMPDIR_GOOGLEAPIS}" > /dev/null 2>&1
rm -rf "${TEMPDIR_API}" > /dev/null 2>&1
rm -rf "${TEMPDIR_APIMACHINERY}" > /dev/null 2>&1
rm -rf "${TEMPDIR_GOGO}" > /dev/null 2>&1
