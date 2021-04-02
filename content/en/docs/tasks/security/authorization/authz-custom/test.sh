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

# Set retries to a higher value for some flakiness.
# TODO: remove this when istioctl wait calls are added
export VERIFY_TIMEOUT=300

snip_before_you_begin_1

_wait_for_deployment foo httpbin
_wait_for_deployment foo sleep

_verify_same snip_before_you_begin_2 "$snip_before_you_begin_2_out"

# deploy ext-authz service.
snip_deploy_the_external_authorizer_1
_wait_for_deployment foo ext-authz

_verify_lines snip_deploy_the_external_authorizer_2 "
+ Starting HTTP server at
+ Starting gRPC server at
"

# add the extension provider to the mesh config.
meshConfigPlaceholder="data:^  mesh: |-^"
extensionProviders=$(echo "$snip_define_the_external_authorizer_2" | tr '\n' '^')
kubectl get cm istio -n istio-system -o yaml | tr '\n' '^' | sed -e "s/${meshConfigPlaceholder}/${extensionProviders}/"  | tr '^' '\n' | kubectl apply -n istio-system -f -

# restart istiod.
snip_define_the_external_authorizer_4
_wait_for_deployment istio-system istiod

# create the authorization policy and verify the ext-authz response.
snip_enable_with_external_authorization_1

_verify_same snip_enable_with_external_authorization_2 "$snip_enable_with_external_authorization_2_out"
_verify_lines snip_enable_with_external_authorization_3 "
+ \"X-Ext-Authz-Check-Result\": \"allowed\",
"
_verify_same snip_enable_with_external_authorization_4 "$snip_enable_with_external_authorization_4_out"
_verify_lines snip_enable_with_external_authorization_5 "
+ [gRPCv3][allowed]
+ [gRPCv3][denied]
"

# @cleanup
snip_clean_up_1

# delete the extension provider from the mesh config.
meshConfigPlaceholder="data:^  mesh: |-^"
escapedExtensionProviders=$(echo "$snip_define_the_external_authorizer_2" | tr '\n' '^' | sed -e 's/[]\/$*.^[]/\\&/g')
kubectl get cm istio -n istio-system -o yaml | tr '\n' '^' | sed -e "s/${escapedExtensionProviders}/${meshConfigPlaceholder}/" | tr '^' '\n' | kubectl apply -n istio-system -f -
