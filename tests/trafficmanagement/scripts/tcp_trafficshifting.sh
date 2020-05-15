#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/tcp-traffic-shifting/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

# TODO: why is the following needed in the test if it's not a needed step in the doc?
# add the TCP port to the ingress-gateway
kubectl -n istio-system patch service istio-ingressgateway --patch "
spec:
  ports:
    - port: 31400
      targetPort: 31400
      name: tcp
"

# create a new namespace for testing purposes and enable automatic Istio sidecar injection
snip_set_up_the_test_environment_1

# start the sleep sample
snip_set_up_the_test_environment_2

# start the v1 and v2 versions of the echo service
snip_set_up_the_test_environment_3

# wait for deployments to start
sample_wait_for_deployment istio-io-tcp-traffic-shifting tcp-echo-v1
sample_wait_for_deployment istio-io-tcp-traffic-shifting tcp-echo-v2
sample_wait_for_deployment istio-io-tcp-traffic-shifting sleep

# export the INGRESS_ environment variables
sample_set_ingress_environment_variables

# Route all traffic to echo v1
snip_apply_weightbased_tcp_routing_1

out=$(snip_apply_weightbased_tcp_routing_2 2>&1)
_verify_contains "$out" "one" "snip_apply_weightbased_tcp_routing_2"
_verify_not_contains "$out" "two" "snip_apply_weightbased_tcp_routing_2"

snip_apply_weightbased_tcp_routing_3

# wait for rules to propagate
sleep 5s # TODO: call proper wait utility (e.g., istioctl wait)

_run_and_verify_elided snip_apply_weightbased_tcp_routing_4 "$snip_apply_weightbased_tcp_routing_4_out"

out=$(snip_apply_weightbased_tcp_routing_5 2>&1)
_verify_contains "$out" "one" "snip_apply_weightbased_tcp_routing_5"
_verify_contains "$out" "two" "snip_apply_weightbased_tcp_routing_5"
