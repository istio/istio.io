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
#          docs/ambient/usage/extend-waypoint-wasm/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_get_gateway() {
kubectl get gateway
}

! IFS=$'\n' read -r -d '' snip_get_gateway_out <<\ENDSNIP
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
ENDSNIP

snip_apply_wasmplugin_gateway() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway # gateway name retrieved from previous step
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

snip_test_gateway_productpage_without_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
}

! IFS=$'\n' read -r -d '' snip_test_gateway_productpage_without_credentials_out <<\ENDSNIP
401
ENDSNIP

snip_test_gateway_productpage_with_credentials() {
kubectl exec deploy/sleep -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
}

! IFS=$'\n' read -r -d '' snip_test_gateway_productpage_with_credentials_out <<\ENDSNIP
200
ENDSNIP

snip_create_waypoint() {
istioctl waypoint apply --enroll-namespace --wait
}

snip_verify_traffic() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_out <<\ENDSNIP
200
ENDSNIP

snip_get_gateway_waypoint() {
kubectl get gateway
}

! IFS=$'\n' read -r -d '' snip_get_gateway_waypoint_out <<\ENDSNIP
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
ENDSNIP

snip_apply_wasmplugin_waypoint_all() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint # gateway name retrieved from previous step
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

snip_get_wasmplugin() {
kubectl get wasmplugin
}

! IFS=$'\n' read -r -d '' snip_get_wasmplugin_out <<\ENDSNIP
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
ENDSNIP

snip_test_waypoint_productpage_without_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_productpage_without_credentials_out <<\ENDSNIP
401
ENDSNIP

snip_test_waypoint_productpage_with_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_productpage_with_credentials_out <<\ENDSNIP
200
ENDSNIP

snip_apply_wasmplugin_waypoint_service() {
kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/reviews"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "MXQtaW4zOmFkbWluMw=="
EOF
}

snip_test_waypoint_service_productpage_with_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_service_productpage_with_credentials_out <<\ENDSNIP
200
ENDSNIP

snip_test_waypoint_service_reviews_with_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_service_reviews_with_credentials_out <<\ENDSNIP
200
ENDSNIP

snip_test_waypoint_service_reviews_without_credentials() {
kubectl exec deploy/sleep -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
}

! IFS=$'\n' read -r -d '' snip_test_waypoint_service_reviews_without_credentials_out <<\ENDSNIP
401
ENDSNIP

snip_remove_wasmplugin() {
kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
}
