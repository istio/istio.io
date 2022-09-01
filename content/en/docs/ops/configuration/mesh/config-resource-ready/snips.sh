#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/ops/configuration/mesh/config-resource-ready/index.md
####################################################################################################

snip_install_with_enable_status() {
istioctl install --set values.pilot.env.PILOT_ENABLE_STATUS=true --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.global.istiod.enableAnalysis=true
}

snip_apply_and_wait_for_httpbin_vs() {
kubectl apply -f samples/httpbin/httpbin.yaml
kubectl apply -f samples/httpbin/httpbin-gateway.yaml
kubectl wait --for=condition=Reconciled virtualservice/httpbin
}

! read -r -d '' snip_apply_and_wait_for_httpbin_vs_out <<\ENDSNIP
virtualservice.networking.istio.io/httpbin condition met
ENDSNIP
