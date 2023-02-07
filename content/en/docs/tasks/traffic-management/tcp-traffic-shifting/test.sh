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

set -e
set -u
set -o pipefail

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=demo

# create a new namespace for testing purposes
snip_set_up_the_test_environment_1

# start the sleep sample
snip_set_up_the_test_environment_2

# start the v1 and v2 versions of the echo service
snip_set_up_the_test_environment_3

# wait for deployments to start
_wait_for_deployment istio-io-tcp-traffic-shifting tcp-echo-v1
_wait_for_deployment istio-io-tcp-traffic-shifting tcp-echo-v2
_wait_for_deployment istio-io-tcp-traffic-shifting sleep

# Route all traffic to echo v1
if [ "$GATEWAY_API" == "true" ]; then
    snip_apply_weightbased_tcp_routing_2
    _wait_for_gateway istio-io-tcp-traffic-shifting tcp-echo-gateway
    snip_apply_weightbased_tcp_routing_3

    # Make sure the nc command will work and not fail the cluster
    # More info: https://github.com/istio/istio.io/pull/12544
    # TODO proper wait for things being ready
    # it seems we had 8 or so exits during the run of 20 so need 8 plus seconds
    sleep 20s
else
    snip_apply_weightbased_tcp_routing_1

    # wait for rules to propagate
    _wait_for_istio gateway istio-io-tcp-traffic-shifting tcp-echo-gateway
    _wait_for_istio destinationrule istio-io-tcp-traffic-shifting tcp-echo-destination
    _wait_for_istio virtualservice istio-io-tcp-traffic-shifting tcp-echo

    # export the INGRESS_ environment variables
    _set_ingress_environment_variables
fi

_verify_lines snip_apply_weightbased_tcp_routing_4 "
+ one
- two
"

if [ "$GATEWAY_API" == "true" ]; then
    snip_apply_weightbased_tcp_routing_6
    _verify_elided snip_apply_weightbased_tcp_routing_8 "$snip_apply_weightbased_tcp_routing_8_out"
else
    snip_apply_weightbased_tcp_routing_5

    # wait for rules to propagate
    _wait_for_istio virtualservice istio-io-tcp-traffic-shifting tcp-echo

    _verify_elided snip_apply_weightbased_tcp_routing_7 "$snip_apply_weightbased_tcp_routing_7_out"
fi

_verify_lines snip_apply_weightbased_tcp_routing_9 "
+ one
+ two
"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_1
    snip_cleanup_3
fi
