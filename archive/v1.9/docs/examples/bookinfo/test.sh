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

source "tests/util/samples.sh"

# @setup profile=demo

# remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-

snip_start_the_application_services_1

snip_start_the_application_services_2

_verify_like snip_start_the_application_services_4 "$snip_start_the_application_services_4_out"

for deploy in "productpage-v1" "details-v1" "ratings-v1" "reviews-v1" "reviews-v2" "reviews-v3"; do
    _wait_for_deployment default "$deploy"
done

_verify_like snip_start_the_application_services_5 "$snip_start_the_application_services_5_out"

_verify_contains snip_start_the_application_services_6 "$snip_start_the_application_services_6_out"

snip_determine_the_ingress_ip_and_port_1

_verify_like snip_determine_the_ingress_ip_and_port_2 "$snip_determine_the_ingress_ip_and_port_2_out"

# give config some time to propagate
_wait_for_istio gateway default bookinfo-gateway
_wait_for_istio virtualservice default bookinfo

# export the INGRESS_ environment variables
_set_ingress_environment_variables

snip_determine_the_ingress_ip_and_port_3

_verify_contains snip_confirm_the_app_is_accessible_from_outside_the_cluster_1 "$snip_confirm_the_app_is_accessible_from_outside_the_cluster_1_out"

snip_apply_default_destination_rules_1

_verify_lines snip_apply_default_destination_rules_2 "
+ productpage
+ reviews
+ ratings
+ details
"

# @cleanup
snip_cleanup_1
