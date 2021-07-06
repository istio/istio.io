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

# Install Bookinfo sample
startup_bookinfo_sample  # from tests/util/samples.sh

# Install Prometheus
kubectl apply -f samples/addons/prometheus.yaml -n istio-system
_wait_for_deployment istio-system prometheus

# Setup bookinfo to use MongoDB
# Install Ratings v2
_verify_same snip_collecting_new_telemetry_data_1 "$snip_collecting_new_telemetry_data_1_out"

# Install the MongoDB service
_verify_same snip_collecting_new_telemetry_data_3 "$snip_collecting_new_telemetry_data_3_out"

# Apply the destination rules
snip_collecting_new_telemetry_data_5
_wait_for_istio destinationrule default ratings
_wait_for_istio destinationrule default reviews

# Create the virtual services
_verify_same snip_collecting_new_telemetry_data_8 "$snip_collecting_new_telemetry_data_8_out"
_wait_for_istio virtualservice default reviews
_wait_for_istio virtualservice default ratings

# Get GATEWAY_URL
# export the INGRESS_ environment variables
# TODO make this work more generally. Currently using snips for Kind.
_set_ingress_environment_variables
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

# Next steps look at the Prometheus browser. Start redirection.
# snip_collecting_new_telemetry_data_10
istioctl dashboard prometheus &

# Hit the GATEWAY_URL and verify metrics exist
get_metrics_1() {
    curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
    curl -sg 'http://localhost:9090/api/v1/query?query=istio_tcp_connections_opened_total' | jq .data.result[0].metric.__name__
}

# Because of retries we can't validate values, but verify that metric exists.
_verify_contains get_metrics_1 '"istio_tcp_connections_opened_total"'
pgrep istioctl | xargs kill

# @cleanup
set +e # ignore cleanup errors
pgrep istioctl | xargs kill
kubectl delete -f samples/bookinfo/networking/virtual-service-ratings-db.yaml
kubectl delete -f samples/bookinfo/networking/destination-rule-all.yaml
kubectl delete -f samples/bookinfo/platform/kube/bookinfo-db.yaml
kubectl delete -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
kubectl delete -f samples/addons/prometheus.yaml -n istio-system
cleanup_bookinfo_sample