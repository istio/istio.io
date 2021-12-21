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
kubectl get crd gateways.gateway.networking.k8s.io || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" | kubectl apply -f -; }
}

snip_configuring_a_gateway_1() {
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_configuring_a_gateway_2() {
kubectl create namespace istio-ingress
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
  namespace: istio-ingress
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
    namespace: istio-ingress
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
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
kubectl wait -n istio-ingress --for=condition=ready gateways.gateway.networking.k8s.io gateway
export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[*].value}')
}

snip_configuring_a_gateway_4() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
}

! read -r -d '' snip_configuring_a_gateway_4_out <<\ENDSNIP
HTTP/1.1 200 OK
server: istio-envoy
...
ENDSNIP

snip_configuring_a_gateway_5() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
}

! read -r -d '' snip_configuring_a_gateway_5_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP

! read -r -d '' snip_automated_deployment_1 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: 192.0.2.0
    type: IPAddress
...
ENDSNIP

! read -r -d '' snip_manual_deployment_1 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:
  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
...
ENDSNIP

! read -r -d '' snip_mesh_traffic_1 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:
  - kind: Mesh
    name: istio
  hostnames: ["example.com"]
  rules:
  - backendRefs:
    - name: example
      port: 80
ENDSNIP
