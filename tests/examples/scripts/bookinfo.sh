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

source "${REPO_ROOT}/content/en/docs/examples/bookinfo/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

# remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-

snip_start_the_application_services_1

snip_start_the_application_services_2

_run_and_verify_like snip_start_the_application_services_4 "$snip_start_the_application_services_4_out"

kubectl wait --for=condition=available deployment --all --timeout=300s
kubectl wait --for=condition=Ready pod --all --timeout=300s

_run_and_verify_like snip_start_the_application_services_5 "$snip_start_the_application_services_5_out"

_run_and_verify_contains snip_start_the_application_services_6 "$snip_start_the_application_services_6_out"

snip_determine_the_ingress_ip_and_port_1

_run_and_verify_like snip_determine_the_ingress_ip_and_port_2 "$snip_determine_the_ingress_ip_and_port_2_out"

# give it some time to propagate
sleep 5

# export the INGRESS_ environment variables
sample_set_ingress_environment_variables

snip_determine_the_ingress_ip_and_port_3

_run_and_verify_contains snip_confirm_the_app_is_accessible_from_outside_the_cluster_1 "$snip_confirm_the_app_is_accessible_from_outside_the_cluster_1_out"
