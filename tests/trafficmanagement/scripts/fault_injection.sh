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

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/fault-injection/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

kubectl label namespace default istio-injection=enabled --overwrite
startup_sleep_sample # needed for sending test requests with curl

# launch the bookinfo app
startup_bookinfo_sample

# set route rules
snip_before_you_begin_1

# inject the delay fault
snip_injecting_an_http_delay_fault_1

# wait for rules to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

# confirm rules are set
out=$(snip_injecting_an_http_delay_fault_2 2>&1)
_verify_elided "$out" "$snip_injecting_an_http_delay_fault_2_out" "snip_injecting_an_http_delay_fault_2"

# check that requests from user jason return error
out=$(sample_get_request "/productpage" "jason")
_verify_contains "$out" "$snip_testing_the_delay_configuration_1" "snip_testing_the_delay_configuration_1"

# inject the abort fault
snip_injecting_an_http_abort_fault_1

# wait for rules to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

# confirm rules are set
out=$(snip_injecting_an_http_abort_fault_2 2>&1)
_verify_elided "$out" "$snip_injecting_an_http_abort_fault_2_out" "snip_injecting_an_http_abort_fault_2"

# check that requests from user jason return error and other request do not
out=$(sample_get_request "/productpage" "jason")
_verify_contains "$out" "Ratings service is currently unavailable" "request_ratings_response_jason"
out=$(sample_get_request "/productpage")
_verify_not_contains "$out" "Ratings service is currently unavailable" "request_ratings_response_others"
