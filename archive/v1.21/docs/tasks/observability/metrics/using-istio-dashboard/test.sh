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

source "tests/util/helpers.sh"
source "tests/util/samples.sh"
source "tests/util/addons.sh"

# @setup profile=default

_deploy_and_wait_for_addons prometheus grafana
_verify_like snip_viewing_the_istio_dashboard_1 "$snip_viewing_the_istio_dashboard_1_out"
_verify_like snip_viewing_the_istio_dashboard_2 "$snip_viewing_the_istio_dashboard_2_out"

# TODO: Deploying bookinfo and sending requests through ingress gateway
# seems like a common pattern for many tests. Should be moved to tests/util.
kubectl label namespace default istio-injection=enabled --overwrite
startup_bookinfo_sample
_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"

bpsnip_trace_generation__1

snip_viewing_the_istio_dashboard_3 &

# For verification, we only check if the dashboards are accessible, but not its actual contents
# TODO: Is it worth checking API calls and output for Grafana case?
function access_grafana_istio_mesh_dashboard() {
  curl -L -s -o /dev/null -w '%{http_code}' "http://localhost:3000/d/G8wLrJIZk/istio-mesh-dashboard"
}

function access_grafana_istio_service_dashboard() {
  curl -L -s -o /dev/null -w '%{http_code}' "http://localhost:3000/d/LJ_uJAvmk/istio-service-dashboard"
}

function access_grafana_istio_workload_dashboard() {
  curl -L -s -o /dev/null -w '%{http_code}' "http://localhost:3000/d/UbsSZTDik/istio-workload-dashboard"
}

# Grafana calls this behind the scenes. It sends a query to prometheus
# The long and scary query is copied straight from requests page in browser
# and some parameters are edited. Basically it is a URL-encoded prometheus query
function query_request_count_to_productpage() {
  curl -L -s 'http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=%20sum(istio_requests_total%7Breporter%3D%22destination%22%2C%20destination_service%3D~%22productpage.default.svc.cluster.local%22%2C%20source_workload_namespace%3D~%22istio-system%22%7D)%20by%20(source_workload)%20or%20sum(istio_tcp_sent_bytes_total%7Breporter%3D%22destination%22%2C%20destination_service%3D~%22productpage.default.svc.cluster.local%22%2C%20source_workload_namespace%3D~%22istio-system%22%7D)%20by%20(source_workload)' | jq -r '.status'
}

# This Prometheus query is from Mesh dashboard
function query_request_for_all_workloads() {
  bpsnip_trace_generation__1
  curl -L -s 'http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=label_join(sum(rate(istio_requests_total%7Breporter%3D%22destination%22%2C%20response_code%3D%22200%22%7D%5B1m%5D))%20by%20(destination_workload%2C%20destination_workload_namespace%2C%20destination_service)%2C%20%22destination_workload_var%22%2C%20%22.%22%2C%20%22destination_workload%22%2C%20%22destination_workload_namespace%22)' \
  | jq -r '.data.result[].metric.destination_workload_var' | sort
}

function query_request_from_productpage_workload() {
  curl -L -s 'http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=%20sum(istio_requests_total%7Breporter%3D%22source%22%2C%20source_workload%3D~%22productpage-v1%22%2C%20source_workload_namespace%3D~%22default%22%7D)%20by%20(destination_service)%20or%20sum(istio_tcp_sent_bytes_total%7Breporter%3D%22source%22%2C%20source_workload%3D~%22productpage-v1%22%2C%20source_workload_namespace%3D~%22default%22%7D)%20by%20(destination_service)' \
  | jq -r '.data.result[].metric.destination_service' | sort
}

_verify_same access_grafana_istio_mesh_dashboard "200"
_verify_lines query_request_for_all_workloads "
+ details-v1.default
+ productpage-v1.default
+ ratings-v1.default
+ reviews-v1.default
+ reviews-v2.default
+ reviews-v3.default
"

_verify_same access_grafana_istio_service_dashboard "200"
_verify_same query_request_count_to_productpage "success"

_verify_same access_grafana_istio_workload_dashboard "200"
_verify_lines query_request_from_productpage_workload "
+ details.default.svc.cluster.local
+ reviews.default.svc.cluster.local
"

pgrep istioctl | xargs kill

# @cleanup
# TODO: Fix issue of killing twice (https://github.com/istio/istio.io/issues/8014)
pgrep istioctl | xargs kill
cleanup_bookinfo_sample
_undeploy_addons prometheus grafana
