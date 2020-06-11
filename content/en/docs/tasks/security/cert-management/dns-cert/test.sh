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

export VERIFY_RETRIES=10

snip_before_you_begin_1
_wait_for_deployment istio-system istiod

# helper functions
check_dns_certs() {
    snip_check_the_provisioning_of_dns_certificates_1 | sed 's/[ ]*$//' # Remove trailing spaces
}
regen_dns_certs() {
    snip_regenerating_a_dns_certificate_2 | sed 's/[ ]*$//' # Remove trailing spaces
}

_verify_contains check_dns_certs "$snip_check_the_provisioning_of_dns_certificates_2"

snip_regenerating_a_dns_certificate_1

_verify_contains regen_dns_certs "$snip_regenerating_a_dns_certificate_3"

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_1
