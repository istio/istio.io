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

# @setup external-istiod

set -e
set -u
set -o pipefail

# Initialize KUBECONFIG_FILES and KUBE_CONTEXTS
_set_kube_vars

# set_clusters_env_vars initializes all variables.
function set_clusters_env_vars
{
  export KUBECONFIG_EXTERNAL_CP_CLUSTER="${KUBECONFIG_FILES[0]}"
  export KUBECONFIG_USER_CLUSTER="${KUBECONFIG_FILES[2]}"
  export CTX_EXTERNAL_CP="${KUBE_CONTEXTS[0]}"
  export CTX_USER_CLUSTER="${KUBE_CONTEXTS[2]}"
}

function install_istio_on_external_cp_cluster {
    echo "Installing Istio default profile on External control plane cluster: ${CTX_EXTERNAL_CP}"

    snip_setup_the_external_control_plane_cluster_1
    echo y | snip_setup_the_external_control_plane_cluster_2


    # echo "Waiting for the east-west gateway to have an external IP"
    # _verify_like snip_install_the_eastwest_gateway_in_cluster1_2 "$snip_install_the_eastwest_gateway_in_cluster1_2_out"

    # TODO: change to use passthrough instead due to limitation in test env
    echo "Exposing the to be installed istiod on the ingress gateway"
    snip_setup_the_external_control_plane_cluster_3
    snip_setup_the_external_control_plane_cluster_4
}

function install_istio_lite_on_remote_cluster {
    echo "Installing Istio on remote config cluster: ${CTX_USER_CLUSTER}"

    # TODO need to set remote pilot addr
    snip_setup_remote_cluster_1
    echo y | snip_setup_remote_cluster_2
}

function install_istiod_on_external_cp_cluster {
  echo "Installing external Istiod on external control plane cluster: ${CTX_EXTERNAL_CP}"

  snip_setup_external_istiod_in_the_control_plane_cluster_1
  snip_setup_external_istiod_in_the_control_plane_cluster_2
  echo y | snip_setup_the_external_control_plane_cluster_2
  # TODO patch istiod service with custom dns name

}

time install_istio_on_external_cp_cluster
time install_istio_lite_on_remote_cluster
time install_istiod_on_external_cp_cluster

# @cleanup
source content/en/docs/setup/install/multicluster/common.sh
set +e # ignore cleanup errors
set_multi_network_vars
time cleanup

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
