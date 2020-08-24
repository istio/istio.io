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

# Although test says, take a look at traces, we don't have to do that in this task
# as it is covered by an integration test in istio/istio
function access_zipkin_with_portforward() {
  local zipkin_url='http://localhost:9411/zipkin/api/v2/traces?serviceName=productpage.default'
  curl -s -o /dev/null -w "%{http_code}" "$zipkin_url"
}

_verify_same access_zipkin_with_portforward "200"
pgrep istioctl | xargs kill

# @cleanup
set +e
cleanup_bookinfo_sample
pgrep istioctl | xargs kill

# Had to repeat again, as setup and cleanup are split into separate scripts
# and are invoked separately by istio.io docs test framework
kubectl delete -f "https://raw.githubusercontent.com/istio/istio/release-1.7/samples/addons/extras/zipkin.yaml"
