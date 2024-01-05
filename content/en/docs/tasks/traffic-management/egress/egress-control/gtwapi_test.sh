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

source "tests/util/gateway-api.sh"
install_gateway_api_crds

# @setup profile=demo

kubectl label namespace default istio-injection=enabled --overwrite

snip_before_you_begin_1
_wait_for_deployment default sleep
snip_before_you_begin_3

snip_access_an_external_http_service_1
_wait_for_istio serviceentry default httpbin-ext

_verify_first_line snip_manage_traffic_to_external_services_1 "$snip_manage_traffic_to_external_services_1_out"
snip_manage_traffic_to_external_services_3
_verify_first_line snip_manage_traffic_to_external_services_4 "$snip_manage_traffic_to_external_services_4_out"

# @cleanup
snip_cleanup_the_controlled_access_to_external_services_2
snip_cleanup_1
kubectl label namespace default istio-injection-
remove_gateway_api_crds
