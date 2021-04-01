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

# @setup profile=default

# Just apply the example policy to make sure it pass the validation.
kubectl create namespace foo
echo "$snip_require_different_jwt_issuer_per_host_1" | kubectl apply -f -
echo "$snip_namespace_isolation_1" | kubectl apply -f -
echo "$snip_namespace_isolation_with_ingress_exception_1" | kubectl apply -f -
echo "$snip_require_mtls_in_authorization_layer_defense_in_depth_1" | kubectl apply -f -
echo "$snip_require_mandatory_authorization_check_with_deny_policy_1" | kubectl apply -f -
echo "$snip_require_mandatory_authorization_check_with_deny_policy_2" | kubectl apply -f -

# @cleanup
kubectl delete authorizationpolicies.security.istio.io --all --all-namespaces
kubectl delete namespace foo
