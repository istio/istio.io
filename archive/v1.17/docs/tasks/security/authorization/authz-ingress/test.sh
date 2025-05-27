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

# @setup profile=default

# Set retries to a higher value because config update is slow.
export VERIFY_TIMEOUT=300

export CLIENT_IP

snip_before_you_begin_1

_wait_for_deployment foo httpbin

_verify_contains snip_before_you_begin_2 "rbac: debug"

# Export the INGRESS_ environment variables
_set_ingress_environment_variables

_verify_same snip_before_you_begin_3 "$snip_before_you_begin_3_out"

snip_source_ip_address_of_the_original_client_3

snip_ipbased_allow_list_and_deny_list_1
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_3 "$snip_ipbased_allow_list_and_deny_list_3_out"

snip_ipbased_allow_list_and_deny_list_2
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_3 "$snip_ipbased_allow_list_and_deny_list_3_out"

_verify_like snip_ipbased_allow_list_and_deny_list_4 "$snip_ipbased_allow_list_and_deny_list_4_out"

CLIENT_IP=$(kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"

snip_ipbased_allow_list_and_deny_list_5
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_8 "$snip_ipbased_allow_list_and_deny_list_8_out"

_verify_like snip_ipbased_allow_list_and_deny_list_6 "$snip_ipbased_allow_list_and_deny_list_6_out"

CLIENT_IP=$(kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"

snip_ipbased_allow_list_and_deny_list_7
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_8 "$snip_ipbased_allow_list_and_deny_list_8_out"

snip_ipbased_allow_list_and_deny_list_9
_wait_for_istio authorizationpolicy istio-system ingress-policy

CLIENT_IP=$(curl "$INGRESS_HOST":"$INGRESS_PORT"/ip -s | grep "origin" | cut -d'"' -f 4)

_verify_same snip_ipbased_allow_list_and_deny_list_11 "$snip_ipbased_allow_list_and_deny_list_11_out"

snip_ipbased_allow_list_and_deny_list_10
_wait_for_istio authorizationpolicy istio-system ingress-policy

CLIENT_IP=$(kubectl get pods -n istio-system | grep ingress | awk '{print $1}' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"

_verify_same snip_ipbased_allow_list_and_deny_list_11 "$snip_ipbased_allow_list_and_deny_list_11_out"

_verify_contains snip_ipbased_allow_list_and_deny_list_12 "remoteIP"

# @cleanup
snip_clean_up_1
snip_clean_up_2
