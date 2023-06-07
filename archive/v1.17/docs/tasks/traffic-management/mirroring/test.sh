#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

# shellcheck disable=SC2155

set -e
set -u
set -o pipefail

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=default

kubectl label namespace default istio-injection- --overwrite

# create the httpbin service
snip_before_you_begin_3

# Configure the httpbin route before deploying the services to allow lots
#  of time for the config to be ready before the first request. If too soon,
#  it might send a request to v2, which will cuase the test to fail
#  _verify_not_contains snip_creating_a_default_routing_policy_5.
if [ "$GATEWAY_API" == "true" ]; then
    snip_creating_a_default_routing_policy_2
else
    snip_creating_a_default_routing_policy_1

    # wait for config
    _wait_for_istio virtualservice default httpbin
    _wait_for_istio destinationrule default httpbin
fi

# deploy the services
snip_before_you_begin_1
_wait_for_deployment default httpbin-v1

snip_before_you_begin_2
_wait_for_deployment default httpbin-v2

snip_before_you_begin_4
_wait_for_deployment default sleep

# wait some more for the route config to be applied to the sleep pod
sleep 30s # TODO proper wait for config update

send_request_and_get_v1_log() {
    _verify_contains snip_creating_a_default_routing_policy_3 "headers"
    out=$(snip_creating_a_default_routing_policy_4)
    echo "$out"
}
_verify_contains send_request_and_get_v1_log "GET /headers HTTP/1.1"

_verify_not_contains snip_creating_a_default_routing_policy_5 "GET /headers HTTP/1.1"

if [ "$GATEWAY_API" == "true" ]; then
    snip_mirroring_traffic_to_v2_2
else
    snip_mirroring_traffic_to_v2_1

    # wait for config
    _wait_for_istio virtualservice default httpbin
fi

# Set environment variables. TODO: why didn't the exports from snip_creating_a_default_routing_policy_3/4/5 take?
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})

send_request_and_get_v2_log() {
    _verify_contains snip_mirroring_traffic_to_v2_3 "headers"
    out=$(snip_mirroring_traffic_to_v2_5)
    echo "$out"
}
_verify_contains send_request_and_get_v2_log "GET /headers HTTP/1.1"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleaning_up_1
    snip_cleaning_up_3
fi
