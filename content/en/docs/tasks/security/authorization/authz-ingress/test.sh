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
export VERIFY_RETRIES=10

export CLIENT_IP

snip_before_you_begin_1

_wait_for_deployment foo httpbin

snip_before_you_begin_2

# Export the INGRESS_ environment variables
_set_ingress_environment_variables

_verify_same snip_before_you_begin_3 "$snip_before_you_begin_3_out"

snip_ipbased_allow_list_and_deny_list_1
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_same snip_ipbased_allow_list_and_deny_list_3 "$snip_ipbased_allow_list_and_deny_list_3_out"

snip_ipbased_allow_list_and_deny_list_2
_wait_for_istio authorizationpolicy istio-system ingress-policy

_verify_contains snip_ipbased_allow_list_and_deny_list_4 "remoteIP"

snip_ipbased_allow_list_and_deny_list_5

snip_ipbased_allow_list_and_deny_list_6
_wait_for_istio authorizationpolicy istio-system ingress-policy

snip_ipbased_allow_list_and_deny_list_7
_wait_for_istio authorizationpolicy istio-system ingress-policy

snip_ipbased_allow_list_and_deny_list_8

snip_ipbased_allow_list_and_deny_list_9
_wait_for_istio authorizationpolicy istio-system ingress-policy

snip_ipbased_allow_list_and_deny_list_10
_wait_for_istio authorizationpolicy istio-system ingress-policy

snip_ipbased_allow_list_and_deny_list_11

snip_ipbased_allow_list_and_deny_list_12

# @cleanup
set +e # ignore cleanup errors
snip_clean_up_1
snip_clean_up_2
