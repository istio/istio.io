#!/usr/bin/env bash
# shellcheck disable=SC2154

# Copyright 2023 Istio Authors
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

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=none

set -e
set -u
set -o pipefail

# Kubernetes Gateway API CRDs are required by waypoint proxy.
snip_download_and_install_2

# install istio with ambient profile
if [ "$GATEWAY_API" == "true" ]; then
  snip_download_and_install_5
else
  snip_download_and_install_3
fi

_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

if [ "$GATEWAY_API" == "true" ]; then
  _verify_like snip_download_and_install_9 "$snip_download_and_install_9_out"
  _verify_like snip_download_and_install_10 "$snip_download_and_install_10_out"
else
  _verify_like snip_download_and_install_7 "$snip_download_and_install_7_out"
  _verify_like snip_download_and_install_8 "$snip_download_and_install_8_out"
fi

# deploy test application
snip_deploy_the_sample_application_1
snip_deploy_the_sample_application_2

if [ "$GATEWAY_API" == "true" ]; then
  snip_deploy_the_sample_application_5
  snip_deploy_the_sample_application_6
else
  snip_deploy_the_sample_application_3
  snip_deploy_the_sample_application_4
fi

# test traffic before ambient mode is enabled
_verify_contains snip_verify_traffic_sleep_to_ingress "$snip_verify_traffic_sleep_to_ingress_out"
_verify_contains snip_verify_traffic_sleep_to_productpage "$snip_verify_traffic_sleep_to_productpage_out"
_verify_contains snip_verify_traffic_notsleep_to_productpage "$snip_verify_traffic_notsleep_to_productpage_out"

_verify_same snip_adding_your_application_to_the_ambient_mesh_1 "$snip_adding_your_application_to_the_ambient_mesh_1_out"

# test traffic after ambient mode is enabled
snip_adding_your_application_to_the_ambient_mesh_2
_verify_contains snip_adding_your_application_to_the_ambient_mesh_3 "received netns, starting proxy"
_verify_same snip_adding_your_application_to_the_ambient_mesh_4 "$snip_adding_your_application_to_the_ambient_mesh_4_out"
_verify_same snip_adding_your_application_to_the_ambient_mesh_5 "$snip_adding_your_application_to_the_ambient_mesh_5_out"
_verify_same snip_adding_your_application_to_the_ambient_mesh_6 "$snip_adding_your_application_to_the_ambient_mesh_6_out"

snip_layer_4_authorization_policy_1
_verify_contains snip_layer_4_authorization_policy_2 "$snip_layer_4_authorization_policy_2_out"
_verify_contains snip_layer_4_authorization_policy_3 "$snip_layer_4_authorization_policy_3_out"
_verify_failure snip_layer_4_authorization_policy_4

_verify_contains snip_layer_7_authorization_policy_1 "$snip_layer_7_authorization_policy_1_out"
_verify_contains snip_layer_7_authorization_policy_2 "Resource programmed, assigned to service"
snip_layer_7_authorization_policy_3
_verify_contains snip_layer_7_authorization_policy_4 "$snip_layer_7_authorization_policy_4_out"
_verify_contains snip_layer_7_authorization_policy_5 "$snip_layer_7_authorization_policy_5_out"
_verify_contains snip_layer_7_authorization_policy_6 "$snip_layer_7_authorization_policy_6_out"

_verify_contains snip_control_traffic_1 "$snip_control_traffic_1_out"

if [ "$GATEWAY_API" == "true" ]; then
  snip_control_traffic_3
else
  snip_control_traffic_2
fi

_verify_lines snip_control_traffic_4 "
+ reviews-v1
+ reviews-v2
- reviews-v3
"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_uninstall_1
    snip_uninstall_2
    snip_uninstall_3
    samples/bookinfo/platform/kube/cleanup.sh
    snip_uninstall_4
    snip_uninstall_5
fi
