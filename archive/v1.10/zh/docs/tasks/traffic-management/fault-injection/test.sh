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
startup_sleep_sample # needed for sending test requests with curl

# launch the bookinfo app
startup_bookinfo_sample

# set route rules
snip_before_you_begin_1

# inject the delay fault
snip_injecting_an_http_delay_fault_1

# confirm rules are set
_verify_elided snip_injecting_an_http_delay_fault_2 "$snip_injecting_an_http_delay_fault_2_out"

# wait for rules to propagate
_wait_for_istio virtualservice default productpage
_wait_for_istio virtualservice default reviews
_wait_for_istio virtualservice default ratings
_wait_for_istio virtualservice default details

# check that requests from user jason return error
_verify_contains get_bookinfo_productpage_jason "$snip_testing_the_delay_configuration_1"

# inject the abort fault
snip_injecting_an_http_abort_fault_1

# wait for rules to propagate
_wait_for_istio virtualservice default ratings

# confirm rules are set
_verify_elided snip_injecting_an_http_abort_fault_2 "$snip_injecting_an_http_abort_fault_2_out"

# check that requests from user jason return error and other request do not
_verify_contains get_bookinfo_productpage_jason "Ratings service is currently unavailable"
_verify_not_contains get_bookinfo_productpage "Ratings service is currently unavailable"

# @cleanup
snip_cleanup_1
cleanup_bookinfo_sample
cleanup_sleep_sample
