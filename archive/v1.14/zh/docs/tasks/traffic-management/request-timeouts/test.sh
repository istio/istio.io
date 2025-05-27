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

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"

# @setup profile=default

kubectl label namespace default istio-injection=enabled --overwrite
startup_sleep_sample # needed for sending test requests with curl

# launch the bookinfo app
startup_bookinfo_sample

# config route all requests to v1
snip_before_you_begin_1

# config route requests to v2 of the reviews service
snip_request_timeouts_1

# config a 2 second delay to calls to the ratings service
snip_request_timeouts_2

# wait for rules to propagate
_wait_for_istio virtualservice default productpage
_wait_for_istio virtualservice default reviews
_wait_for_istio virtualservice default ratings
_wait_for_istio virtualservice default details

get_productpage() {
    out=$(sample_http_request "/productpage")
    echo "$out"
}

# verify 2s delay with ratings stars displayed
# TODO: should we time this request to confirm it takes ~2s?
_verify_contains get_productpage "glyphicon glyphicon-star"

# config a half second request timeout for calls to the reviews service
snip_request_timeouts_3

_wait_for_istio virtualservice default reviews

# verify product reviews are unavailable
_verify_contains get_productpage "Sorry, product reviews are currently unavailable for this book."

# @cleanup
snip_cleanup_1
cleanup_bookinfo_sample
cleanup_sleep_sample
