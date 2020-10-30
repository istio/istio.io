#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

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

# @setup profile=demo

# Install Istio with access logging enabled

#_verify_elided snip_enable_envoys_access_logging_2 "$snip_enable_envoys_access_logging_2_out"
# TODO: verify install and wait for output ??? Don't call function multiple times.
#snip_enable_envoys_access_logging_2
#_wait_for_deployment istio-system istiod
# TODO: above snip does not seem to be needed, access logging is already enabled by default?
# TODO: also, running the above snip causes failure in following test (egress/egress-gateway-tls-origination/tls_test.sh)

kubectl label namespace default istio-injection=enabled --overwrite

# Start the sleep sample
startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

# Start the httpbin sample
startup_httpbin_sample

# Make curl request to httpbin
_verify_elided snip_test_the_access_log_1 "$snip_test_the_access_log_1_out"

# Check the logs
_verify_contains snip_test_the_access_log_2 "outbound|8000||httpbin.default.svc.cluster.local"
_verify_contains snip_test_the_access_log_3 "outbound_.8000_._.httpbin.default.svc.cluster.local"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_1
#snip_disable_envoys_access_logging_1
#_wait_for_deployment istio-system istiod
