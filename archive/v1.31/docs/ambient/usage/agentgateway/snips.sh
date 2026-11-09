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
#          docs/ambient/usage/agentgateway/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-install-crds.sh"
source "content/en/boilerplates/snips/gateway-api-remove-crds.sh"

snip_install_istio() {
istioctl install --set profile=ambient --set values.pilot.env.PILOT_ENABLE_AGENTGATEWAY=true -y
}

snip_verify_gateway_classes() {
kubectl get gatewayclass istio-agentgateway istio-agentgateway-waypoint
}

! IFS=$'\n' read -r -d '' snip_verify_gateway_classes_out <<\ENDSNIP
NAME                          CONTROLLER                                  ACCEPTED   AGE
istio-agentgateway            istio.io/agentgateway-controller            True       30s
istio-agentgateway-waypoint   istio.io/agentgateway-waypoint-controller   True       30s
ENDSNIP

snip_deploy_bookinfo() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

snip_deploy_ingress_gateway() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bookinfo-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio-agentgateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
}

snip_deploy_ingress_route() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bookinfo
spec:
  parentRefs:
  - name: bookinfo-gateway
  rules:
  - matches:
    - path:
        type: Exact
        value: /productpage
    - path:
        type: PathPrefix
        value: /static
    - path:
        type: Exact
        value: /login
    - path:
        type: PathPrefix
        value: /api/v1/products
    backendRefs:
    - name: productpage
      port: 9080
EOF
}

snip_verify_ingress_gateway() {
kubectl get gateway bookinfo-gateway
}

! IFS=$'\n' read -r -d '' snip_verify_ingress_gateway_out <<\ENDSNIP
NAME               CLASS                ADDRESS                                      PROGRAMMED   AGE
bookinfo-gateway   istio-agentgateway   bookinfo-gateway.default.svc.cluster.local   True         30s
ENDSNIP

snip_label_ambient() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

! IFS=$'\n' read -r -d '' snip_label_ambient_out <<\ENDSNIP
namespace/default labeled
ENDSNIP

snip_deploy_waypoint() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: agentgateway-waypoint
  labels:
    istio.io/waypoint-for: service
spec:
  gatewayClassName: istio-agentgateway-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
}

snip_verify_waypoint() {
kubectl get gateway agentgateway-waypoint
}

! IFS=$'\n' read -r -d '' snip_verify_waypoint_out <<\ENDSNIP
NAME                    CLASS                         ADDRESS        PROGRAMMED   AGE
agentgateway-waypoint   istio-agentgateway-waypoint   10.96.15.112   True         30s
ENDSNIP

snip_enroll_waypoint() {
kubectl label service reviews istio.io/use-waypoint=agentgateway-waypoint
}

! IFS=$'\n' read -r -d '' snip_enroll_waypoint_out <<\ENDSNIP
service/reviews labeled
ENDSNIP

! IFS=$'\n' read -r -d '' snip_configure_agentgateway_as_a_waypoint_5 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1
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
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
ENDSNIP

snip_cleanup_ingress() {
kubectl delete httproute bookinfo
kubectl delete gateway bookinfo-gateway
}

snip_cleanup_waypoint() {
kubectl label service reviews istio.io/use-waypoint-
kubectl delete gateway agentgateway-waypoint
}

snip_cleanup_bookinfo() {
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl label namespace default istio.io/dataplane-mode-
}

snip_uninstall_istio() {
istioctl uninstall --purge -y
kubectl delete namespace istio-system
}
