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

# @setup profile=none
echo "$snip_configure_tracing_1" | istioctl install -y -r opencensusagent -f -
snip_configure_tracing_2


# NOTE: This test is very similar to the one for zipkin.
_deploy_and_wait_for_addons jaeger

snip_deploy_opentelemetry_collector_1

kubectl label namespace default istio-injection=enabled --overwrite
startup_bookinfo_sample
_set_ingress_environment_variables
GATEWAY_URL="$INGRESS_HOST:$INGRESS_PORT"
bpsnip_trace_generation__1

_verify_contains snip_generating_traces_using_the_bookinfo_sample_1 "outbound|9080||productpage.default.svc.cluster.local"

# @cleanup
cleanup_bookinfo_sample
_undeploy_addons jaeger
kubectl delete telemetries.telemetry.istio.io -n istio-system mesh-default
snip_cleanup_3
istioctl uninstall -r opencensusagent --skip-confirmation
kubectl label namespace default istio-injection-
kubectl delete ns istio-system