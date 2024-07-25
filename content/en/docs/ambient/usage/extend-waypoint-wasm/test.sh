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

# @setup profile=ambient

set -e
set -u
set -o pipefail

source "content/en/boilerplates/snips/gateway-api-install-crds.sh"
source "content/en/boilerplates/snips/gateway-api-remove-crds.sh"
source "content/en/docs/ambient/getting-started/snips.sh"
source "content/en/docs/ambient/getting-started/secure-and-visualize/snips.sh"
source "content/en/docs/ambient/getting-started/enforce-auth-policies/snips.sh"
source "content/en/docs/ambient/getting-started/manage-traffic/snips.sh"
source "content/en/docs/ambient/getting-started/deploy-sample-app/snips.sh"
source "content/en/docs/ambient/getting-started/cleanup/snips.sh"

# Kubernetes Gateway API CRDs are required by waypoint proxy.
bpsnip_gateway_api_install_crds_install_crds

_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system ztunnel
_wait_for_daemonset istio-system istio-cni-node

# deploy test application
snip_deploy_the_bookinfo_application_1
snip_deploy_sleep

snip_deploy_bookinfo_gateway
_wait_for_deployment default bookinfo-gateway-istio
snip_annotate_bookinfo_gateway
_wait_for_deployment default bookinfo-gateway-istio
_verify_like snip_deploy_and_configure_the_ingress_gateway_3 "$snip_deploy_and_configure_the_ingress_gateway_3_out"

# adding applications to ambient mesh
_verify_contains snip_add_bookinfo_to_the_mesh_1 "$snip_add_bookinfo_to_the_mesh_1_out"

# Display existing gateways and verify output
_verify_like snip_configure_wasmplugin_for_gateway_1 "$snip_configure_wasmplugin_for_gateway_1_out"

# Configure WASM plugin for gateway
snip_configure_wasmplugin_for_gateway_2

# verify traffic via gateway
_verify_same snip_verify_the_traffic_via_the_gateway_1 "$snip_verify_the_traffic_via_the_gateway_2_out"
_verify_same snip_verify_the_traffic_via_the_gateway_2 "$snip_verify_the_traffic_via_the_gateway_2_out"

# Deploy a waypoint proxy
snip_deploy_a_waypoint_proxy_1

# verify traffic_without wasmplugin at the waypoint
_verify_same snip_verify_traffic_without_wasmplugin_at_the_waypoint_1 "$snip_verify_traffic_without_wasmplugin_at_the_waypoint_1_out"

# Display existing gateways and verify output
_verify_like snip_apply_wasmplugin_at_waypoint_proxy_1 "$snip_apply_wasmplugin_at_waypoint_proxy_1_out"

# apply wasmplugin at waypoint proxy
snip_apply_wasmplugin_at_waypoint_proxy_2

# Display applied wasmplugins and verify output
_verify_like snip_view_the_configured_wasmplugin_1 "$snip_view_the_configured_wasmplugin_1_out"

# verify the traffic via waypoint proxy
_verify_same snip_verify_the_traffic_via_waypoint_proxy_1 "$snip_verify_the_traffic_via_waypoint_proxy_1_out"
_verify_same snip_verify_the_traffic_via_waypoint_proxy_2 "$snip_verify_the_traffic_via_waypoint_proxy_2_out"

# apply wasmplugin for a specific service using waypoint
snip_apply_wasmplugin_for_a_specific_service_using_waypoint_1

# verify the traffic targeting the service
_verify_same snip_verify_the_traffic_targeting_the_service_1 "$snip_verify_the_traffic_targeting_the_service_1_out"
_verify_same snip_verify_the_traffic_targeting_the_service_2 "$snip_verify_the_traffic_targeting_the_service_2_out"
_verify_same snip_verify_the_traffic_targeting_the_service_3 "$snip_verify_the_traffic_targeting_the_service_3_out"

# @cleanup
snip_cleanup_1
snip_remove_the_ambient_and_waypoint_labels_1
snip_remove_waypoint_proxies_1
snip_remove_the_sample_application_1
samples/bookinfo/platform/kube/cleanup.sh
bpsnip_gateway_api_remove_crds_remove_crds
