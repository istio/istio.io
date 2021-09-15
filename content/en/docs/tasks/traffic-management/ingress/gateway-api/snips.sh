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
#          docs/tasks/traffic-management/ingress/gateway-api/index.md
####################################################################################################

snip_setup_1() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0-rc1" | kubectl apply -f -
}

snip_setup_2() {
istioctl install
}

snip_configuring_a_gateway_1() {
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_configuring_a_gateway_2() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: GatewayClass
metadata:
  name: istio
spec:
  controller: istio.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: default
    hostname: "*.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
metadata:
  name: http
  namespace: default
spec:
  parentRefs:
  - name: gateway
    namespace: istio-system
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: Prefix
        value: /get
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: my-added-header
          value: added-value
    backendRefs:
    - name: httpbin
      port: 8000
EOF
}

snip_configuring_a_gateway_3() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/get"
}

! read -r -d '' snip_configuring_a_gateway_3_out <<\ENDSNIP
HTTP/1.1 200 OK
server: istio-envoy
...
ENDSNIP

snip_configuring_a_gateway_4() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

! read -r -d '' snip_configuring_a_gateway_4_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP
