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
#          docs/tasks/extensibility/wasm-module-distribution/index.md
####################################################################################################

snip_configure_wasm_modules_1() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
}

snip_check_the_configured_wasm_module_1() {
curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
}

! read -r -d '' snip_check_the_configured_wasm_module_1_out <<\ENDSNIP
401
ENDSNIP

snip_check_the_configured_wasm_module_2() {
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
}

! read -r -d '' snip_check_the_configured_wasm_module_2_out <<\ENDSNIP
200
ENDSNIP

snip_clean_up_wasm_modules_1() {
kubectl delete wasmplugins.extensions.istio.io -n istio-system basic-auth
}
