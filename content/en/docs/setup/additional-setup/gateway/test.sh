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
    istioctl x uninstall --purge --skip-confirmation
    kubectl delete namespace istio-ingress
    istioctl install --skip-confirmation --set profile=minimal
}

# rewrite-repo invokes bash make to rewrite a snippet to avoid installing from a real helm repository, and instead uses
# local files
# shellcheck disable=SC2001
function rewrite-repo() {
  # get function definition: https://stackoverflow.com/a/6916952/374797
  cmd="$(type "${1:?snip}" | sed '1,3d;$d')"
  cmd="$(echo "${cmd}" | sed 's|istio/base|manifests/charts/base|')"
  cmd="$(echo "${cmd}" | sed 's|istio/istiod|manifests/charts/istio-control/istio-discovery|')"
  cmd="$(echo "${cmd}" | sed 's|istio/gateway|manifests/charts/gateway|')"
  eval "${cmd} --set global.tag=${ISTIO_IMAGE_VERSION=SHOULD_BE_SET}.${ISTIO_LONG_SHA=latest} --wait"
}

istioctl install --skip-confirmation --set profile=minimal
_wait_for_deployment istio-system istiod

# shellcheck disable=SC2154
cat <<EOF >ingress.yaml
$snip_deploying_a_gateway_1
EOF

echo y | snip_deploying_a_gateway_2
_wait_for_deployment istio-ingress ingressgateway

rebuild
rewrite-repo snip_deploying_a_gateway_3
_wait_for_deployment istio-ingress istio-ingress

rebuild
# shellcheck disable=SC2154
cat <<EOF >ingress.yaml
$snip_deploying_a_gateway_4
EOF
snip_deploying_a_gateway_5
_wait_for_deployment istio-ingress istio-ingressgateway

# @cleanup

kubectl delete namespace istio-ingress