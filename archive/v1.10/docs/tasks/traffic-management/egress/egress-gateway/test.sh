#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

# Copyright 2020 Istio Authors
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

# @setup profile=demo

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# Deploy sleep sample and set up variable pointing to it
# Start the sleep sample
startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

# Create ServiceEntry
snip_egress_gateway_for_http_traffic_1
# Verify curl to cnn
_verify_contains snip_egress_gateway_for_http_traffic_2 "HTTP/2 200"

# Create Gateway
snip_egress_gateway_for_http_traffic_3
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-cnn

# Create VS
snip_egress_gateway_for_http_traffic_4
_wait_for_istio virtualservice default direct-cnn-through-egress-gateway

# Verify successful curl
_verify_contains snip_egress_gateway_for_http_traffic_5 "HTTP/2 200"

# Verify routing through gateway
_verify_contains snip_egress_gateway_for_http_traffic_6 "GET /politics HTTP/2"

# cleanup http task
snip_cleanup_http_gateway_1

# ServiceEntry for HTTPS
snip_egress_gateway_for_https_traffic_1

# Try and verify curl
_verify_contains snip_egress_gateway_for_https_traffic_2 "HTTP/2 200"

# Gateway Passthrough dr and vs
snip_egress_gateway_for_https_traffic_3
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-cnn
_wait_for_istio virtualservice default direct-cnn-through-egress-gateway

# Verify successful curl
_verify_contains snip_egress_gateway_for_https_traffic_4 "HTTP/2 200"

# Verify gateway routing
_verify_contains snip_egress_gateway_for_https_traffic_5 "outbound|443||edition.cnn.com"

# cleanup https
snip_cleanup_https_gateway_1

### Kubernetes netowkring policy test

# Create namespace
snip_apply_kubernetes_network_policies_1

# Deploy sleep
snip_apply_kubernetes_network_policies_2

# Verify 200 response
_verify_contains snip_apply_kubernetes_network_policies_4 "200"

# label
snip_apply_kubernetes_network_policies_5
snip_apply_kubernetes_network_policies_6

# Apply kubernetes network policy
snip_apply_kubernetes_network_policies_7

# Verify failure
#_verify_contains snip_apply_kubernetes_network_policies_8 "port 443 failed: Connection timed out"
# TODO: ^^^ this check fails as the test cluster doesn't have a network plugin
# installed which can enforce network policies.

# Enable sidecar injection
snip_apply_kubernetes_network_policies_9

# Delete older sleep and reapply
snip_apply_kubernetes_network_policies_10
_wait_for_deployment test-egress sleep

# verify containers
_verify_contains snip_apply_kubernetes_network_policies_11 "sleep istio-proxy"

# configure DR
snip_apply_kubernetes_network_policies_12
_wait_for_istio destinationrule test-egress egressgateway-for-cnn

# Verify 200 response
_verify_contains snip_apply_kubernetes_network_policies_13 "200"

# Verify routing through gateway
_verify_contains snip_apply_kubernetes_network_policies_14 "outbound|443||edition.cnn.com"

# @cleanup
snip_cleanup_http_gateway_1
snip_cleanup_https_gateway_1
snip_cleanup_network_policies_1
snip_cleanup_1
