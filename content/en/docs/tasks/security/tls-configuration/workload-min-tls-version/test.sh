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

# shellcheck disable=SC2001

set -e
set -u
set -o pipefail

# @setup profile=none

export VERIFY_TIMEOUT=300

echo y | snip_before_you_begin_1
_wait_for_deployment istio-system istiod

snip_before_you_begin_2
_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep

# Send request from sleep to httpbin
_verify_contains snip_before_you_begin_3 "$snip_before_you_begin_3_out"

_verify_contains snip_check_the_tls_configuration_of_istio_workloads_1 "$snip_check_the_tls_configuration_of_istio_workloads_2"

_verify_contains snip_check_the_tls_configuration_of_istio_workloads_3 "$snip_check_the_tls_configuration_of_istio_workloads_4"

# @cleanup
snip_cleanup_1