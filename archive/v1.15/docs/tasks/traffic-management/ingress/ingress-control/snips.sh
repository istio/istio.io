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
source "content/en/boilerplates/snips/start-httpbin-service.sh"

snip_determining_the_ingress_ip_and_ports_1() {
kubectl get svc istio-ingressgateway -n istio-system
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_1_out <<\ENDSNIP
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
ENDSNIP

snip_minikube_tunnel() {
minikube tunnel
}

snip_determining_the_ingress_ip_and_ports_3() {
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
}

snip_determining_the_ingress_ip_and_ports_4() {
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}

snip_determining_the_ingress_ip_and_ports_5() {
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
}

snip_determining_the_ingress_ip_and_ports_6() {
export INGRESS_HOST=worker-node-address
}

snip_determining_the_ingress_ip_and_ports_7() {
gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
}

snip_determining_the_ingress_ip_and_ports_8() {
ibmcloud ks workers --cluster cluster-name-or-id
export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
}

snip_determining_the_ingress_ip_and_ports_9() {
export INGRESS_HOST=127.0.0.1
}

snip_determining_the_ingress_ip_and_ports_10() {
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
}

snip_configuring_ingress_using_an_istio_gateway_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
}

snip_configuring_ingress_using_an_istio_gateway_2() {
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

snip_configuring_ingress_using_an_istio_gateway_3() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
}

! read -r -d '' snip_configuring_ingress_using_an_istio_gateway_3_out <<\ENDSNIP
HTTP/1.1 200 OK
server: istio-envoy
...
ENDSNIP

snip_configuring_ingress_using_an_istio_gateway_4() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

! read -r -d '' snip_configuring_ingress_using_an_istio_gateway_4_out <<\ENDSNIP
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
  selector:
    istio: ingressgateway # use Istio default gateway implementation
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
