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
#          docs/ops/ambient/upgrade/helm-upgrade/index.md
####################################################################################################

snip_update_helm() {
helm repo update istio
}

snip_istioctl_precheck() {
istioctl x precheck
}

! read -r -d '' snip_istioctl_precheck_out <<\ENDSNIP
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out <https://istio.io/latest/docs/setup/getting-started/>
ENDSNIP

snip_manual_crd_upgrade() {
kubectl apply -f manifests/charts/base/crds
}

snip_upgrade_base() {
helm upgrade istio-base manifests/charts/base -n istio-system --skip-crds
}

snip_upgrade_istiod() {
helm upgrade istiod istio/istiod -n istio-system
}

snip_upgrade_ztunnel() {
helm upgrade ztunnel istio/ztunnel -n istio-system
}

snip_upgrade_cni() {
helm upgrade istio-cni istio/cni -n istio-system
}

snip_upgrade_gateway() {
helm upgrade istio-ingress istio/gateway -n istio-ingress
}

snip_show_istiod_values() {
helm show values istio/istiod
}

snip_show_components() {
helm list -n istio-system
}

snip_check_pods() {
kubectl get pods -n istio-system
}
