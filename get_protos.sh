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

REPODIR="$(pwd)"

# Temporary directories securely created
TEMPDIR_PROTOCOLBUFFERS="$(mktemp -d /tmp/google-XXXXXXXX)"
TEMPDIR_GOOGLEAPIS="$(mktemp -d /tmp/googleapis-XXXXXXXX)"
TEMPDIR_API="$(mktemp -d /tmp/api-XXXXXXXX)"
TEMPDIR_APIMACHINERY="$(mktemp -d /tmp/apimachinery-XXXXXXXX)"
TEMPDIR_GOGO="$(mktemp -d /tmp/gogo-XXXXXXXX)"
TEMPDIR_PROTOCGENVALIDATE="$(mktemp -d /tmp/genvalidate-XXXXXXXX)"

# Upstream GIT tags or branches used for protobufs by repo
PROTOCOLBUFFERS_TAG="516f8b15603b7f7613e2fb957c55bc56a36b64a6"
GOOGLEAPIS_TAG="e121a35579e73377f998c11bcc09ba0486736404"
API_TAG="eb06f43765d3e053d360c9f9755d15004c35e5f9"
APIMACHINERY_TAG="508c689428e40ab183bc7d43cac6738714bdd3dc"
GOGO_TAG="4c00d2f19fb91be5fecd8681fa83450a2a979e69"
PROTOCGENVALIDATE_TAG="b2e4ad3b1fe3766cf83f85a6b3755625cacf9410"

# Retrieve a copy of Googles's protobufs
pushd "${TEMPDIR_PROTOCOLBUFFERS}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/protocolbuffers/protobuf.git
pushd protobuf || exit
git checkout "${PROTOCOLBUFFERS_TAG}"
popd || exit
pushd protobuf/src/google || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/google
popd || exit
popd || exit

# Retrieve a copy of Googles's protobufs including api, rpc, and type
pushd "${TEMPDIR_GOOGLEAPIS}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/googleapis/googleapis.git
pushd googleapis || exit
git checkout "${GOOGLEAPIS_TAG}"
popd || exit
pushd googleapis/google/api || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/google/api
popd || exit
pushd googleapis/google/rpc || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/google/rpc
popd || exit
pushd googleapis/google/type || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/google/type
popd || exit
popd || exit

# Retrieve a copy of K8s api proto files
pushd "${TEMPDIR_API}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/kubernetes/api.git
pushd api || exit
git checkout "${API_TAG}"
popd || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/k8s.io
popd || exit

# Retrieve a copy of K8s apimachinery proto files
pushd "${TEMPDIR_APIMACHINERY}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/kubernetes/apimachinery.git
pushd apimachinery || exit
git checkout ${APIMACHINERY_TAG}
popd || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/k8s.io
popd || exit

# Retrieve a copy of gogo's proto files
pushd "${TEMPDIR_GOGO}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/gogo/protobuf.git
pushd protobuf || exit
git checkout ${GOGO_TAG}
popd || exit
pushd protobuf/gogoproto/ || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/gogoproto
popd || exit
popd || exit

# Retrieve a copy of envoyproxy's protoc-gen-validate files
pushd "${TEMPDIR_PROTOCGENVALIDATE}" || exit
git clone --depth 1 --single-branch --branch master https://github.com/envoyproxy/protoc-gen-validate.git
pushd protoc-gen-validate || exit
git checkout ${PROTOCGENVALIDATE_TAG}
popd || exit
find . -name \*proto | cpio -pdm "${REPODIR}"/common-protos/github.com/envoyproxy
popd || exit

# Clean up junk that is not needed
find common-protos -name vendor -exec rm -rf {} \; > /dev/null 2>&1
find common-protos -name \*test\* -exec rm -rf {} \; > /dev/null 2>&1

# Clean up temporary directories
rm -rf "${TEMPDIR_GOOGLE}" > /dev/null 2>&1
rm -rf "${TEMPDIR_GOOGLEAPIS}" > /dev/null 2>&1
rm -rf "${TEMPDIR_API}" > /dev/null 2>&1
rm -rf "${TEMPDIR_APIMACHINERY}" > /dev/null 2>&1
rm -rf "${TEMPDIR_GOGO}" > /dev/null 2>&1
rm -rf "${TEMPDIR_PROTOCGENVALIDATE}" > /dev/null 2>&1
