#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2034,SC2154

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

source "tests/util/samples.sh"

GATEWAY_API="${GATEWAY_API:-false}"

# @setup profile=default

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

if [ "$GATEWAY_API" == "true" ]; then
    # create the gateway and routes
    snip_configuring_ingress_using_a_gateway_3
    _wait_for_gateway default httpbin-gateway
    snip_configuring_ingress_using_a_gateway_4
    snip_configuring_ingress_using_a_gateway_5

    # set INGRESS_HOST and INGRESS_PORT environment variables
    snip_determining_the_ingress_ip_and_ports_7
else
    # create the gateway and routes
    snip_configuring_ingress_using_a_gateway_1
    snip_configuring_ingress_using_a_gateway_2

    # wait for rules to propagate
    _wait_for_istio gateway default httpbin-gateway
    _wait_for_istio virtualservice default httpbin

    # check for external load balancer
    snip_determining_the_ingress_ip_and_ports_2
    _verify_like snip_determining_the_ingress_ip_and_ports_4 "$snip_determining_the_ingress_ip_and_ports_4_out"

    # set INGRESS_HOST, INGRESS_PORT, SECURE_INGRESS_PORT, and TCP_INGRESS_PORT environment variables
    snip_determining_the_ingress_ip_and_ports_5
fi

# access the httpbin service
_verify_elided snip_accessing_ingress_services_1 "$snip_accessing_ingress_services_1_out"

# access the httpbin service
_verify_elided snip_accessing_ingress_services_2 "$snip_accessing_ingress_services_2_out"

if [ "$GATEWAY_API" == "true" ]; then
    # configure for web browser
    snip_accessing_ingress_services_using_a_browser_2
else
    # configure for web browser
    snip_accessing_ingress_services_using_a_browser_1

    # wait for rules to propagate
    _wait_for_istio gateway default httpbin-gateway
    _wait_for_istio virtualservice default httpbin
fi

# helper function
curl_httpbin_headers() {
    curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

# access httpbin without host header
_verify_contains curl_httpbin_headers "HTTP/1.1 200 OK"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_1
fi
