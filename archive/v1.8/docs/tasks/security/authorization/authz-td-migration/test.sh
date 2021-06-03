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

#export VERIFY_TIMEOUT=300

echo y | snip_before_you_begin_1

# Remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-

# Wait fo Istio to start up.
_wait_for_deployment istio-system istiod

snip_before_you_begin_2

_wait_for_deployment default sleep
_wait_for_deployment default httpbin
_wait_for_deployment sleep-allow sleep

snip_before_you_begin_3

_verify_same snip_before_you_begin_4 "$snip_before_you_begin_4_out"

_verify_same snip_before_you_begin_5 "$snip_before_you_begin_5_out"

echo y | snip_migrate_trust_domain_without_trust_domain_aliases_1

snip_migrate_trust_domain_without_trust_domain_aliases_2

_wait_for_deployment istio-system istiod

snip_migrate_trust_domain_without_trust_domain_aliases_3

snip_migrate_trust_domain_without_trust_domain_aliases_4

_verify_same snip_migrate_trust_domain_without_trust_domain_aliases_5 "$snip_migrate_trust_domain_without_trust_domain_aliases_5_out"

_verify_same snip_migrate_trust_domain_without_trust_domain_aliases_6 "$snip_migrate_trust_domain_without_trust_domain_aliases_6_out"

echo y | snip_migrate_trust_domain_with_trust_domain_aliases_1

_wait_for_deployment istio-system istiod

_verify_same snip_migrate_trust_domain_with_trust_domain_aliases_2 "$snip_migrate_trust_domain_with_trust_domain_aliases_2_out"

_verify_same snip_migrate_trust_domain_with_trust_domain_aliases_3 "$snip_migrate_trust_domain_with_trust_domain_aliases_3_out"

# @cleanup

set +e # ignore cleanup errors
echo y | snip_clean_up_1
