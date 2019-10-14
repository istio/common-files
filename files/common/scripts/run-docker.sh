#!/bin/bash

# WARNING: DO NOT EDIT, THIS FILE IS PROBABLY A COPY
#
# The original version of this file is located in the https://github.com/istio/common-files repo.
# If you're looking at this file in a different repo and want to make a change, please go to the
# common-files repo, make the change there and check it in. Then come back to this repo and run
# "make update-common".

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

# set -ex

local_arch=$(uname -m)
if [[ $local_arch == x86_64 ]]; then
    target_arch=amd64
elif [[ $local_arch == armv8* ]]; then
    target_arch=arm64
elif [[ $local_arch == armv* ]]; then
    target_arch=arm
else
    echo "This system's architecture, $local_arch, isn't supported"
    exit 1
fi

local_os=$(uname)
if [[ $local_os == Linux ]]; then
    target_os=linux
    readlink_flags="-f"
elif [[ $local_os == Darwin ]]; then
    target_os=darwin
    readlink_flags=""
else
    echo "This system's OS, $local_os, isn't supported"
    exit 1
fi

timezone=$(readlink $readlink_flags /etc/localtime | sed -e 's/^.*zoneinfo\///')

out="${TARGET_OUT:-/work/out/${target_arch}_${target_os}}"

image="${IMG:-gcr.io/istio-testing/build-tools:2019-10-11T13-37-52}"

container_cli="${CONTAINER_CLI:-docker}"

parent_env="-e \"$(env | grep -v "^_\|PATH\|SHELL\|EDITOR\|TMUX\|USER\|HOME\|PWD\|TERM\|GO\|rvm\|SSH" | awk 'ORS="\" -e \""' | sed 's/ -e "$//')"

"$container_cli" pull "$image"

# $CONTAINER_OPTIONS becomes an empty arg when quoted, so SC2086 is disabled for the
# following command only
# shellcheck disable=SC2086
"$container_cli" run -it --rm -u "$(id -u):docker" \
    --sig-proxy=true \
    ${DOCKER_SOCKET_MOUNT:+"-v /var/run/docker.sock:/var/run/docker.sock"} \
    -v /etc/passwd:/etc/passwd:ro \
    $CONTAINER_OPTIONS \
    "$parent_env" \
    -e IN_BUILD_CONTAINER=1 \
    -e TZ="${timezone:-$TZ}" \
    -e TARGET_ARCH="${TARGET_ARCH:-$target_arch}" \
    -e TARGET_OS="${TARGET_OS:-$target_os}" \
    -e TARGET_OUT="$out" \
    --mount "type=bind,source=$(pwd),destination=/work" \
    --mount "type=volume,source=go,destination=/go" \
    --mount "type=volume,source=gocache,destination=/gocache" \
    -w /work "$image" "$@"

