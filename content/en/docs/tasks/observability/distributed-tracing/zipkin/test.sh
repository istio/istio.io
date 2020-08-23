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

# @setup profile=demo

## Setting up application
# Set to known setting of sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

# ZIPKIN_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/extras/zipkin.yaml"
kubectl apply -f "https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/extras/zipkin.yaml"
_wait_for_deployment istio-system zipkin

# Install Bookinfo application
startup_bookinfo_sample

# This shows up in many places. Should move to util? 
function send_productpage_requests() {
  _set_ingress_environment_variables
  local GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
  for _ in {1..250}; do
    curl -s "http://$GATEWAY_URL/productpage" > /dev/null
  done
}

snip_accessing_the_dashboard_1 &
send_productpage_requests

# Sometimes, traces may not be present in zipkin server. So it returns [] when
# queried. In this case, we should wait for some more time and try 
function get_and_verify_zipkin_trace() {
  local attempt=1
  local max_attempts=5
  local trace_present=0
  while [[ $attempt -le $max_attempts ]]; do
    local trace="$(curl -sS 'http://localhost:9411/zipkin/api/v2/traces?serviceName=productpage.default')"
    local trace_item="$(echo $trace | jq '.[0]')"
    if [[ $trace_item != "null" ]]; then
      trace_present=1
      echo "$trace" | python3 "content/en/docs/tasks/observability/distributed-tracing/zipkin/verify_traces.py"
      break
    fi
    sleep $(( attempt ** 2 ))
    attempt=$(( attempt + 1 )) 
  done
  
  if [[ $trace_present -eq 0 ]]; then
    echo "trace not present in zipkin server"
    exit 1
  fi
}

get_and_verify_zipkin_trace
pgrep istioctl | xargs kill

# @cleanup
set +e
cleanup_bookinfo_sample
pgrep istioctl | xargs kill

# Had to repeat again, as setup and cleanup are split into separate scripts
# and are invoked separately by istio.io docs test framework
kubectl delete -f "https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/extras/zipkin.yaml"
