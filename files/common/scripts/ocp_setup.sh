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
set -x

# The purpose of this file is to unify ocp setup in both istio/istio and istio-ecosystem/sail-operator.
# repos to avoid code duplication. This is needed to setup the OCP environment for the tests.

WD=$(dirname "$0")
WD=$(cd "$WD"; pwd)
TIMEOUT=300
export NAMESPACE="${NAMESPACE:-"istio-system"}"

function setup_internal_registry() {
  # Validate that the internal registry is running in the OCP Cluster, configure the variable to be used in the make target. 
  # If there is no internal registry, the test can't be executed targeting to the internal registry

  # Check if the registry pods are running
  oc get pods -n openshift-image-registry --no-headers | grep -v "Running\|Completed" && echo "It looks like the OCP image registry is not deployed or Running. This tests scenario requires it. Aborting." && exit 1

  # Check if default route already exist
  if [ -z "$(oc get route default-route -n openshift-image-registry -o name)" ]; then
    echo "Route default-route does not exist, patching DefaultRoute to true on Image Registry."
    oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
  
    timeout --foreground -v -s SIGHUP -k ${TIMEOUT} ${TIMEOUT} bash --verbose -c \
      "until oc get route default-route -n openshift-image-registry &> /dev/null; do sleep 5; done && echo 'The 'default-route' has been created.'"
  fi

  # Get the registry route
  URL=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  # Hub will be equal to the route url/project-name(NameSpace) 
  export HUB="${URL}/${NAMESPACE}"
  echo "Internal registry URL: ${HUB}"

  # Create namespace from where the image are going to be pushed
  # This is needed because in the internal registry the images are stored in the namespace.
  # If the namespace already exist, it will not fail
  oc create namespace "${NAMESPACE}" || true

  deploy_rolebinding

  # Login to the internal registry when running on CRC (Only for local development)
  # Take into count that you will need to add before the registry URL as Insecure registry in "/etc/docker/daemon.json"
  if [[ ${URL} == *".apps-crc.testing"* ]]; then
    echo "Executing Docker login to the internal registry"
    if ! oc whoami -t | docker login -u "$(oc whoami)" --password-stdin "${URL}"; then
      echo "***** Error: Failed to log in to Docker registry."
      echo "***** Check the error and if is related to 'tls: failed to verify certificate' please add the registry URL as Insecure registry in '/etc/docker/daemon.json'"
      exit 1
    fi
  fi
}

function deploy_rolebinding() {
    # Adding roles to avoid the need to be authenticated to push images to the internal registry 
    # and pull them later in the any namespace
      echo '
kind: List
apiVersion: v1
items:
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: image-puller
    namespace: '"$NAMESPACE"'
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:image-puller
  subjects:
  - kind: Group
    apiGroup: rbac.authorization.k8s.io
    name: system:unauthenticated
- apiVersion: rbac.authorization.k8s.io/v1
  kind: RoleBinding
  metadata:
    name: image-pusher
    namespace: '"$NAMESPACE"'
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: system:image-builder
  subjects:
  - kind: Group
    apiGroup: rbac.authorization.k8s.io
    name: system:unauthenticated
' | oc apply -f -
}