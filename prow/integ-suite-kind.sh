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
TOPOLOGY="SINGLE_CLUSTER"

# This is relevant only when multicluster topology is picked
CLUSTER_TOPOLOGY_CONFIG_FILE="./prow/config/topology/multi-cluster.json"

PARAMS=()

while (( "$#" )); do
  case $1 in
    --topology)
      case $2 in
        SINGLE_CLUSTER | MULTICLUSTER)
          TOPOLOGY=$2
          ;;
        *)
          echo "unknown topology: $2. Valid ones: SINGLE_CLUSTER, MULTICLUSTER"
          exit 1
          ;;
      esac
      shift 2
      ;;

    --topology-config)
      CLUSTER_TOPOLOGY_CONFIG_FILE=$2
      shift 2
      ;;

    --token-path)
      ACCESS_TOKEN=$(cat "$2")
      shift 2
      ;;

    -*)
      echo "Error: unsupported flag: $1" >&2
      exit 1
      ;;

    *)
      PARAMS+=("$1")
      shift
      ;;
  esac
done

if [ -n "${PULL_NUMBER:-}" ]; then
  echo "Optimizing tests for pull number: $PULL_NUMBER"
  TESTS=$(python3 ./scripts/pr_tests.py --token="${ACCESS_TOKEN:-}" "$PULL_NUMBER")
  if [ "$TESTS" = "NONE" ]; then
    echo "No tests affected by the current changes"
    exit 0
  elif [ "$TESTS" != "ALL" ]; then
    PARAMS+=("TEST=$TESTS")
  fi
fi

export IP_FAMILY="${IP_FAMILY:-ipv4}"
export NODE_IMAGE="gcr.io/istio-testing/kind-node:v1.27.3"

if [[ -z "${SKIP_SETUP:-}" ]]; then
  export ARTIFACTS="${ARTIFACTS:-$(mktemp -d)}"
  export DEFAULT_CLUSTER_YAML="./prow/config/default.yaml"
  export METRICS_SERVER_CONFIG_DIR=''

  if [[ "${TOPOLOGY}" == "SINGLE_CLUSTER" ]]; then
    time setup_kind_cluster "istio-testing" "${NODE_IMAGE}"
  else
    time load_cluster_topology "${CLUSTER_TOPOLOGY_CONFIG_FILE}"
    time setup_kind_clusters "${NODE_IMAGE}" "${IP_FAMILY}"

    export TEST_ENV=kind-metallb
    export DOCTEST_KUBECONFIG
    DOCTEST_KUBECONFIG=$(IFS=','; echo "${KUBECONFIGS[*]}")

    ITER_END=$((NUM_CLUSTERS-1))
    declare -a NETWORK_TOPOLOGIES

    for i in $(seq 0 $ITER_END); do
      NETWORK_TOPOLOGIES+=("$i:test-network-${CLUSTER_NETWORK_ID[$i]}")
    done

    export DOCTEST_NETWORK_TOPOLOGY
    DOCTEST_NETWORK_TOPOLOGY=$(IFS=','; echo "${NETWORK_TOPOLOGIES[*]}")
  fi
fi

make "${PARAMS[@]}"
