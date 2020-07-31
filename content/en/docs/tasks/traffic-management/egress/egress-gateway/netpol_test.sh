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

# Enable access logging
#istioctl install --set profile=demo --set meshConfig.accessLogFile="/dev/stdout"
#_wait_for_deployment istio-system istiod
# TODO: above command is not needed, since access logging seems to be enabled by default.
# TODO: Also, running "istioctl install" causes the test to fail?????

# Apply ServiceEntry, Gateway, DR and VS for external traffic to be routed through egress gateway
snip_egress_gateway_for_https_traffic_1
_wait_for_istio serviceentry default cnn
snip_egress_gateway_for_https_traffic_3
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-cnn
_wait_for_istio virtualservice default direct-cnn-through-egress-gateway

# Deploy app to external namespace
snip_apply_kubernetes_network_policies_1
snip_apply_kubernetes_network_policies_2
_wait_for_deployment test-egress sleep
_verify_contains snip_apply_kubernetes_network_policies_3 "1\/1"

# Verify request to external workload returns 200
_verify_elided snip_apply_kubernetes_network_policies_4 "$snip_apply_kubernetes_network_policies_4_out"

# Label namespaces
snip_apply_kubernetes_network_policies_5
snip_apply_kubernetes_network_policies_6

# Create NetworkPolicy and verify traffic is blocked
snip_apply_kubernetes_network_policies_7
_verify_failure snip_apply_kubernetes_network_policies_8

# label external ns for injection and redeploy app
snip_apply_kubernetes_network_policies_9
snip_apply_kubernetes_network_policies_10
_wait_for_deployment test-egress sleep
_verify_same snip_apply_kubernetes_network_policies_11 "$snip_apply_kubernetes_network_policies_11_out"

# Create DR for external worklaod in external ns
snip_apply_kubernetes_network_policies_12
_wait_for_istio destinationrule test-egress egressgateway-for-cnn

# Verify request to external service returns 200
_verify_contains snip_apply_kubernetes_network_policies_13 "$snip_apply_kubernetes_network_policies_13_out"

# Verify traffic goes through egress gateway
_verify_contains snip_apply_kubernetes_network_policies_14 '\"\- \- \-\"'

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_network_policies_1
snip_cleanup_https_gateway_1