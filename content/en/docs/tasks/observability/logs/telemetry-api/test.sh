#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2086

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

# @setup profile=minimal

snip_install_loki

_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system opentelemetry-collector

port_forward_loki() {
  kubectl wait pods -n istio-system -l app.kubernetes.io/name=loki --for condition=Ready --timeout=90s
  kubectl port-forward -n istio-system svc/loki 3100:3100 &
}

port_forward_loki

startup_sleep_sample
startup_httpbin_sample

function send_httpbin_requests() {
  local request_path="$1"
  for _ in {1..10}; do
    kubectl exec deploy/sleep -- curl -sS "http://httpbin:8000/$request_path" > /dev/null
  done
}

function count_by_pod() {
  local namespace="$1"
  local name="$2"
  curl -G -s 'http://localhost:3100/loki/api/v1/query_range' --data-urlencode "query={namespace=\"$namespace\", pod=\"$name\"}" | jq '.data.result[0].values | length'
}

count_sleep_pod() {
  local pod=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
  count_by_pod default $pod
}

count_httpbin_pod() {
  local pod=$(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name})
  count_by_pod default $pod
}

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "0"
_verify_same count_httpbin_pod "0"

# enable access log via Telemetry API
snip_get_started_with_telemetry_api_1
_wait_for_istio telemetry istio-system mesh-logging-default

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "10"
_verify_same count_httpbin_pod "10"

# disable access log for sleep pod
snip_get_started_with_telemetry_api_2
_wait_for_istio telemetry default disable-sleep-logging

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "10"
_verify_same count_httpbin_pod "20"

# disable httpbin
snip_get_started_with_telemetry_api_3
_wait_for_istio telemetry default disable-httpbin-logging

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "20"
_verify_same count_httpbin_pod "20"

# filter sleep logs
kubectl delete telemetry --all -n istio-sytem
snip_get_started_with_telemetry_api_4
_wait_for_istio telemetry default filter-sleep-logging

send_httpbin_requests "status/200"
_verify_same count_sleep_pod "20"

send_httpbin_requests "status/500"
_verify_same count_sleep_pod "20"

# @cleanup
cleanup_sleep_sample
cleanup_httpbin_sample

snip_cleanup_1
snip_cleanup_2
snip_cleanup_3

kubectl delete ns istio-system
