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
  gateway_url=$INGRESS_HOST:$INGRESS_PORT
  for i in {1..100}; do
    curl -s http://$gateway_url/productpage > /dev/null
  done
}

function check_sidecar_metrics() {
  productpage_pod=$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')
  kubectl exec $productpage_pod -c istio-proxy -- curl -s 'localhost:15000/stats/prometheus' | grep 'istio_requests_total'
}

send_productpage_requests
_verify_not_contains check_sidecar_metrics "destination_port"
_verify_not_contains check_sidecar_metrics "request_host"

## Patching configuration
# Find and get the stats filter file and tweak metrics configuration
filter_name="stats-filter-1.7"
_verify_like snip_enable_custom_metrics_1 "$snip_enable_custom_metrics_1_out"
kubectl -n istio-system get envoyfilter $filter_name -o yaml > $filter_name.yaml

echo "patch stats-filter configuration to add custom metrics"
stats_filter_config="$filter_name.yaml"
script_path="content/en/docs/tasks/observability/metrics/customize-metrics"
python3 "$script_path"/patch_stats_filter_config.py $stats_filter_config $stats_filter_config

# After editing the filter apply changes and wait for propagation
kubectl -n istio-system apply -f $filter_name.yaml
kubectl -n istio-system get envoyfilter $filter_name -o yaml
_wait_for_istio envoyfilter istio-system $filter_name

## Verify if patching works correctly
send_productpage_requests
_verify_contains check_sidecar_metrics "destination_port"
_verify_contains check_sidecar_metrics "request_host"

# @cleanup
set +e # ignore cleanup errors
cleanup_bookinfo_sample