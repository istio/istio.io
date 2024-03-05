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

GATEWAY_API="${GATEWAY_API:-false}"

source "tests/util/samples.sh"

# Make sure default namespace is injected
kubectl label namespace default istio-injection=enabled || true

# Deploy sleep sample and set up variable pointing to it
# Start the sleep sample
startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

# Create ServiceEntry
snip_egress_gateway_for_http_traffic_1
# Verify curl to cnn
_verify_contains snip_egress_gateway_for_http_traffic_2 "HTTP/2 200"

# Create Gateway and Routes
if [ "$GATEWAY_API" == "true" ]; then
    snip_egress_gateway_for_http_traffic_4
    snip_egress_gateway_for_http_traffic_6
    _wait_for_gateway default cnn-egress-gateway
    sleep 30 # TODO: remove this delay once we can reliably detect route rules have propogated
else
    snip_egress_gateway_for_http_traffic_3
    _wait_for_istio gateway default istio-egressgateway
    _wait_for_istio destinationrule default egressgateway-for-cnn

    snip_egress_gateway_for_http_traffic_5
    _wait_for_istio virtualservice default direct-cnn-through-egress-gateway
fi

# Verify successful curl
_verify_contains snip_egress_gateway_for_http_traffic_7 "HTTP/2 200"

# Verify routing through gateway
if [ "$GATEWAY_API" == "true" ]; then
    _verify_contains snip_egress_gateway_for_http_traffic_11 "outbound|80||edition.cnn.com"
    _verify_contains snip_egress_gateway_for_http_traffic_13 "$snip_egress_gateway_for_http_traffic_13_out"
else
    _verify_contains snip_egress_gateway_for_http_traffic_8 "outbound|80||edition.cnn.com"
    _verify_contains snip_egress_gateway_for_http_traffic_10 "$snip_egress_gateway_for_http_traffic_10_out"
fi

# cleanup http task
if [ "$GATEWAY_API" == "true" ]; then
    snip_cleanup_http_gateway_2
else
    snip_cleanup_http_gateway_1
fi

# ServiceEntry for HTTPS
snip_egress_gateway_for_https_traffic_1

# Try and verify curl
_verify_contains snip_egress_gateway_for_https_traffic_2 "HTTP/2 200"

# Gateway Passthrough and routes
if [ "$GATEWAY_API" == "true" ]; then
    snip_egress_gateway_for_https_traffic_4
    _wait_for_gateway default cnn-egress-gateway
    sleep 30 # TODO: remove this delay once we can reliably detect route rules have propogated
else
    snip_egress_gateway_for_https_traffic_3
    _wait_for_istio gateway default istio-egressgateway
    _wait_for_istio destinationrule default egressgateway-for-cnn
    _wait_for_istio virtualservice default direct-cnn-through-egress-gateway
fi

# Verify successful curl
_verify_contains snip_egress_gateway_for_https_traffic_5 "HTTP/2 200"

# Verify gateway routing
if [ "$GATEWAY_API" == "true" ]; then
    _verify_contains snip_egress_gateway_for_https_traffic_8 "outbound|443||edition.cnn.com"
else
    _verify_contains snip_egress_gateway_for_https_traffic_6 "outbound|443||edition.cnn.com"
fi

# cleanup https
#if [ "$GATEWAY_API" == "true" ]; then
#    snip_cleanup_https_gateway_2
#else
#    snip_cleanup_https_gateway_1
#fi

### Kubernetes netowkring policy test

# Create namespace
snip_apply_kubernetes_network_policies_1

# Deploy sleep
snip_apply_kubernetes_network_policies_2

# Verify 200 response
_verify_contains snip_apply_kubernetes_network_policies_4 "200"

# label
if [ "$GATEWAY_API" == "true" ]; then
    snip_apply_kubernetes_network_policies_6
else
    snip_apply_kubernetes_network_policies_5
fi
snip_apply_kubernetes_network_policies_7

# Apply kubernetes network policy
if [ "$GATEWAY_API" == "true" ]; then
    snip_apply_kubernetes_network_policies_9
else
    snip_apply_kubernetes_network_policies_8
fi

# Verify failure
#_verify_contains snip_apply_kubernetes_network_policies_10 "port 443 failed: Connection timed out"
# TODO: ^^^ this check fails as the test cluster doesn't have a network plugin
# installed which can enforce network policies.

# Enable sidecar injection
snip_apply_kubernetes_network_policies_11

# Delete older sleep and reapply
snip_apply_kubernetes_network_policies_12
_wait_for_deployment test-egress sleep

if [ "$GATEWAY_API" == "true" ]; then
    # verify containers
    _verify_contains snip_apply_kubernetes_network_policies_15 "sleep istio-proxy"
else
    # verify containers
    _verify_contains snip_apply_kubernetes_network_policies_13 "sleep istio-proxy"

    # configure DR
    snip_apply_kubernetes_network_policies_14
    _wait_for_istio destinationrule test-egress egressgateway-for-cnn
fi

# Verify 200 response
_verify_contains snip_apply_kubernetes_network_policies_16 "200"

# Verify routing through gateway
if [ "$GATEWAY_API" == "true" ]; then
    _verify_contains snip_apply_kubernetes_network_policies_19 "outbound|443||edition.cnn.com"
else
    _verify_contains snip_apply_kubernetes_network_policies_17 "outbound|443||edition.cnn.com"
fi

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_http_gateway_1
    snip_cleanup_https_gateway_1
    snip_cleanup_network_policies_1
    snip_cleanup_1
fi
