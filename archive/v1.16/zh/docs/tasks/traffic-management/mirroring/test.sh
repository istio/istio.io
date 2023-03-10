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

snip_before_you_begin_1

snip_before_you_begin_2

snip_before_you_begin_3

snip_before_you_begin_4

# wait for deployments
_wait_for_deployment default httpbin-v1
_wait_for_deployment default httpbin-v2
_wait_for_deployment default sleep

if [ "$GATEWAY_API" == "true" ]; then
    snip_creating_a_default_routing_policy_2
    sleep 30s # TODO proper wait
else
    snip_creating_a_default_routing_policy_1

    # wait for config
    _wait_for_istio virtualservice default httpbin
    _wait_for_istio destinationrule default httpbin
fi

_verify_contains snip_creating_a_default_routing_policy_3 "headers"

_verify_contains snip_creating_a_default_routing_policy_4 "GET /headers HTTP/1.1"

_verify_not_contains snip_creating_a_default_routing_policy_5 "GET /headers HTTP/1.1"

if [ "$GATEWAY_API" == "true" ]; then
    snip_mirroring_traffic_to_v2_2
    sleep 30s # TODO proper wait
else
    snip_mirroring_traffic_to_v2_1

    # wait for config
    _wait_for_istio virtualservice default httpbin
fi

# Set environment variables. TODO: why didn't the exports from snip_creating_a_default_routing_policy_2/3/4 take?
export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
export V1_POD=$(kubectl get pod -l app=httpbin,version=v1 -o jsonpath={.items..metadata.name})
export V2_POD=$(kubectl get pod -l app=httpbin,version=v2 -o jsonpath={.items..metadata.name})

snip_mirroring_traffic_to_v2_3

# TODO: This should check for 2 lines with the GET request
_verify_contains snip_mirroring_traffic_to_v2_4 "GET /headers HTTP/1.1"

_verify_contains snip_mirroring_traffic_to_v2_5 "GET /headers HTTP/1.1"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleaning_up_1
    snip_cleaning_up_3
fi
