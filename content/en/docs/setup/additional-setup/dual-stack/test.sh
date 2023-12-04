#!/usr/bin/env bash
# shellcheck disable=SC2154
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

# @setup dualstack

# create test namespaces and deployments
snip_verification_1
snip_verification_2
snip_verification_3
snip_verification_4

# wait for deployments to be up and running
_wait_for_deployment default sleep
_wait_for_deployment dual-stack tcp-echo
_wait_for_deployment ipv4 tcp-echo
_wait_for_deployment ipv6 tcp-echo

# verify traffic
_verify_like snip_verification_5 "$snip_verification_5_out"
_verify_like snip_verification_6 "$snip_verification_6_out"
_verify_like snip_verification_7 "$snip_verification_7_out"

# @cleanup
snip_cleanup_1