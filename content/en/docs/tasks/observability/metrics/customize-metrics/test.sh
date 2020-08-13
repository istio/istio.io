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

# Set to known setting of sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

# Install Bookinfo application
startup_bookinfo_sample

# Find and get the stats filter file and tweak metrics configuration
_verify_like snip_enable_custom_metrics_1 "$snip_enable_custom_metrics_1_out"
snip_enable_custom_metrics_2

echo "patch stats-filter configuration to add custom metrics"
stats_filter_config="stats-filter-1.6.yaml"
script_path="content/en/docs/tasks/observability/metrics/customize-metrics"
python3 "$script_path"/patch_stats_filter_config.py $stats_filter_config $stats_filter_config

# After editing the filter apply changes and wait for propagation
snip_enable_custom_metrics_5
kubectl -n istio-system get envoyfilter stats-filter-1.6 -o yaml
_wait_for_istio envoyfilter istio-system stats-filter-1.6

# Fire some requests at productpage so that we will have some requests
_set_ingress_environment_variables
gateway_url=$INGRESS_HOST:$INGRESS_PORT
for i in {1..100}; do
  curl http://$gateway_url/productpage > /dev/null
done

# Finally verify results
# I cannot use the command in the snippet because it has pod-name, but I need an actual pod
productpage_pod=$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')
metric_count=$(kubectl exec $productpage_pod -c istio-proxy -- curl 'localhost:15000/stats/prometheus' | grep 'istio_requests_total' | wc -l)
echo "obtained count: $metric_count"
__cmp_at_least $metric_count 1

# @cleanup
set +e # ignore cleanup errors
cleanup_bookinfo_sample