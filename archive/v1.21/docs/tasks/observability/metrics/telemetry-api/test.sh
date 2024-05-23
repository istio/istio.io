#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2034

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

## Setting up application
# Set to known setting of sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

# Install Bookinfo application
startup_bookinfo_sample

## Before patching configuration
# First make sure that the metric dimensions we are going to add as
# part of this task don't exist yet
function send_productpage_requests() {
  _set_ingress_environment_variables
  local GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
  for _ in {1..10}; do
    snip_verify_the_results_1 > /dev/null
  done
}

function restart_productpage() {
  kubectl rollout restart deployment productpage-v1
  kubectl rollout restart deployment details-v1
  kubectl rollout restart deployment ratings-v1
  kubectl rollout restart deployment reviews-v1
  kubectl rollout restart deployment reviews-v2
  kubectl rollout restart deployment reviews-v3
  _wait_for_deployment default productpage-v1
  _wait_for_deployment default details-v1
  _wait_for_deployment default ratings-v1
  _wait_for_deployment default reviews-v1
  _wait_for_deployment default reviews-v2
  _wait_for_deployment default reviews-v3
}

function cleanup_telemetry_api() {
  kubectl delete telemetry --all -nistio-system
}

echo 'remvoe grpc_response_status'
echo "$snip_override_metrics_1" | kubectl apply -f -
send_productpage_requests
_verify_not_contains snip_verify_the_results_2 "grpc_response_status"
cleanup_telemetry_api

echo 'custom tags metrics'
echo "$snip_override_metrics_2" | kubectl apply -f -
restart_productpage
send_productpage_requests
_verify_contains snip_verify_the_results_2 "destination_x"
cleanup_telemetry_api

echo 'remove all metrics'
echo "$snip_disable_metrics_1" | kubectl apply -f -
restart_productpage
send_productpage_requests
_verify_same snip_verify_the_results_2 ""
_verify_same snip_verify_the_results_3 ""
cleanup_telemetry_api

echo 'remove request count'
echo "$snip_disable_metrics_2" | kubectl apply -f -
restart_productpage
send_productpage_requests
_verify_same snip_verify_the_results_2 ""
_verify_same snip_verify_the_results_3 ""
cleanup_telemetry_api

echo 'remove client metrics'
echo "$snip_disable_metrics_3" | kubectl apply -f -
restart_productpage
send_productpage_requests
_verify_same snip_verify_the_results_2 ""
_verify_contains snip_verify_the_results_3 "response_code"
cleanup_telemetry_api

echo 'remove server metrics'
echo "$snip_disable_metrics_4" | kubectl apply -f -
restart_productpage
send_productpage_requests
_verify_contains snip_verify_the_results_2 "response_code"
_verify_same snip_verify_the_results_3 ""
cleanup_telemetry_api

# @cleanup
cleanup_bookinfo_sample
