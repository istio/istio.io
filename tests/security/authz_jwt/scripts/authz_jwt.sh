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

source "${REPO_ROOT}/content/en/docs/tasks/security/authorization/authz-jwt/snips.sh"

# Pull the Istio branch from the docs configuration file.
ISTIO_BRANCH=$(yq r "${REPO_ROOT}"/data/args.yml 'source_branch_name')

TOKEN_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/demo.jwt"
TOKEN_GROUP_URL="https://raw.githubusercontent.com/istio/istio/${ISTIO_BRANCH}/security/tools/jwt/samples/groups-scope.jwt"

export TOKEN
export TOKEN_GROUP

max_attempts=5

_run_and_verify_same  snip_before_you_begin_2 "$snip_before_you_begin_2_out" $max_attempts

snip_allow_requests_with_valid_jwt_and_listtyped_claims_1

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_2 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_2_out" $max_attempts

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_3 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_3_out" $max_attempts

snip_allow_requests_with_valid_jwt_and_listtyped_claims_4

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_5 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_5_out" $max_attempts

# The previous step stored the JWT in TOKEN, and it's needed in the next step.
TOKEN=$(curl "${TOKEN_URL}" -s)

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_6 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_6_out" $max_attempts

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_7 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_7_out" $max_attempts

snip_allow_requests_with_valid_jwt_and_listtyped_claims_8

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_9 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_9_out" $max_attempts

# The previous step stored the JWT group in TOKEN_GROUP, and it's needed in
# the next step.
TOKEN_GROUP=$(curl "${TOKEN_GROUP_URL}" -s)

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_10 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_10_out" $max_attempts

_run_and_verify_same snip_allow_requests_with_valid_jwt_and_listtyped_claims_11 "$snip_allow_requests_with_valid_jwt_and_listtyped_claims_11_out" $max_attempts
