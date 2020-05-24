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

source "${REPO_ROOT}/content/en/docs/tasks/traffic-management/mirroring/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

kubectl label namespace default istio-injection=enabled --overwrite

snip_before_you_begin_1

snip_before_you_begin_2

snip_before_you_begin_3

snip_before_you_begin_4

# wait for deployments
#sample_wait_for_deployment default httpbin-v1
#sample_wait_for_deployment default httpbin-v2
#sample_wait_for_deployment default sleep

snip_creating_a_default_routing_policy_1

# wait for virtual service
#istioctl experimental wait --for=distribution VirtualService httpbin.default
#sleep 5s

kubectl get all --all-namespaces

#_run_and_verify_contains snip_creating_a_default_routing_policy_2 "headers"

#_run_and_verify_contains snip_creating_a_default_routing_policy_3 "GET /headers HTTP/1.1"

#_run_and_verify_not_contains snip_creating_a_default_routing_policy_4 "GET /headers HTTP/1.1"

#snip_mirroring_traffic_to_v2_1

# wait for virtual service
#istioctl experimental wait --for=distribution VirtualService httpbin.default
#sleep 5s

#snip_mirroring_traffic_to_v2_2

#_run_and_verify_contains snip_mirroring_traffic_to_v2_3 "GET /headers HTTP/1.1"

#_run_and_verify_contains snip_mirroring_traffic_to_v2_3 "GET /headers HTTP/1.1"
