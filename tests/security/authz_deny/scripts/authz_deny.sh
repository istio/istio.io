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

source "${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-deny/snips.sh"

max_attempts=5

_run_and_verify_same snip_before_you_begin_2 "$snip_before_you_begin_2_out" $max_attempts

snip_explicitly_deny_a_request_1

_run_and_verify_same snip_explicitly_deny_a_request_2 "$snip_explicitly_deny_a_request_2_out" $max_attempts

_run_and_verify_same snip_explicitly_deny_a_request_3 "$snip_explicitly_deny_a_request_3_out" $max_attempts

snip_explicitly_deny_a_request_4

_run_and_verify_same snip_explicitly_deny_a_request_5 "$snip_explicitly_deny_a_request_5_out" $max_attempts

_run_and_verify_same snip_explicitly_deny_a_request_6 "$snip_explicitly_deny_a_request_6_out" $max_attempts

snip_explicitly_deny_a_request_7

_run_and_verify_same snip_explicitly_deny_a_request_8 "$snip_explicitly_deny_a_request_8_out" $max_attempts

_run_and_verify_same snip_explicitly_deny_a_request_9 "$snip_explicitly_deny_a_request_9_out" $max_attempts

_run_and_verify_same snip_explicitly_deny_a_request_10 "$snip_explicitly_deny_a_request_10_out" $max_attempts
