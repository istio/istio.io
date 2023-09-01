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

# @setup profile=none

snip_install_loki

_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system opentelemetry-collector

expose_loki() {
cat <<EOF | kubectl apply -n istio-system -f -
apiVersion: v1
kind: Service
metadata:
  name: loki-elb
  labels:
    app.kubernetes.io/name: loki
    app.kubernetes.io/instance: loki
    app.kubernetes.io/version: "2.7.3"
spec:
  type: LoadBalancer
  ports:
    - name: http-metrics
      port: 3100
      targetPort: http-metrics
      protocol: TCP
    - name: grpc
      port: 9095
      targetPort: grpc
      protocol: TCP
  selector:
    app.kubernetes.io/name: loki
    app.kubernetes.io/instance: loki
    app.kubernetes.io/component: single-binary
EOF
}

expose_loki
kubectl wait pods -n istio-system -l app.kubernetes.io/name=loki --for condition=Ready --timeout=90s

kubectl label namespace default istio-injection=enabled --overwrite

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
  local loki_address=$(kubectl get svc loki-elb -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  curl -G -s "http://$loki_address:3100/loki/api/v1/query_range" --data-urlencode "query={namespace=\"$namespace\", pod=\"$name\"}" | jq '.data.result[0].values | length'
}

count_sleep_pod() {
  local pod=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
  count_by_pod default $pod
}

count_httpbin_pod() {
  local pod=$(kubectl get pod -l app=httpbin -o jsonpath={.items..metadata.name})
  count_by_pod default $pod
}

rollout_restart_pods() {
  kubectl rollout restart deploy/sleep
  kubectl rollout restart deploy/httpbin
  _wait_for_deployment default sleep
  _wait_for_deployment default httpbin
}

send_httpbin_requests "status/200"

# no logs are sent to loki
_verify_same count_sleep_pod "0"
_verify_same count_httpbin_pod "0"

# enable access log via Telemetry API
snip_get_started_with_telemetry_api_1
rollout_restart_pods

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "10"
_verify_same count_httpbin_pod "10"

# disable access log for sleep pod
snip_get_started_with_telemetry_api_2
rollout_restart_pods

send_httpbin_requests "status/200"

# sleep pod logs are not sent to loki
_verify_same count_sleep_pod "0"
_verify_same count_httpbin_pod "10"

# disable httpbin
snip_get_started_with_telemetry_api_3
rollout_restart_pods

send_httpbin_requests "status/200"

_verify_same count_sleep_pod "0"
# httpbin pod logs are not sent to loki
_verify_same count_httpbin_pod "0"

# filter sleep logs
kubectl delete telemetry --all -n default
snip_get_started_with_telemetry_api_4
rollout_restart_pods

# only 5xx logs are sent to loki
send_httpbin_requests "status/200"
_verify_same count_sleep_pod "0"

send_httpbin_requests "status/500"
_verify_same count_sleep_pod "10"

# @cleanup
cleanup_sleep_sample
cleanup_httpbin_sample

snip_cleanup_1
snip_cleanup_2
snip_cleanup_3

kubectl delete ns istio-system
