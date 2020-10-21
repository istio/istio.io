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
set_single_network_vars

function install_istio_on_cluster1 {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER1}"
    snip_install_istio_17
    echo y | snip_install_istio_18

    echo "Creating the east-west gateway"
    snip_install_istio_19

    echo "Waiting for the east-west gateway to have an external IP"
    _wait_for_gateway_ip istio-system istio-eastwestgateway "${CTX_CLUSTER1}"

    echo "Exposing istiod via the east-west gateway"
    snip_install_istio_20
}

function install_istio_on_cluster2 {
    echo "Installing Istio on Remote cluster: ${CTX_CLUSTER2}"
    snip_install_istio_22
    snip_install_istio_23
    echo y | snip_install_istio_24
}

function configure_api_server_access {
  snip_install_istio_21
}

time configure_trust
time install_istio_on_cluster1
time configure_api_server_access
time install_istio_on_cluster2
time verify_load_balancing

# @cleanup
source content/en/docs/setup/install/multicluster/common.sh
set +e # ignore cleanup errors
set_single_network_vars
time cleanup

# Everything should be removed once cleanup completes. Use a small
# number of retries for comparing cluster snapshots before/after the test.
export VERIFY_RETRIES=1
