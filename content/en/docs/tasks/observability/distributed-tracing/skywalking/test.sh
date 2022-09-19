#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2034,SC2016

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

# @setup profile=none
echo "$snip_configure_tracing_1" | istioctl install -y -r skywalkingagent -f -
snip_configure_tracing_2

_deploy_and_wait_for_addons skywalking

## Setting up application
kubectl label namespace default istio-injection=enabled --overwrite

# Install Bookinfo application
startup_bookinfo_sample

snip_accessing_the_dashboard_1 &

_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
bpsnip_trace_generation__1

function access_skywalking_with_portforward() {
  local skywalking_url='http://localhost:8080/graphql'
  local product_svc_id="cHJvZHVjdHBhZ2UuZGVmYXVsdA==.1"
  local now=$(date +%s)
  local _15min_ago=$((now - 15 * 60))
  local now=$(date +'%Y-%m-%d %H%M' -d @"$now")
  local _15min_ago=$(date +'%Y-%m-%d %H%M' -d @"$_15min_ago")

  curl -s "$skywalking_url" \
    -X 'POST' \
    -H 'Content-Type: application/json' \
    --data-binary '{
      "query": "query queryTraces($condition: TraceQueryCondition) { result: queryBasicTraces(condition: $condition) { traces { key: segmentId endpointNames duration start isError traceIds } } }",
      "variables": {
        "condition": {
          "queryDuration": {
            "start": "'"$_15min_ago"'",
            "end": "'"$now"'",
            "step": "MINUTE"
          },
          "traceState": "ALL",
          "queryOrder": "BY_DURATION",
          "paging": {
            "pageNum": 1,
            "pageSize": 20
          },
          "serviceId": "'"$product_svc_id"'",
          "minTraceDuration": null,
          "maxTraceDuration": null
        }
      }
    }' | jq '.data.result.traces | length'
}

_verify_same access_skywalking_with_portforward 20
pgrep istioctl | xargs kill

# @cleanup
cleanup_bookinfo_sample

# TODO: Fix issue with using killall. Also why do we need to do this in setup and cleanup?
pgrep istioctl | xargs kill
_undeploy_addons skywalking

kubectl delete telemetries.telemetry.istio.io -n istio-system mesh-default
istioctl uninstall -r skywalkingagent --skip-confirmation
kubectl label namespace default istio-injection-
kubectl delete ns istio-system
