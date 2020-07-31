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

# Deploy sleep sample and set up variable pointing to it
set +e
kubectl delete pods -l app=sleep --force
set -e
snip_before_you_begin_2
_wait_for_deployment default sleep
snip_before_you_begin_3

# Apply ServiceEntry for external worklad and verify 200
snip_egress_gateway_for_https_traffic_1
_wait_for_istio serviceentry default cnn
_verify_elided snip_egress_gateway_for_https_traffic_2 "$snip_egress_gateway_for_https_traffic_2_out"

# Create Gateway, DR and VS to forwards requests to egress gateway
snip_egress_gateway_for_https_traffic_3
_wait_for_istio gateway default istio-egressgateway
_wait_for_istio destinationrule default egressgateway-for-cnn
_wait_for_istio virtualservice default direct-cnn-through-egress-gateway

# Verify HTTP request to external service returns 200
_verify_elided snip_egress_gateway_for_https_traffic_4 "$snip_egress_gateway_for_https_traffic_4_out"

# Verify that request was routed through egress gateway
_verify_contains snip_egress_gateway_for_https_traffic_5 '\"\- \- \-\"'


# @cleanup
set +e # ignore cleanup errors
snip_cleanup_https_gateway_1
