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
#          docs/ops/ambient/install/helm-installation/index.md
####################################################################################################

snip_configure_helm() {
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
}

snip_install_base() {
helm install istio-base istio/base -n istio-system --create-namespace
}

snip_install_cni() {
helm install istio-cni istio/cni -n istio-system --set profile=ambient
}

snip_install_discovery() {
helm install istiod istio/istiod --namespace istio-system --set profile=ambient
}

snip_install_ztunnel() {
helm install ztunnel istio/ztunnel -n istio-system
}

snip_configuration_1() {
helm show values istio/istiod
}

snip_show_components() {
helm list -n istio-system
}

snip_check_pods() {
kubectl get pods -n istio-system
}

snip_uninstall_1() {
helm ls -n istio-system
}

! read -r -d '' snip_uninstall_1_out <<\ENDSNIP
NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART        APP VERSION
istio-base istio-system 1        ... ... ... ... deployed base-1.0.0   1.0.0
istiod     istio-system 1        ... ... ... ... deployed istiod-1.0.0 1.0.0
ENDSNIP

snip_uninstall_2() {
helm delete istio-ingress -n istio-ingress
kubectl delete namespace istio-ingress
}

snip_delete_cni() {
helm delete istio-cni -n istio-system
}

snip_delete_ztunnel() {
helm delete ztunnel -n istio-system
}

snip_delete_discovery() {
helm delete istiod -n istio-system
}

snip_delete_base() {
helm delete istio-base -n istio-system
}

snip_uninstall_7() {
kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
}

snip_delete_system_namespace() {
kubectl delete namespace istio-system
}
