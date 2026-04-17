#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

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

# @setup profile=ambient

GATEWAY_API=true

source "tests/util/gateway-api.sh"
install_gateway_api_crds

source "tests/util/samples.sh"
startup_bookinfo_sample
startup_curl_sample

kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
_wait_for_gateway default bookinfo-gateway

kubectl label namespace default istio.io/dataplane-mode=ambient

# Display existing gateways and verify output
_verify_like snip_get_gateway "$snip_get_gateway_out"

# Apply Lua parity filter at gateway
snip_apply_lua_gateway

# Verify parity header via gateway
_verify_same snip_test_gateway_parity "$snip_test_gateway_parity_out"

# Deploy a waypoint proxy
snip_create_waypoint

# Verify traffic reaches the service without filter
_verify_same snip_verify_traffic "$snip_verify_traffic_out"

# Display existing gateways and verify output
_verify_like snip_get_gateway_waypoint "$snip_get_gateway_waypoint_out"

# Apply Lua parity filter at waypoint
snip_apply_lua_waypoint_all

# Verify parity header via waypoint
_verify_same snip_test_waypoint_parity "$snip_test_waypoint_parity_out"

# Remove namespace-wide filter before applying service-specific one
snip_remove_waypoint_parity

# Apply Lua parity filter for specific service
snip_apply_lua_waypoint_service

# Verify parity header for the reviews service
_verify_same snip_test_waypoint_service_parity "$snip_test_waypoint_service_parity_out"

# @cleanup
snip_remove_traffic_extensions

kubectl label namespace default istio.io/dataplane-mode-
kubectl label namespace default istio.io/use-waypoint-

istioctl x waypoint delete --all

cleanup_curl_sample
cleanup_bookinfo_sample
remove_gateway_api_crds
