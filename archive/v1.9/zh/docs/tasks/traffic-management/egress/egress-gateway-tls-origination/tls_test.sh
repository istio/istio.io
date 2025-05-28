#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

# Make sure automatic sidecar injection is enabled
kubectl label namespace default istio-injection=enabled || true

# Deploy sleep sample and set up variable pointing to it
snip_before_you_begin_1
_wait_for_deployment default sleep
snip_before_you_begin_3

# Apply ServiceEntry for external workload and verify 301
snip_perform_tls_origination_with_an_egress_gateway_1
_wait_for_istio serviceentry default cnn
_verify_elided snip_perform_tls_origination_with_an_egress_gateway_2 "$snip_perform_tls_origination_with_an_egress_gateway_2_out"

# Create Gateway and DR to forward sidecar requests to egress gateway
snip_perform_tls_origination_with_an_egress_gateway_3
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-cnn

# Create VirtualService to direct traffic through gateway and deploy DR to originate Simple TLS
snip_perform_tls_origination_with_an_egress_gateway_4
_wait_for_istio virtualservice default direct-cnn-through-egress-gateway

# Verify HTTP request to external service returns 200
_verify_elided snip_perform_tls_origination_with_an_egress_gateway_5 "$snip_perform_tls_origination_with_an_egress_gateway_5_out"

# Verify that the request was routed through egressgateway
_verify_contains snip_perform_tls_origination_with_an_egress_gateway_6 "GET /politics HTTP/2"

# @cleanup
kubectl label namespace default istio-injection-
snip_cleanup_the_tls_origination_example_1
snip_cleanup_1
