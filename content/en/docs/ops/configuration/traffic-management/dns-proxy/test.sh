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

# @setup profile=none

set -e
set -u
set -o pipefail

# install Istio with smart dns proxy enabled
snip_getting_started_1

# deploy test application
snip_dns_capture_in_action_2

# configure service entries and verify
snip_dns_capture_in_action_1
_verify_first_line snip_dns_capture_in_action_3 "$snip_dns_capture_in_action_3_out"
snip_address_auto_allocation_1
_verify_contains snip_address_auto_allocation_2 "*   Trying 240.240."

# @cleanup

snip_cleanup_1

