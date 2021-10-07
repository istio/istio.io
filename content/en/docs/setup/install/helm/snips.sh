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
#          docs/setup/install/helm/index.md
####################################################################################################
source "content/en/boilerplates/snips/helm-prereqs.sh"

snip_create_istio_system_namespace() {
kubectl create namespace istio-system
}

snip_install_base() {
helm install istio-base istio/base -n istio-system
}

snip_install_discovery() {
helm install istiod istio/istiod -n istio-system --wait
}

snip_install_ingressgateway() {
kubectl create namespace istio-ingress
kubectl label namespace istio-ingress istio-injection=enabled
helm install istio-ingress istio/gateway -n istio-ingress --wait
}

snip_helm_ls() {
helm ls -n istio-system
}

! read -r -d '' snip_helm_ls_out <<\ENDSNIP
NAME       NAMESPACE    REVISION UPDATED         STATUS   CHART        APP VERSION
istio-base istio-system 1        ... ... ... ... deployed base-1.0.0   1.0.0
istiod     istio-system 1        ... ... ... ... deployed istiod-1.0.0 1.0.0
ENDSNIP

snip_delete_delete_gateway_charts() {
helm delete istio-ingress -n istio-ingress
kubectl delete namespace istio-ingress
}

snip_helm_delete_discovery_chart() {
helm delete istiod -n istio-system
}

snip_helm_delete_base_chart() {
helm delete istio-base -n istio-system
}

snip_delete_istio_system_namespace() {
kubectl delete namespace istio-system
}

snip_delete_crds() {
kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
}
