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
_wait_for_deployment istio-system istiod

snip_setup_1

_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep
_wait_for_deployment bar httpbin
_wait_for_deployment bar sleep
_wait_for_deployment legacy httpbin
_wait_for_deployment legacy sleep

_verify_same  snip_setup_2 "$snip_setup_2_out"
_verify_same  snip_setup_3 "$snip_setup_3_out"
_verify_same  snip_setup_4 "$snip_setup_4_out"
snip_setup_5

_verify_like  snip_auto_mutual_tls_1 "$snip_auto_mutual_tls_1_out"
_verify_same  snip_auto_mutual_tls_2 "$snip_auto_mutual_tls_2_out"

snip_globally_enabling_istio_mutual_tls_in_strict_mode_1
_wait_for_istio peerauthentication istio-system default

_verify_same  snip_globally_enabling_istio_mutual_tls_in_strict_mode_2 "$snip_globally_enabling_istio_mutual_tls_in_strict_mode_2_out"

snip_cleanup_part_1_1

snip_namespacewide_policy_1
_wait_for_istio peerauthentication foo default

_verify_same  snip_namespacewide_policy_2 "$snip_namespacewide_policy_2_out"

snip_enable_mutual_tls_per_workload_1
snip_enable_mutual_tls_per_workload_2
_wait_for_istio peerauthentication bar httpbin
_wait_for_istio destinationrule  bar httpbin

_verify_same  snip_enable_mutual_tls_per_workload_3 "$snip_enable_mutual_tls_per_workload_3_out"

# Ignore snip_enable_mutual_tls_per_workload_4()--it's just text.

snip_enable_mutual_tls_per_workload_5
snip_enable_mutual_tls_per_workload_6
_wait_for_istio peerauthentication bar httpbin
_wait_for_istio destinationrule  bar httpbin

_verify_same  snip_enable_mutual_tls_per_workload_7 "$snip_enable_mutual_tls_per_workload_7_out"

snip_policy_precedence_1
snip_policy_precedence_2
_wait_for_istio peerauthentication foo overwrite-example
_wait_for_istio destinationrule  foo overwrite-example

_verify_same  snip_policy_precedence_3 "$snip_policy_precedence_3_out"

snip_cleanup_part_2_1

snip_enduser_authentication_1
snip_enduser_authentication_2
_wait_for_istio gateway foo httpbin-gateway
_wait_for_istio virtualservice  foo httpbin

# Export the INGRESS_ environment variables
_set_ingress_environment_variables

_verify_same  snip_enduser_authentication_3 "$snip_enduser_authentication_3_out"

snip_enduser_authentication_4
_wait_for_istio requestauthentication istio-system jwt-example

_verify_same  snip_enduser_authentication_5 "$snip_enduser_authentication_5_out"
_verify_same  snip_enduser_authentication_6 "$snip_enduser_authentication_6_out"
_verify_same  snip_enduser_authentication_7 "$snip_enduser_authentication_7_out"

snip_enduser_authentication_8
snip_enduser_authentication_9

# snip_enduser_authentication_10 is highly timing dependent, so just check
# that the token times out during the run.
expected="200
401"
_verify_contains  snip_enduser_authentication_10 "$expected"

snip_require_a_valid_token_1
_wait_for_istio authorizationpolicy istio-system frontend-ingress

_verify_same  snip_require_a_valid_token_2 "$snip_require_a_valid_token_2_out"

snip_require_valid_tokens_perpath_1
_wait_for_istio authorizationpolicy istio-system frontend-ingress

_verify_same  snip_require_valid_tokens_perpath_2 "$snip_require_valid_tokens_perpath_2_out"
_verify_same  snip_require_valid_tokens_perpath_3 "$snip_require_valid_tokens_perpath_3_out"

# @cleanup
snip_cleanup_part_1_1
snip_cleanup_part_2_1
snip_cleanup_part_3_1
snip_cleanup_part_3_2
snip_cleanup_part_3_3
snip_cleanup_part_3_4
