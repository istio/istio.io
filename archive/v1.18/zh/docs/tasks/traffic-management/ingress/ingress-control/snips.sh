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
#          docs/tasks/traffic-management/ingress/ingress-control/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_before_you_begin_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=minimal
}

snip_before_you_begin_2() {
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_configuring_ingress_using_a_gateway_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # The selector matches the ingress gateway pod labels.
  # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
}

snip_configuring_ingress_using_a_gateway_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
}

snip_configuring_ingress_using_a_gateway_3() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "httpbin.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
}

snip_configuring_ingress_using_a_gateway_4() {
kubectl wait --for=condition=programmed gtw httpbin-gateway
}

snip_configuring_ingress_using_a_gateway_5() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
}

snip_minikube_tunnel() {
minikube tunnel
}

snip_determining_the_ingress_ip_and_ports_2() {
export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system
}

snip_determining_the_ingress_ip_and_ports_3() {
export INGRESS_NAME=istio-ingress
export INGRESS_NS=istio-ingress
}

snip_determining_the_ingress_ip_and_ports_4() {
kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_4_out <<\ENDSNIP
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
ENDSNIP

snip_determining_the_ingress_ip_and_ports_5() {
export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
}

snip_determining_the_ingress_ip_and_ports_6() {
export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}

snip_determining_the_ingress_ip_and_ports_7() {
export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
}

snip_determining_the_ingress_ip_and_ports_8() {
export INGRESS_HOST=$(kubectl get gtw my-gateway -o jsonpath='{.status.addresses[0].value}')
export SECURE_INGRESS_PORT=$(kubectl get gtw my-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
}

snip_accessing_ingress_services_1() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
}

! read -r -d '' snip_accessing_ingress_services_1_out <<\ENDSNIP
HTTP/1.1 200 OK
server: istio-envoy
...
ENDSNIP

snip_accessing_ingress_services_2() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

! read -r -d '' snip_accessing_ingress_services_2_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP

snip_accessing_ingress_services_using_a_browser_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  # The selector matches the ingress gateway pod labels.
  # If you installed Istio using Helm following the standard documentation, this would be "istio=ingress"
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
}

snip_accessing_ingress_services_using_a_browser_2() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /headers
    backendRefs:
    - name: httpbin
      port: 8000
EOF
}

snip_using_node_ports_of_the_ingress_gateway_service_1() {
export INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export TCP_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
}

snip_using_node_ports_of_the_ingress_gateway_service_2() {
export INGRESS_HOST=worker-node-address
}

snip_using_node_ports_of_the_ingress_gateway_service_3() {
gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
}

snip_using_node_ports_of_the_ingress_gateway_service_4() {
ibmcloud ks workers --cluster cluster-name-or-id
export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
}

snip_using_node_ports_of_the_ingress_gateway_service_5() {
export INGRESS_HOST=127.0.0.1
}

snip_using_node_ports_of_the_ingress_gateway_service_6() {
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n "${INGRESS_NS}" -o jsonpath='{.items[0].status.hostIP}')
}

snip_troubleshooting_1() {
kubectl get svc -n istio-system
echo "INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT"
}

snip_troubleshooting_2() {
kubectl get gateway --all-namespaces
}

snip_troubleshooting_3() {
kubectl get ingress --all-namespaces
}

snip_cleanup_1() {
kubectl delete gateway httpbin-gateway
kubectl delete virtualservice httpbin
kubectl delete --ignore-not-found=true -f samples/httpbin/httpbin.yaml
}

snip_cleanup_2() {
kubectl delete gtw httpbin-gateway
kubectl delete httproute httpbin
kubectl delete --ignore-not-found=true -f samples/httpbin/httpbin.yaml
}
