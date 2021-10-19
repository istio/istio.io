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
#          docs/ops/diagnostic-tools/istioctl-analyze/index.md
####################################################################################################

snip_analyze_all_namespaces() {
istioctl analyze --all-namespaces
}

! read -r -d '' snip_analyze_all_namespace_sample_response <<\ENDSNIP
Info [IST0102] (Namespace default) The namespace is not enabled for Istio injection. Run 'kubectl label namespace default istio-injection=enabled' to enable it, or 'kubectl label namespace default istio-injection=disabled' to explicitly mark it as not needing injection.
ENDSNIP

snip_fix_default_namespace() {
kubectl label namespace default istio-injection=enabled
}

snip_try_with_fixed_namespace() {
istioctl analyze --namespace default
}

! read -r -d '' snip_try_with_fixed_namespace_out <<\ENDSNIP
✔ No validation issues found when analyzing namespace: default.
ENDSNIP

snip_analyze_sample_destrule() {
istioctl analyze samples/bookinfo/networking/bookinfo-gateway.yaml samples/bookinfo/networking/destination-rule-all.yaml
}

! read -r -d '' snip_analyze_sample_destrule_out <<\ENDSNIP
Error [IST0101] (Gateway default/bookinfo-gateway samples/bookinfo/networking/bookinfo-gateway.yaml:7) Referenced selector not found: "istio=ingressgateway"
Error [IST0101] (VirtualService default/bookinfo samples/bookinfo/networking/bookinfo-gateway.yaml:39) Referenced host not found: "productpage"
Error: Analyzers found issues when analyzing namespace: default.
See https://istio.io/v1.12/docs/reference/config/analysis for more information about causes and resolutions.
ENDSNIP

snip_analyze_networking_directory() {
istioctl analyze samples/bookinfo/networking/
}

snip_analyze_all_networking_yaml() {
istioctl analyze samples/bookinfo/networking/*.yaml
}

snip_analyze_all_networking_yaml_no_kube() {
istioctl analyze --use-kube=false samples/bookinfo/networking/*.yaml
}

! read -r -d '' snip_vs_yaml_with_status <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
...
status:
  validationMessages:
  - documentation_url: https://istio.io/v1.12/docs/reference/config/analysis/ist0101/?ref=status-controller
    level: 3
    type:
      code: IST0101
ENDSNIP

snip_install_with_custom_config_analysis() {
istioctl install --set values.global.istiod.enableAnalysis=true
}

snip_analyze_k_frod() {
istioctl analyze -k --namespace frod
}

! read -r -d '' snip_analyze_k_frod_out <<\ENDSNIP
Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection.
ENDSNIP

snip_analyze_suppress0102() {
istioctl analyze -k --namespace frod --suppress "IST0102=Namespace frod"
}

! read -r -d '' snip_analyze_suppress0102_out <<\ENDSNIP
✔ No validation issues found when analyzing namespace: frod.
ENDSNIP

snip_analyze_suppress_frod_0107_baz() {
# Suppress code IST0102 on namespace frod and IST0107 on all pods in namespace baz
istioctl analyze -k --all-namespaces --suppress "IST0102=Namespace frod" --suppress "IST0107=Pod *.baz"
}

snip_annotate_for_deployment_suppression() {
kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107
}

snip_annotate_for_deployment_suppression_107() {
kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress=IST0107,IST0002
}
