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
  curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/dashboard/db/istio-mesh-dashboard
}

function access_grafana_istio_service_dashboard() {
  curl -s -o /dev/null -w '%{http_code}'http://localhost:3000/dashboard/db/istio-service-dashboard
}

_verify_same access_grafana_istio_mesh_dashboard "200"
_verify_same access_grafana_istio_service_dashboard "200"
pgrep istioctl | xargs kill

# @cleanup
set +e

# TODO: Fix issue of killing twice (https://github.com/istio/istio.io/issues/8014)
pgrep istioctl | xargs kill
cleanup_bookinfo_sample
_undeploy_addons prometheus grafana
