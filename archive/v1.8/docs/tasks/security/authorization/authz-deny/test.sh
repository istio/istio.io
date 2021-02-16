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

# Set retries to a higher value for some flakiness.
# TODO: remove this when istioctl wait calls are added
export VERIFY_TIMEOUT=300

snip_before_you_begin_1

_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep

_verify_same snip_before_you_begin_2 "$snip_before_you_begin_2_out"

snip_explicitly_deny_a_request_1
_wait_for_istio authorizationpolicy foo deny-method-get

_verify_same snip_explicitly_deny_a_request_2 "$snip_explicitly_deny_a_request_2_out"

_verify_same snip_explicitly_deny_a_request_3 "$snip_explicitly_deny_a_request_3_out"

snip_explicitly_deny_a_request_4
_wait_for_istio authorizationpolicy foo deny-method-get

_verify_same snip_explicitly_deny_a_request_5 "$snip_explicitly_deny_a_request_5_out"

_verify_same snip_explicitly_deny_a_request_6 "$snip_explicitly_deny_a_request_6_out"

snip_explicitly_deny_a_request_7
_wait_for_istio authorizationpolicy foo allow-path-ip

_verify_same snip_explicitly_deny_a_request_8 "$snip_explicitly_deny_a_request_8_out"

_verify_same snip_explicitly_deny_a_request_9 "$snip_explicitly_deny_a_request_9_out"

_verify_same snip_explicitly_deny_a_request_10 "$snip_explicitly_deny_a_request_10_out"

# @cleanup
set +e # ignore cleanup errors
snip_clean_up_1
