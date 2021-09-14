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

# @setup profile=default

kubectl label namespace default istio-injection=enabled --overwrite

# start the httpbin sample
startup_httpbin_sample

# check for external load balancer
CMP_MATCH_IP_PENDING=true # TODO(https://github.com/istio/istio.io/issues/8353)
_verify_like snip_determining_the_ingress_ip_and_ports_1 "$snip_determining_the_ingress_ip_and_ports_1_out"
unset CMP_MATCH_IP_PENDING

# set INGRESS_HOST, INGRESS_PORT, SECURE_INGRESS_PORT, and TCP_INGRESS_PORT environment variables
if [[ "$out" != *"<none>"* && "$out" != *"<pending>"* ]]; then
    # external load balancer
    snip_determining_the_ingress_ip_and_ports_2
else
    # node port
    snip_determining_the_ingress_ip_and_ports_4
    snip_determining_the_ingress_ip_and_ports_10
fi

# create the gateway and routes
snip_configuring_ingress_using_an_istio_gateway_1
snip_configuring_ingress_using_an_istio_gateway_2

# wait for rules to propagate
_wait_for_istio gateway default httpbin-gateway
_wait_for_istio virtualservice default httpbin

# access the httpbin service
_verify_elided snip_configuring_ingress_using_an_istio_gateway_3 "$snip_configuring_ingress_using_an_istio_gateway_3_out"

# access the httpbin service
_verify_elided snip_configuring_ingress_using_an_istio_gateway_4 "$snip_configuring_ingress_using_an_istio_gateway_4_out"

# configure route based on JWT claims
snip_configuring_ingress_routing_based_on_jwt_claims_1
snip_configuring_ingress_routing_based_on_jwt_claims_2

# wait for rules to propagate
_wait_for_istio requestauthentication istio-system ingress-jwt
_wait_for_istio virtualservice default httpbin

# validate without JWT
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_3 "snip_configuring_ingress_routing_based_on_jwt_claims_3_out"

# validate with invalid JWT
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_4 "snip_configuring_ingress_routing_based_on_jwt_claims_4_out"

# Pull the Istio branch from the docs configuration file.
ISTIO_BRANCH=$(yq r "${REPO_ROOT}"/data/args.yml 'source_branch_name')
export TOKEN_GROUP
export TOKEN_NO_GROUP

# validate with valid and matched JWT
TOKEN_GROUP_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/groups-scope.jwt"
TOKEN_GROUP=$(curl "${TOKEN_GROUP_URL}" -s)
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_5 "snip_configuring_ingress_routing_based_on_jwt_claims_5_out"
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_6 "snip_configuring_ingress_routing_based_on_jwt_claims_6_out"

# validate with valid but unmatched JWT
TOKEN_NO_GROUP_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/demo.jwt"
TOKEN_NO_GROUP=$(curl "${TOKEN_NO_GROUP_URL}" -s)
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_7 "snip_configuring_ingress_routing_based_on_jwt_claims_7_out"
_verify_elided snip_configuring_ingress_routing_based_on_jwt_claims_8 "snip_configuring_ingress_routing_based_on_jwt_claims_8_out"

# configure for web browser
snip_accessing_ingress_services_using_a_browser_1

# wait for rules to propagate
_wait_for_istio gateway default httpbin-gateway
_wait_for_istio virtualservice default httpbin

# helper function
curl_httpbin_headers() {
    curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

# access httpbin without host header
_verify_contains curl_httpbin_headers "HTTP/1.1 200 OK"

# @cleanup
snip_cleanup_1
