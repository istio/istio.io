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

source content/en/docs/ambient/install/multicluster/common.sh
source "tests/util/gateway-api.sh"
set_multi_network_vars

function install_istio_on_cluster1_istioctl {
    echo "Installing Gateway API CRDs on Primary cluster: ${CTX_CLUSTER1}"
    install_gateway_api_crds "${CTX_CLUSTER1}"

    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER1}"

    snip_set_the_default_network_for_cluster1_1

    snip_configure_cluster1_as_a_primary_1
    echo y | snip_configure_cluster1_as_a_primary_2

    echo "Creating the east-west gateway"
    snip_install_an_ambient_eastwest_gateway_in_cluster1_1

    echo "Waiting for the east-west gateway to have an external IP"
    _verify_like snip_install_an_ambient_eastwest_gateway_in_cluster1_4 "$snip_install_an_ambient_eastwest_gateway_in_cluster1_4_out"
}

function install_istio_on_cluster2_istioctl {
    echo "Installing Gateway API CRDs on Primary cluster: ${CTX_CLUSTER2}"
    install_gateway_api_crds "${CTX_CLUSTER2}"

    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER2}"

    snip_set_the_default_network_for_cluster2_1

    snip_configure_cluster2_as_a_primary_1
    echo y | snip_configure_cluster2_as_a_primary_2

    echo "Creating the east-west gateway"
    snip_install_an_ambient_eastwest_gateway_in_cluster2_1

    echo "Waiting for the east-west gateway to have an external IP"
    _verify_like snip_install_an_ambient_eastwest_gateway_in_cluster2_4 "$snip_install_an_ambient_eastwest_gateway_in_cluster2_4_out"
}

function install_istio_istioctl {
  # Install Istio on the 2 clusters. Executing in
  # parallel to reduce test time.
  install_istio_on_cluster1_istioctl &
  install_istio_on_cluster2_istioctl &
  wait
}

function enable_endpoint_discovery {
  snip_enable_endpoint_discovery_1
  snip_enable_endpoint_discovery_2
}

time configure_trust
time install_istio_istioctl
time enable_endpoint_discovery
time verify_load_balancing
time deploy_waypoints
time configure_locality_failover
time verify_traffic_local
time break_cluster1
time verify_failover

# @cleanup
source content/en/docs/ambient/install/multicluster/common.sh
set_multi_network_vars
time cleanup_istioctl
time snip_delete_gateway_crds

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
