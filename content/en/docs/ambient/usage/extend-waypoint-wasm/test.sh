#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2154

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

GATEWAY_API=true

source "tests/util/gateway-api.sh"
install_gateway_api_crds

# deploy test application
source "tests/util/samples.sh"
startup_bookinfo_sample
startup_sleep_sample

# snip_annotate_bookinfo_gateway
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
_wait_for_gateway default bookinfo-gateway

kubectl label namespace default istio.io/dataplane-mode=ambient

# Display existing gateways and verify output
_verify_like snip_get_gateway "$snip_get_gateway_out"

# Configure WASM plugin for gateway
snip_apply_wasmplugin_gateway

# verify traffic via gateway
_verify_same snip_test_gateway_productpage_without_credentials "$snip_test_gateway_productpage_without_credentials_out"
_verify_same snip_test_gateway_productpage_with_credentials "$snip_test_gateway_productpage_with_credentials_out"

# Deploy a waypoint proxy
snip_create_waypoint

# verify traffic_without wasmplugin at the waypoint
_verify_same snip_verify_traffic "$snip_verify_traffic_out"

# Display existing gateways and verify output
_verify_like snip_get_gateway_waypoint "$snip_get_gateway_waypoint_out"

# apply wasmplugin at waypoint proxy
snip_apply_wasmplugin_waypoint_all

# Display applied wasmplugins and verify output
_verify_like snip_get_wasmplugin "$snip_get_wasmplugin_out"

# verify the traffic via waypoint proxy
_verify_same snip_test_waypoint_productpage_without_credentials "$snip_test_waypoint_productpage_without_credentials_out"
_verify_same snip_test_waypoint_productpage_with_credentials "$snip_test_waypoint_productpage_with_credentials_out"

# apply wasmplugin for one specific service through the waypoint
snip_apply_wasmplugin_waypoint_service

# verify the traffic targeting the service
_verify_same snip_test_waypoint_service_productpage_with_credentials "$snip_test_waypoint_service_productpage_with_credentials_out"
_verify_same snip_test_waypoint_service_reviews_with_credentials "$snip_test_waypoint_service_reviews_with_credentials_out"
_verify_same snip_test_waypoint_service_reviews_without_credentials "$snip_test_waypoint_service_reviews_without_credentials_out"

# @cleanup
snip_remove_wasmplugin

kubectl label namespace default istio.io/dataplane-mode-
kubectl label namespace default istio.io/use-waypoint-

istioctl x waypoint delete --all

cleanup_sleep_sample
cleanup_bookinfo_sample
remove_gateway_api_crds
