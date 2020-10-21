#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

# @setup multicluster

set -e
set -u
set -o pipefail

source content/en/docs/setup/install/multicluster/common.sh
set_multi_network_vars

function install_istio_on_cluster1 {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER1}"

    snip_install_istio_7
    echo y | snip_install_istio_8

    echo "Creating the east-west gateway"
    snip_install_istio_9

    echo "Waiting for the east-west gateway to have an external IP"
    _wait_for_gateway_ip istio-system istio-eastwestgateway "${CTX_CLUSTER1}"

    echo "Exposing services via the east-west gateway"
    snip_install_istio_10
}

function install_istio_on_cluster2 {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER2}"

    snip_install_istio_11
    echo y | snip_install_istio_12

    echo "Creating the east-west gateway"
    snip_install_istio_13

    echo "Exposing services via the east-west gateway"
    snip_install_istio_14
}

function install_istio {
  # Install Istio on the 2 clusters. Executing in
  # parallel to reduce test time.
  install_istio_on_cluster1 &
  install_istio_on_cluster2 &
  wait
}

function configure_endpoint_discovery {
  # Configure endpoint discovery.
  snip_install_istio_15
  snip_install_istio_16
}

time configure_trust
time install_istio
time configure_endpoint_discovery
time verify_load_balancing

# @cleanup
source content/en/docs/setup/install/multicluster/common.sh
set +e # ignore cleanup errors
set_multi_network_vars
time cleanup

# Everything should be removed once cleanup completes. Use a small
# number of retries for comparing cluster snapshots before/after the test.
export VERIFY_RETRIES=1
