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
kubectl label namespace default istio-injection=enabled --overwrite

# Install Bookinfo sample
startup_bookinfo_sample

# Install Prometheus
kubectl apply -f samples/addons/prometheus.yaml -n istio-system
_wait_for_deployment istio-system prometheus

_verify_like snip_querying_istio_metrics_1 "$snip_querying_istio_metrics_1_out"

# Fire a couple of requests
_set_ingress_environment_variables
export GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
for _ in {1..50}; do
    snip_querying_istio_metrics_2 > /dev/null
done

function query_prometheus() {
    local prometheus_api_root="localhost:9090/api/v1"
    local encoded_query=$(_urlencode "$1")
    curl -sg -m 3.0 "http://$prometheus_api_root/query?query=$encoded_query"
}

function query_total_requests() {
    query_prometheus "$snip_querying_istio_metrics_4" | jq '.data.result[0].metric.__name__'
}

function query_requests_to_productpage() {
    query_prometheus "$snip_querying_istio_metrics_5" | jq '.data.result[0].metric.destination_service'
}

function query_requests_to_reviews_v3() {
    query_prometheus "$snip_querying_istio_metrics_6" | jq '.data.result[0].metric.destination_service,.data.result[0].metric.destination_version'
}

function query_rate_of_requests_to_productpage_5m() {
    query_prometheus "$snip_querying_istio_metrics_7" | jq '.data.result[0].metric.destination_service'
}

# Prometheus living inside cluster is not accessible from outside.
# So we need some sort of port forwarding mechanism
snip_querying_istio_metrics_3 &

_verify_contains query_total_requests '"istio_requests_total"'
_verify_contains query_requests_to_productpage '"productpage.default.svc.cluster.local"'
_verify_contains query_requests_to_reviews_v3 '"reviews.default.svc.cluster.local"'
_verify_contains query_requests_to_reviews_v3 '"v3"'
_verify_contains query_rate_of_requests_to_productpage_5m '"productpage.default.svc.cluster.local"'
pgrep istioctl | xargs kill

# @cleanup
set +e
pgrep istioctl | xargs kill
kubectl delete -f samples/addons/prometheus.yaml -n istio-system
cleanup_bookinfo_sample