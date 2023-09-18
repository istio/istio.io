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
#          docs/setup/additional-setup/pod-security-admission/index.md
####################################################################################################

snip_install_istio_with_psa_1() {
kubectl create namespace istio-system
kubectl label --overwrite ns istio-system \
    pod-security.kubernetes.io/enforce=privileged \
    pod-security.kubernetes.io/enforce-version=latest
}

! read -r -d '' snip_install_istio_with_psa_1_out <<\ENDSNIP
namespace/istio-system labeled
ENDSNIP

snip_install_istio_with_psa_2() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set components.cni.enabled=true -y
}

! read -r -d '' snip_install_istio_with_psa_2_out <<\ENDSNIP
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ CNI installed
✔ Installation complete
ENDSNIP

snip_deploy_the_sample_application_1() {
kubectl label --overwrite ns default \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/enforce-version=latest
}

! read -r -d '' snip_deploy_the_sample_application_1_out <<\ENDSNIP
namespace/default labeled
ENDSNIP

snip_deploy_the_sample_application_2() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-psa.yaml
}

! read -r -d '' snip_deploy_the_sample_application_2_out <<\ENDSNIP
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
ENDSNIP

snip_deploy_the_sample_application_3() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_deploy_the_sample_application_3_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_uninstall_1() {
kubectl delete -f samples/bookinfo/platform/kube/bookinfo-psa.yaml
}

snip_uninstall_2() {
kubectl label namespace default pod-security.kubernetes.io/enforce- pod-security.kubernetes.io/enforce-version-
}

snip_uninstall_3() {
istioctl uninstall -y --purge
}

snip_uninstall_4() {
kubectl delete namespace istio-system
}
