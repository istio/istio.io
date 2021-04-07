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

snip_create_istio_system_namespace() {
kubectl create namespace istio-system
}

snip_install_base() {
helm install istio-base manifests/charts/base -n istio-system
}

snip_install_discovery() {
helm install istiod manifests/charts/istio-control/istio-discovery \
    -n istio-system
}

snip_install_ingressgateway() {
helm install istio-ingress manifests/charts/gateways/istio-ingress \
    -n istio-system
}

snip_install_egressgateway() {
helm install istio-egress manifests/charts/gateways/istio-egress \
    -n istio-system
}

snip_create_backup() {
kubectl get istio-io --all-namespaces -oyaml > "$HOME"/istio_resource_backup.yaml
}

snip_restore_backup() {
kubectl apply -f "$HOME"/istio_resource_backup.yaml
}

snip_canary_install_discovery() {
helm install istiod-canary manifests/charts/istio-control/istio-discovery \
    --set revision=canary \
    -n istio-system
}

snip_canary_upgrade_base() {
helm upgrade istio-base manifests/charts/base -n istio-system
}

snip_canary_upgrade_discovery() {
helm upgrade istiod manifests/charts/istio-control/istio-discovery \
    -n istio-system
}

snip_canary_upgrade_gateways() {
helm upgrade istio-ingress manifests/charts/gateways/istio-ingress \
    -n istio-system
helm upgrade istio-egress manifests/charts/gateways/istio-egress \
    -n istio-system
}

snip_helm_ls() {
helm ls -n istio-system
}

! read -r -d '' snip_helm_ls_out <<\ENDSNIP
NAME            NAMESPACE       REVISION    UPDATED                                 STATUS      CHART                    APP VERSION
istio-base      istio-system    1           ... ... ... ...                         deployed    base-1.9.0
istio-egress    istio-system    1           ... ... ... ...                         deployed    istio-egress-1.9.0
istio-ingress   istio-system    1           ... ... ... ...                         deployed    istio-ingress-1.9.0
istiod          istio-system    1           ... ... ... ...                         deployed    istio-discovery-1.9.0
ENDSNIP

snip_delete_delete_gateway_charts() {
helm delete istio-egress -n istio-system
helm delete istio-ingress -n istio-system
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
kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
    | xargs -n1 kubectl delete crd
}
