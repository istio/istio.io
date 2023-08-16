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
#          docs/tasks/traffic-management/request-routing/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-gamma-support.sh"

snip_route_to_version_1_1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
}

snip_route_to_version_1_2() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
}

snip_route_to_version_1_3() {
kubectl get virtualservices -o yaml
}

! read -r -d '' snip_route_to_version_1_3_out <<\ENDSNIP
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - details
    http:
    - route:
      - destination:
          host: details
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - productpage
    http:
    - route:
      - destination:
          host: productpage
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - ratings
    http:
    - route:
      - destination:
          host: ratings
          subset: v1
- apiVersion: networking.istio.io/v1beta1
  kind: VirtualService
  ...
  spec:
    hosts:
    - reviews
    http:
    - route:
      - destination:
          host: reviews
          subset: v1
ENDSNIP

snip_route_to_version_1_4() {
kubectl get destinationrules -o yaml
}

snip_route_to_version_1_5() {
kubectl get httproute reviews -o yaml
}

! read -r -d '' snip_route_to_version_1_5_out <<\ENDSNIP
...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: Route was valid
      observedGeneration: 8
      reason: Accepted
      status: "True"
      type: Accepted
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: All references resolved
      observedGeneration: 8
      reason: ResolvedRefs
      status: "True"
      type: ResolvedRefs
    controllerName: istio.io/gateway-controller
    parentRef:
      group: gateway.networking.k8s.io
      kind: Service
      name: reviews
      port: 9080
ENDSNIP

snip_route_based_on_user_identity_1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
}

snip_route_based_on_user_identity_2() {
kubectl get virtualservice reviews -o yaml
}

! read -r -d '' snip_route_based_on_user_identity_2_out <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
ENDSNIP

snip_route_based_on_user_identity_3() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
}

snip_cleanup_1() {
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
}

snip_cleanup_2() {
kubectl delete httproute reviews
}
