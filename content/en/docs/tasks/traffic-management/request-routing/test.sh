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

source "tests/util/samples.sh"

# @setup profile=default

# helper functions
get_bookinfo_productpage() {
    sample_http_request "/productpage"
}
get_bookinfo_productpage_jason() {
    sample_http_request "/productpage" "jason"
}

kubectl label namespace default istio-injection=enabled --overwrite
startup_curl_sample # needed for sending test requests with curl

# launch the bookinfo app
startup_bookinfo_sample

# set default route rules
if [ "$GATEWAY_API" == "true" ]; then
    snip_route_to_version_1_2
    _verify_lines snip_route_to_version_1_5 "
    + message: Route was valid
    + reason: Accepted
    "
else
    snip_route_to_version_1_1

    # wait for rules to propagate
    _wait_for_resource virtualservice default productpage
    _wait_for_resource virtualservice default reviews
    _wait_for_resource virtualservice default ratings
    _wait_for_resource virtualservice default details

    # confirm route rules are set
    _verify_elided snip_route_to_version_1_3 "$snip_route_to_version_1_3_out"

    # check destination rules
    _verify_lines snip_route_to_version_1_4 "
    + productpage
    + reviews
    + ratings
    + details
    "
fi

# check that requests do not return ratings
_verify_not_contains get_bookinfo_productpage "glyphicon glyphicon-star"

# route traffic for user jason to reviews:v2
if [ "$GATEWAY_API" == "true" ]; then
    snip_route_based_on_user_identity_3
else
    snip_route_based_on_user_identity_1

    # wait for rules to propagate
    _wait_for_resource virtualservice default reviews

    # confirm route rules are set
    _verify_elided snip_route_based_on_user_identity_2 "$snip_route_based_on_user_identity_2_out"
fi

# check that requests from user jason return ratings and other requests do not
_verify_contains get_bookinfo_productpage_jason "glyphicon glyphicon-star"
_verify_not_contains get_bookinfo_productpage "glyphicon glyphicon-star"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
    snip_cleanup_1
    cleanup_bookinfo_sample
    cleanup_curl_sample
    kubectl label namespace default istio-injection-
fi
