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

export CLIENT_IP

snip_before_you_begin_1

_wait_for_deployment foo httpbin

snip_before_you_begin_2

# Export the INGRESS_ environment variables
_set_ingress_environment_variables

_verify_same snip_before_you_begin_3 "$snip_before_you_begin_3_out"

_verify_like snip_before_you_begin_4 "$snip_before_you_begin_4_out"

CLIENT_IP=$(curl "$INGRESS_HOST":"$INGRESS_PORT"/ip -s | grep "origin" | cut -d'"' -f 4)

snip_ipbased_allow_list_and_deny_list_1
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_2 "$snip_ipbased_allow_list_and_deny_list_2_out"

snip_ipbased_allow_list_and_deny_list_3
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_4 "$snip_ipbased_allow_list_and_deny_list_4_out"

snip_ipbased_allow_list_and_deny_list_5
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_6 "$snip_ipbased_allow_list_and_deny_list_6_out"

# @cleanup
set +e # ignore cleanup errors
snip_clean_up_1
snip_clean_up_2
