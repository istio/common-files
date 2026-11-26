#!/bin/bash

# Copyright Istio Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# shellcheck source-path=SCRIPTDIR
set -euo pipefail

# shellcheck source=./kind_provisioner.sh
source "$(dirname "$0")/kind_provisioner.sh"
set +x

calls=$(mktemp)
trap 'rm -f "${calls}"' EXIT
function docker() {
  printf '%s\n' "$@" >> "${calls}"
  printf '%s\n' "${api_host}"
  return "${docker_status}"
}
function helm() {
  printf '%s\n' "$@" >> "${calls}"
  return "${helm_status}"
}
function kubectl() {
  printf '%s\n' "$@" >> "${calls}"
  return "${kubectl_status}"
}

KIND_IP_FAMILY=ipv4
api_host=172.18.0.2
helm_status=0
docker_status=0
kubectl_status=0
install_cilium test-cluster
for flag in '1.18.14' 'bpf.hostLegacyRouting=false' 'bpf.masquerade=true' \
  'endpointRoutes.enabled=true' 'cni.exclusive=false' 'kubeProxyReplacement=true' \
  'k8sServiceHost=172.18.0.2' 'test-cluster-control-plane' 'daemonset/cilium'; do
  grep -Fxq -- "${flag}" "${calls}"
done

KIND_IP_FAMILY=dual
if install_cilium test-cluster; then
  echo "Expected unsupported IP family to fail." >&2
  exit 1
fi

KIND_IP_FAMILY=ipv4
api_host=""
if install_cilium test-cluster; then
  echo "Expected missing API address to fail." >&2
  exit 1
fi

api_host=172.18.0.2
docker_status=1
if install_cilium test-cluster; then
  echo "Expected Docker failure to propagate." >&2
  exit 1
fi

docker_status=0
helm_status=1
: > "${calls}"
if install_cilium test-cluster; then
  echo "Expected Helm failure to propagate." >&2
  exit 1
fi

if grep -Fxq 'daemonset/cilium' "${calls}"; then
  echo "Must not report rollout success after Helm fails." >&2
  exit 1
fi

helm_status=0
kubectl_status=1
if install_cilium test-cluster; then
  echo "Expected rollout failure to propagate." >&2
  exit 1
fi
