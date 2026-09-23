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
setup_helm_repo
snip_create_istio_system_namespace_cluster_1

function install_istio_on_cluster1_helm {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER1}"
    snip_configure_cluster1_as_a_primary_3
    snip_configure_cluster1_as_a_primary_4

    echo "Creating the east-west gateway"
    snip_install_the_eastwest_gateway_in_cluster1_2

    echo "Waiting for the east-west gateway to have an external IP"
    _verify_like snip_install_the_eastwest_gateway_in_cluster1_3 "$snip_install_the_eastwest_gateway_in_cluster1_3_out"
    snip_install_the_eastwest_gateway_in_cluster1_3

    echo "Exposing istiod via the east-west gateway"
    snip_expose_the_control_plane_in_cluster1_1
}

function install_istio_on_cluster2_helm {
    echo "Installing Istio on Remote cluster: ${CTX_CLUSTER2}"
    snip_set_the_control_plane_cluster_for_cluster2_1
    snip_configure_cluster2_as_a_remote_1
    snip_configure_cluster2_as_a_remote_4
    snip_configure_cluster2_as_a_remote_5
}

function enable_api_server_access {
    snip_attach_cluster2_as_a_remote_cluster_of_cluster1_1
}

# @TODO: We need to fix this... for some reason, the CRDs don't seem to exist in cluster2 here anymore?
snip_delete_crds || true
time install_istio_on_cluster1_helm
time install_istio_on_cluster2_helm
time enable_api_server_access
time verify_load_balancing

# @cleanup
source content/en/docs/setup/install/multicluster/common.sh
set_single_network_vars

function cleanup_cluster1_helm {
  snip_cleanup_3
  snip_cleanup_4
  snip_delete_sample_ns_cluster_1
}

function cleanup_cluster2_helm {
  snip_cleanup_5
  snip_cleanup_6
  snip_delete_sample_ns_cluster_2
}

function cleanup_helm {
  cleanup_cluster1_helm
  cleanup_cluster2_helm
  snip_delete_crds
}

time cleanup_helm

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
