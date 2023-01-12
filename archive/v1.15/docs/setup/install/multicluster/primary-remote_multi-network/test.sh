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
    snip_configure_cluster1_as_a_primary_1
    echo y | snip_configure_cluster1_as_a_primary_2

    echo "Creating the east-west gateway"
    snip_install_the_eastwest_gateway_in_cluster1_1

    echo "Waiting for the east-west gateway to have an external IP"
    _verify_like snip_install_the_eastwest_gateway_in_cluster1_2 "$snip_install_the_eastwest_gateway_in_cluster1_2_out"

    echo "Exposing istiod via the east-west gateway"
    snip_expose_the_control_plane_in_cluster1_1

    echo "Exposing services via the east-west gateway"
    snip_expose_services_in_cluster1_1
}

function enable_api_server_access {
    snip_attach_cluster2_as_a_remote_cluster_of_cluster1_1
}

function install_istio_on_cluster2 {
    echo "Installing Istio on Remote cluster: ${CTX_CLUSTER2}"
    snip_set_the_control_plane_cluster_for_cluster2_1
    snip_set_the_default_network_for_cluster2_1
    snip_configure_cluster2_as_a_remote_1
    snip_configure_cluster2_as_a_remote_2
    echo y | snip_configure_cluster2_as_a_remote_3

    echo "Creating the east-west gateway"
    snip_install_the_eastwest_gateway_in_cluster2_1

    echo "Waiting for the east-west gateway to have an external IP"
    _verify_like snip_install_the_eastwest_gateway_in_cluster2_2 "$snip_install_the_eastwest_gateway_in_cluster2_2_out"

    echo "Exposing services via the east-west gateway"
    snip_expose_services_in_cluster2_1
}

time install_istio_on_cluster1
time install_istio_on_cluster2
time enable_api_server_access
time verify_load_balancing

# @cleanup
source content/en/docs/setup/install/multicluster/common.sh
set_multi_network_vars
time cleanup

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
