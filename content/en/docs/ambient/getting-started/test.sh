#!/usr/bin/env bash
# shellcheck disable=SC2154

# Copyright 2024 Istio Authors
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

# @setup profile=none

set -e
set -u
set -o pipefail

source "content/en/docs/ambient/getting-started/deploy-sample-app/snips.sh"
source "content/en/docs/ambient/getting-started/secure-and-visualize/snips.sh"
source "content/en/docs/ambient/getting-started/enforce-auth-policies/snips.sh"
source "content/en/docs/ambient/getting-started/manage-traffic/snips.sh"
source "content/en/docs/ambient/getting-started/cleanup/snips.sh"

snip_install_ambient
snip_install_k8s_gateway_api

_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

snip_deploy_the_bookinfo_application_1
snip_deploy_bookinfo_gateway
_wait_for_deployment default bookinfo-gateway-istio
snip_annotate_bookinfo_gateway
_wait_for_deployment default bookinfo-gateway-istio
_verify_like snip_deploy_and_configure_the_ingress_gateway_3 "$snip_deploy_and_configure_the_ingress_gateway_3_out"

_verify_contains snip_add_bookinfo_to_the_mesh_1 "$snip_add_bookinfo_to_the_mesh_1_out"

snip_deploy_l4_policy
snip_deploy_sleep
_wait_for_deployment default sleep
_verify_contains snip_enforce_layer_4_authorization_policy_3 "$snip_enforce_layer_4_authorization_policy_3_out"

snip_deploy_waypoint
_wait_for_deployment default waypoint
_verify_contains snip_deploy_waypoint "$snip_deploy_waypoint_out"

_verify_like snip_enforce_layer_7_authorization_policy_2 "$snip_enforce_layer_7_authorization_policy_2_out"

snip_deploy_l7_policy

_verify_contains snip_enforce_layer_7_authorization_policy_4 "$snip_enforce_layer_7_authorization_policy_4_out"
_verify_contains snip_enforce_layer_7_authorization_policy_5 "$snip_enforce_layer_7_authorization_policy_5_out"
_verify_contains snip_enforce_layer_7_authorization_policy_6 "$snip_enforce_layer_7_authorization_policy_6_out"

snip_deploy_httproute
snip_test_traffic_split

_verify_lines snip_test_traffic_split "
+ reviews-v1
+ reviews-v2
- reviews-v3
"

# @cleanup
snip_remove_the_ambient_and_waypoint_labels_1
snip_remove_waypoint_proxies_and_uninstall_istio_1
snip_remove_the_sample_application_1
samples/bookinfo/platform/kube/cleanup.sh
snip_remove_the_kubernetes_gateway_api_crds_1