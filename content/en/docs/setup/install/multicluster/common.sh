#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2034,SC2154

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

# Initialize KUBECONFIG_FILES and KUBE_CONTEXTS
_set_kube_vars

# set_single_network_vars initializes all variables for a single network config.
function set_single_network_vars
{
  export CTX_CLUSTER1="${KUBE_CONTEXTS[0]}"
  export CTX_CLUSTER2="${KUBE_CONTEXTS[1]}"
}

# set_multi_network_vars initializes all variables for a multi-network config.
function set_multi_network_vars
{
  export CTX_CLUSTER1="${KUBE_CONTEXTS[0]}"
  export CTX_CLUSTER2="${KUBE_CONTEXTS[2]}"
}

# delete_namespaces removes the istio-system and sample namespaces on both
# CLUSTER1 and CLUSTER2.
function delete_namespaces()
{
  # Run the delete on both clusters concurrently
  _delete_namespaces_cluster1 &
  _delete_namespaces_cluster2 &
  wait
}

# _delete_namespaces_cluster1 removes the istio-system and sample namespaces on both
# CLUSTER1.
function _delete_namespaces_cluster1()
{
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER1}" --ignore-not-found
}

# _delete_namespaces_cluster2 removes the istio-system and sample namespaces on both
# CLUSTER2.
function _delete_namespaces_cluster2()
{
  kubectl delete ns istio-system sample --context="${CTX_CLUSTER2}" --ignore-not-found
}

# verify_load_balancing verifies that traffic is load balanced properly
# between CLUSTER1 and CLUSTER2.
function verify_load_balancing()
{
  # Deploy HelloWorld and Sleep.
  snip_deploy_the_helloworld_service_1
  snip_deploy_the_helloworld_service_2
  snip_deploy_the_helloworld_service_3
  snip_deploy_helloworld_v1_1
  snip_deploy_helloworld_v2_1
  snip_deploy_sleep_1
  snip_deploy_sleep_3

  # Wait for the deployments in CLUSTER1
  (KUBECONFIG="${KUBECONFIG_FILES[0]}"; _wait_for_deployment sample helloworld-v1)
  (KUBECONFIG="${KUBECONFIG_FILES[0]}"; _wait_for_deployment sample sleep)

  # Wait for the deployments in CLUSTER2
  (KUBECONFIG="${KUBECONFIG_FILES[1]}"; _wait_for_deployment sample helloworld-v2)
  (KUBECONFIG="${KUBECONFIG_FILES[1]}"; _wait_for_deployment sample sleep)

  # Verify that traffic is load balanced from both clusters.
  _verify_lb_with_load_function snip_verifying_crosscluster_traffic_1
  _verify_lb_with_load_function snip_verifying_crosscluster_traffic_3
}

# _verify_lb_with_load_function that traffic for a given function is balanced
# between the two clusters
#
# $1: the function to be called to generate traffic.
function _verify_lb_with_load_function()
{
  local CALL_HELLOWORLD="$1"
  local PREV_OUTPUT=""
  local LOAD_BALANCED=""
  for i in {1..20}; do
    OUTPUT="$($CALL_HELLOWORLD)"
    echo "HelloWorld output: $OUTPUT"

    if [[ -n "$PREV_OUTPUT" ]] && [[ "$PREV_OUTPUT" != "$OUTPUT" ]]; then
      LOAD_BALANCED="true"
      break
    fi
    PREV_OUTPUT="$OUTPUT"

    # Wait before trying again
    sleep 2
  done

  if [[ -z "$LOAD_BALANCED" ]]; then
    echo "Traffic was not load balanced between the clusters"
    exit 1
  fi
}
