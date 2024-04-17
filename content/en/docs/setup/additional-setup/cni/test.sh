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

source "tests/util/samples.sh"
source "tests/util/verify.sh"

get_productpage() {
    out=$(sample_http_request "/productpage")
    echo "$out"
}

# @setup profile=none

# Test helm install snip
kubectl create namespace istio-system
helm --set global.tag="${ISTIO_IMAGE_VERSION=SHOULD_BE_SET}"."${ISTIO_LONG_SHA=latest}" install istio-base manifests/charts/base -n istio-system --set defaultRevision=default
_rewrite_helm_repo snip_installing_with_helm_1
_rewrite_helm_repo snip_install_istio_with_cni_plugin_2
_wait_for_deployment istio-system istiod
_wait_for_daemonset kube-system istio-cni-node
helm delete istio-cni -n kube-system
helm delete istiod -n istio-system
helm delete istio-base -n istio-system
kubectl delete ns istio-system

# Test istioctl install snip
snip_install_istio_with_cni_plugin_1
_wait_for_deployment istio-system istiod
_wait_for_daemonset istio-system istio-cni-node

startup_bookinfo_sample
startup_sleep_sample

_verify_contains get_productpage "glyphicon glyphicon-star"

# @cleanup
cleanup_bookinfo_sample
cleanup_sleep_sample
echo y | istioctl uninstall --revision=default
kubectl delete ns istio-system
