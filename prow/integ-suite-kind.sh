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


# Usage: ./integ-suite-kind.sh TARGET
# Example: ./integ-suite-kind.sh test.integration.pilot.kube.presubmit

WD=$(dirname "$0")
WD=$(cd "$WD"; pwd)
ROOT=$(dirname "$WD")

# Exit immediately for non zero status
set -e
# Check unset variables
set -u
# Print commands
set -x

# shellcheck source=common/scripts/kind_provisioner.sh
source "${ROOT}/common/scripts/kind_provisioner.sh"

# KinD will not have a LoadBalancer, so we need to disable it
export TEST_ENV=kind

# KinD will have the images loaded into it; it should not attempt to pull them
# See https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster
export PULL_POLICY=IfNotPresent
export HUB=${HUB:-"gcr.io/istio-testing"}

# Setup junit report and verbose logging
export T="${T:-"-v"}"
export CI="true"

# TOPOLOGY must be specified. Based on that we pick the topology
# configuration file that is used to bring up KinD environment.
TOPOLOGY="${TOPOLOGY:-"SINGLE_CLUSTER"}"
if [[ "${TOPOLOGY}" == "SINGLE_CLUSTER" ]]; then
  CLUSTER_TOPOLOGY_CONFIG_FILE="./prow/config/cluster_config_single.json"
else
  CLUSTER_TOPOLOGY_CONFIG_FILE="./prow/config/cluster_config_multi.json"
fi

if [[ -z "${SKIP_SETUP:-}" ]]; then
  export ARTIFACTS="${ARTIFACTS:-$(mktemp -d)}"
  export DEFAULT_CLUSTER_YAML="./prow/config/trustworthy-jwt.yaml"
  export METRICS_SERVER_CONFIG_DIR=''
  
  time load_cluster_topology "${CLUSTER_TOPOLOGY_CONFIG_FILE}"
  time setup_kind_clusters

  export KUBECONFIG
  KUBECONFIG=$(IFS=':'; echo "${KUBECONFIGS[*]}")
fi

make "${@}"
