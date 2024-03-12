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
#          boilerplates/gateway-api-gamma-support.md
####################################################################################################

bpsnip_gateway_api_gamma_support_install_experimental_crds() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=444631bfe06f3bcca5d0eadf1857eac1d369421d" | kubectl apply -f -
}

bpsnip_gateway_api_gamma_support_enable_alpha_crds() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true --set profile=minimal -y
}
