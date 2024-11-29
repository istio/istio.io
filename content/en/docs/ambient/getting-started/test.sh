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

# @setup profile=ambient

set -e
set -u
set -o pipefail

source "content/en/boilerplates/snips/gateway-api-remove-crds.sh"
source "content/en/docs/ambient/getting-started/deploy-sample-app/snips.sh"
source "content/en/docs/ambient/getting-started/secure-and-visualize/snips.sh"
source "content/en/docs/ambient/getting-started/enforce-auth-policies/snips.sh"
source "content/en/docs/ambient/getting-started/manage-traffic/snips.sh"
source "content/en/docs/ambient/getting-started/cleanup/snips.sh"

bpsnip_gateway_api_install_crds_install_crds

snip_deploy_the_bookinfo_application_1
snip_deploy_bookinfo_gateway
snip_annotate_bookinfo_gateway
_wait_for_gateway default bookinfo-gateway
_verify_like snip_deploy_and_configure_the_ingress_gateway_3 "$snip_deploy_and_configure_the_ingress_gateway_3_out"

_verify_contains snip_add_bookinfo_to_the_mesh_1 "$snip_add_bookinfo_to_the_mesh_1_out"

snip_deploy_l4_policy
snip_deploy_curl
_wait_for_deployment default curl
_verify_contains snip_enforce_layer_4_authorization_policy_3 "$snip_enforce_layer_4_authorization_policy_3_out"

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
snip_remove_waypoint_proxies_1
snip_remove_the_namespace_from_the_ambient_data_plane_1
snip_remove_the_sample_application_1
samples/bookinfo/platform/kube/cleanup.sh
bpsnip_gateway_api_remove_crds_remove_crds
