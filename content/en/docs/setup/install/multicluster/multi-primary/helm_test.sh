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

function install_istio_helm {
  # Install Istio on the 2 clusters. Executing in
  # parallel to reduce test time.
  install_istio_on_cluster1_helm &
  install_istio_on_cluster2_helm &
  wait
}

function install_istio_on_cluster1_helm {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER1}"
    snip_configure_cluster1_as_a_primary_3
    snip_configure_cluster1_as_a_primary_4
}

function install_istio_on_cluster2_helm {
    echo "Installing Istio on Primary cluster: ${CTX_CLUSTER2}"
    snip_configure_cluster2_as_a_primary_3
    snip_configure_cluster2_as_a_primary_4
}

function enable_endpoint_discovery {
  snip_enable_endpoint_discovery_1
  snip_enable_endpoint_discovery_2
}

time configure_trust
time install_istio_helm
time enable_endpoint_discovery
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
