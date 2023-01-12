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
export VERIFY_TIMEOUT=300

snip_before_you_begin_1

_wait_for_deployment foo httpbin

# Export the INGRESS_ environment variables
_set_ingress_environment_variables

_verify_same snip_before_you_begin_2 "$snip_before_you_begin_2_out"

# Apply the request authentication and virtual service.
snip_configuring_ingress_routing_based_on_jwt_claims_1
snip_configuring_ingress_routing_based_on_jwt_claims_2

_verify_elided snip_validating_ingress_routing_based_on_jwt_claims_1 "$snip_validating_ingress_routing_based_on_jwt_claims_1_out"
_verify_elided snip_validating_ingress_routing_based_on_jwt_claims_2 "$snip_validating_ingress_routing_based_on_jwt_claims_2_out"

# Pull the Istio branch from the docs configuration file.
ISTIO_BRANCH=$(yq '.source_branch_name' "${REPO_ROOT}"/data/args.yml)

TOKEN_GROUP_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/groups-scope.jwt"
export TOKEN_GROUP
TOKEN_GROUP=$(curl "${TOKEN_GROUP_URL}" -s)
_verify_elided snip_validating_ingress_routing_based_on_jwt_claims_4 "$snip_validating_ingress_routing_based_on_jwt_claims_4_out"

TOKEN_NO_GROUP_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/demo.jwt"
export TOKEN_NO_GROUP
TOKEN_NO_GROUP=$(curl "${TOKEN_NO_GROUP_URL}" -s)
_verify_elided snip_validating_ingress_routing_based_on_jwt_claims_6 "$snip_validating_ingress_routing_based_on_jwt_claims_6_out"

# @cleanup
snip_cleanup_1
snip_cleanup_2
