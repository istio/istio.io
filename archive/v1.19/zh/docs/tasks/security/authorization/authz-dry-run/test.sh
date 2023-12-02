#!/usr/bin/env bash
# shellcheck disable=SC2154,SC2251

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

source "tests/util/addons.sh"

# @setup profile=default

# Install Prometheus and Zipkin
_deploy_and_wait_for_addons prometheus zipkin

# Install sleep and httpbin
snip_before_you_begin_1
_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep

# Enable RBAC debug logging on httpbin
_verify_contains snip_before_you_begin_2 "$snip_before_you_begin_2_out"

# Send request from sleep to httpbin
_verify_contains snip_before_you_begin_3 "$snip_before_you_begin_3_out"

# Create authorization policy in dry-run mode
snip_create_dryrun_policy_1
snip_create_dryrun_policy_2

# Send requests from sleep to httpbin
_verify_elided snip_create_dryrun_policy_3 "$snip_create_dryrun_policy_3_out"

# Verify Envoy logs for the dry-run result
function check_logs() {
  # Send more requests in case the log is not showing
  kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -s -o /dev/null -w "%{http_code}\n"
  snip_check_dryrun_result_in_proxy_log_1
}
_verify_contains check_logs "ns[foo]-policy[deny-path-headers]-rule[0]"

function query_prometheus() {
  # Send more requests in case the metric is not showing
  kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s
  curl -sg "http://localhost:9090/api/v1/query?query=$snip_check_dryrun_result_in_metric_using_prometheus_2" | jq '.data.result[0].value[1]'
}

# Start the Prometheus dashboard and verify the query result is non-zero
snip_check_dryrun_result_in_metric_using_prometheus_1 &
_verify_regex query_prometheus '"([1-9]|[1-9][0-9]+)"'
pgrep istioctl | xargs kill

function query_zipkin() {
  # Send more requests in case the trace is not showing
  kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/headers -H "X-B3-Sampled: 1" -s
  curl -s 'http://localhost:9411/zipkin/api/v2/traces?serviceName=httpbin.foo'
}

# Start the Zipkin dashboard and verify the trace result includes the dry-run policy name
snip_check_dryrun_result_in_tracing_using_zipkin_1 &
_verify_contains query_zipkin "ns[foo]-policy[deny-path-headers]-rule[0]"
pgrep istioctl | xargs kill

# @cleanup
_undeploy_addons prometheus zipkin
snip_clean_up_1
