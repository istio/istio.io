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

# Prometheus living inside cluster is not accessible from outside.
# So we need some sort of port redirection mechanism
istioctl dashboard prometheus &

# Fire a couple of requests
_set_ingress_environment_variables
export INGRESS_URL=$INGRESS_HOST:$INGRESS_PORT
for i in {1..50}; do
    curl -s http://$INGRESS_URL/productpage > /dev/null
done

# Now check Prometheus dashboard for the metric. It should be present
function query_prometheus() {
    curl -sg 'http://localhost:9090/api/v1/query?query=istio_requests_total' | jq .data.result[0].metric.__name__
}

_verify_contains query_prometheus '"istio_requests_total"'

# @cleanup
set +e
killall istioctl
kubectl delete -f samples/addons/prometheus.yaml -n istio-system
cleanup_bookinfo_sample