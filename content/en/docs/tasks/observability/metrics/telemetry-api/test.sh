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

# @setup profile=none
echo "$snip_before_you_begin_1" | istioctl install -y -f -

## Setting up application
# Set to known setting of sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

# remove grpc_response_status taq from REQUEST_COUNT metrics
ech "$snip_override_metrics_1" | kubectl apply -f -

# Install Bookinfo application
startup_bookinfo_sample

## Before patching configuration
# First make sure that the metric dimensions we are going to add as
# part of this task don't exist yet
function send_productpage_requests() {
  _set_ingress_environment_variables
  local GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
  for _ in {1..100}; do
    snip_verify_the_results_1 > /dev/null
  done
}

send_productpage_requests
_verify_not_contains snip_verify_the_results_2 "grpc_response_status"

# @cleanup
cleanup_bookinfo_sample

istioctl uninstall --purge -y
kubectl delete ns istio-system
