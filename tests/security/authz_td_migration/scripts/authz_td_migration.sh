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

source "${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-td-migration/snips.sh"
source "${REPO_ROOT}/tests/util/samples.sh"

max_attempts=10

snip_before_you_begin_1

# Remove the injection label to prevent the following command from failing
kubectl label namespace default istio-injection-

# Give Istio a little time to start up.
sleep 5

snip_before_you_begin_2

sample_wait_for_deployment default sleep
sample_wait_for_deployment default httpbin
sample_wait_for_deployment sleep-allow sleep

snip_before_you_begin_3

_run_and_verify_same snip_before_you_begin_4 "$snip_before_you_begin_4_out" $max_attempts

_run_and_verify_same snip_before_you_begin_5 "$snip_before_you_begin_5_out" $max_attempts

snip_migrate_trust_domain_without_trust_domain_aliases_1

snip_migrate_trust_domain_without_trust_domain_aliases_2

snip_migrate_trust_domain_without_trust_domain_aliases_3

_run_and_verify_same snip_migrate_trust_domain_without_trust_domain_aliases_4 "$snip_migrate_trust_domain_without_trust_domain_aliases_4_out" $max_attempts

_run_and_verify_same snip_migrate_trust_domain_without_trust_domain_aliases_5 "$snip_migrate_trust_domain_without_trust_domain_aliases_5_out" $max_attempts

snip_migrate_trust_domain_with_trust_domain_aliases_1

_run_and_verify_same snip_migrate_trust_domain_with_trust_domain_aliases_2 "$snip_migrate_trust_domain_with_trust_domain_aliases_2_out" $max_attempts

_run_and_verify_same snip_migrate_trust_domain_with_trust_domain_aliases_3 "$snip_migrate_trust_domain_with_trust_domain_aliases_3_out" $max_attempts
