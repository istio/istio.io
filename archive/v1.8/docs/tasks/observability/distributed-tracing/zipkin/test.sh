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
source "tests/util/addons.sh"

# @setup profile=demo

## Setting up application
# Set to known setting of sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

_deploy_and_wait_for_addons zipkin

# Install Bookinfo application
startup_bookinfo_sample

snip_accessing_the_dashboard_1 &

_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
bpsnip_trace_generation__1

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

# TODO: Fix issue with using killall. Also why do we need to do this in setup and cleanup?
pgrep istioctl | xargs kill
_undeploy_addons zipkin
