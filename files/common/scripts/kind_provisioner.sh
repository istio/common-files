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

set -e

export CLUSTER_TOPOLOGY_CONFIG=${1:-""}

if [[ -z "${CLUSTER_TOPOLOGY_CONFIG_FILE}" ]]; then
  echo 'cluster topology configuration file is not specified'
  exit 1
fi

export CLUSTER_NAMES=$(jq -r '.[].cluster_name' ${CLUSTER_TOPOLOGY_CONFIG_FILE})
export CLUSTER_POD_SUBNETS=$(jq -r '.[].pod_subnet' ${CLUSTER_TOPOLOGY_CONFIG_FILE})
export CLUSTER_SVC_SUBNETS=$(jq -r '.[].svc_subnet' ${CLUSTER_TOPOLOGY_CONFIG_FILE})
export CLUSTER_NETWORK_ID=$(jq -r '.[].svc_subnet' ${CLUSTER_TOPOLOGY_CONFIG_FILE})

# cleanup_kind_cluster takes a single parameter NAME
# and deletes the KinD cluster with that name
function cleanup_kind_cluster() {
  NAME="${1}"
  echo "Test exited with exit code $?."
  kind export logs --name "${NAME}" "${ARTIFACTS}/kind" -v9 || true
  if [[ -z "${SKIP_CLEANUP:-}" ]]; then
    echo "Cleaning up kind cluster"
    kind delete cluster --name "${NAME}" -v9 || true
  fi
}

# setup_kind_cluster creates new KinD cluster with given name, image and configuration
# 1. CLUSTER_CONFIG: KinD cluster configuration YAML file (mandatory)
# 2. NAME: Name of the Kind cluster (optional)
# 3. IMAGE: Node image used by KinD (optional)
# 4. IP_FAMILY: valid values are ipv4 and ipv6.
function setup_kind_cluster() {
  CLUSTER_CONFIG="${1}"
  NAME="${2:-istio-testing}"
  IMAGE="${3:-kindest/node:v1.18.2}"
  IP_FAMILY="${4:-ipv4}"

  # Cluster configuration must be specified
  if [[ -z "${CLUSTER_CONFIG}" ]]; then
    echo 'cluster configuration YAML must be specified'
    exit 1
  fi

  # Delete any previous KinD cluster
  echo "Deleting previous KinD cluster with name=${NAME}"
  if ! (kind delete cluster --name="${NAME}" -v9) > /dev/null; then
    echo "No existing kind cluster with name ${NAME}. Continue..."
  fi

  # Patch cluster configuration if IPv6 is required
  if [ "${IP_FAMILY}" = "ipv6" ]; then
    grep 'ipFamily: ipv6' ${CLUSTER_CONFIG} || \
    cat <<EOF >> "${CLUSTER_CONFIG}"
networking:
  ipFamily: ipv6
EOF
  fi

  # explicitly disable shellcheck since we actually want $NAME to expand now
  # shellcheck disable=SC2064
  trap "cleanup_kind_cluster ${NAME}" EXIT

  # Create KinD cluster
  if ! (kind create cluster --name="${NAME}" --config "${CONFIG}" -v9 --retain --image "${IMAGE}" --wait=60s); then
    echo "Could not setup KinD environment. Something wrong with KinD setup. Exporting logs."
    exit 1
  fi
}

# deploy_metrics_server deploys metrics server
function deploy_metrics_server() {
  METRICS_SERVER_CONFIG_DIR=${1}
  kubectl apply -f ${METRICS_SERVER_CONFIG_DIR}
}
