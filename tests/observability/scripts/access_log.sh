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

source "${REPO_ROOT}/content/en/docs/tasks/observability/logs/access-log/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

# Install Istio with access logging enabled
_verify_elided snip_enable_envoys_access_logging_1 "$snip_enable_envoys_access_logging_1_out"

# Wait for istiod pod to be ready
_wait_for_deployment istio-system istiod

kubectl label namespace default istio-injection=enabled --overwrite

# Start the sleep sample
startup_sleep_sample
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')

# Start the httpbin sample
startup_httpbin_sample

# Make curl request to httpbin
#TODO _verify_elided snip_test_the_access_log_1 "$snip_test_the_access_log_1_out"
_verify_contains snip_test_the_access_log_1 "-=[ teapot ]=-"

# Check the logs
_verify_contains snip_test_the_access_log_2 "outbound|8000||httpbin.default.svc.cluster.local"
_verify_contains snip_test_the_access_log_3 "inbound|8000|http|httpbin.default.svc.cluster.local"
