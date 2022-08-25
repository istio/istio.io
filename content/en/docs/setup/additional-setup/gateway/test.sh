#!/usr/bin/env bash
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

# @setup profile=none
function rebuild() {
    istioctl uninstall --purge --skip-confirmation
    kubectl delete namespace istio-ingress
    istioctl install --skip-confirmation --set profile=minimal
}

istioctl install --skip-confirmation --set profile=minimal
_wait_for_deployment istio-system istiod

# shellcheck disable=SC2154
cat <<EOF >ingress.yaml
$snip_deploying_a_gateway_1
EOF

echo y | snip_deploying_a_gateway_2
_wait_for_deployment istio-ingress istio-ingressgateway

rebuild
_rewrite_helm_repo snip_deploying_a_gateway_3
_wait_for_deployment istio-ingress istio-ingressgateway

rebuild
# shellcheck disable=SC2154
cat <<EOF >ingress.yaml
$snip_deploying_a_gateway_4
EOF
snip_deploying_a_gateway_5
_wait_for_deployment istio-ingress istio-ingressgateway

istioctl install --skip-confirmation --set profile=minimal --set revision=canary
_wait_for_deployment istio-system istiod-canary

# shellcheck disable=SC2154
cat <<EOF | kubectl apply -f -
$snip_canary_upgrade_advanced_1
EOF
_wait_for_deployment istio-ingress istio-ingressgateway-canary

# shellcheck disable=SC2154
_verify_like snip_canary_upgrade_advanced_2 "${snip_canary_upgrade_advanced_2_out}"

# @cleanup

istioctl uninstall --purge --skip-confirmation
kubectl delete namespace istio-system
kubectl delete namespace istio-ingress