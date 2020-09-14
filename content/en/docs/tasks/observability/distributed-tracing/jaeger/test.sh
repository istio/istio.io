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

# NOTE: This test is very similar to the one for zipkin.
_deploy_and_wait_for_addons jaeger

kubectl label namespace default istio-injection=enabled --overwrite
startup_bookinfo_sample
_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
bpsnip_trace_generation__1

snip_accessing_the_dashboard_1 &

# Although test says, take a look at traces, we don't have to do that in this task
# as it is covered by an integration test in istio/istio.
function access_jaeger_by_port_forward() {
  curl -s -o /dev/null -w '%{http_code}' "http://localhost:16686/jaeger/api/traces?service=productpage.default"
}

_verify_same access_jaeger_by_port_forward "200"
pgrep istioctl | xargs kill

# @cleanup
set +e

# TODO: Fix issue of killing twice (https://github.com/istio/istio.io/issues/8014)
pgrep istioctl | xargs kill
cleanup_bookinfo_sample
_undeploy_addons jaeger
