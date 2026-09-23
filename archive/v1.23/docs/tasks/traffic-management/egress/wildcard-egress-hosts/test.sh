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

# @setup profile=none

set -e
set -u
set -o pipefail

GATEWAY_API="${GATEWAY_API:-false}"

if [ "$GATEWAY_API" == "true" ]; then
    snip_before_you_begin_2
else
    echo y | snip_before_you_begin_1
fi
_wait_for_deployment istio-system istiod

kubectl label namespace default istio-injection=enabled --overwrite

snip_before_you_begin_3
_wait_for_deployment default sleep
snip_before_you_begin_5

confirm_blocking() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -I https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -I https://edition.cnn.com | grep "HTTP/"
}
_verify_contains confirm_blocking "command terminated with exit code 35"

snip_configure_direct_traffic_to_a_wildcard_host_1
_wait_for_istio serviceentry default wikipedia

_verify_same snip_configure_direct_traffic_to_a_wildcard_host_2 "$snip_configure_direct_traffic_to_a_wildcard_host_2_out"

snip_cleanup_direct_traffic_to_a_wildcard_host_1

if [ "$GATEWAY_API" == "true" ]; then
    snip_configure_egress_gateway_traffic_to_a_wildcard_host_2
    kubectl wait --for=condition=programmed gtw wikipedia-egress-gateway
else
    snip_configure_egress_gateway_traffic_to_a_wildcard_host_1
    _wait_for_istio gateway default istio-egressgateway
    _wait_for_istio destinationrule default egressgateway-for-wikipedia
    _wait_for_istio virtualservice default direct-wikipedia-through-egress-gateway
fi

snip_configure_egress_gateway_traffic_to_a_wildcard_host_3
_wait_for_istio serviceentry default www-wikipedia

_verify_same snip_configure_egress_gateway_traffic_to_a_wildcard_host_4 "$snip_configure_egress_gateway_traffic_to_a_wildcard_host_4_out"

if [ "$GATEWAY_API" == "true" ]; then
    _verify_contains snip_configure_egress_gateway_traffic_to_a_wildcard_host_6 "outbound|443||www.wikipedia.org"
    snip_cleanup_egress_gateway_traffic_to_a_wildcard_host_2
else
    _verify_contains snip_configure_egress_gateway_traffic_to_a_wildcard_host_5 "outbound|443||www.wikipedia.org"
    snip_cleanup_egress_gateway_traffic_to_a_wildcard_host_1
fi

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_direct_traffic_to_a_wildcard_host_1
    snip_cleanup_egress_gateway_traffic_to_a_wildcard_host_1
    snip_cleanup_1
    snip_cleanup_2
    kubectl delete ns istio-system
    kubectl label namespace default istio-injection-
fi
