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
#          docs/tasks/traffic-management/ingress/kubernetes-ingress/index.md
####################################################################################################

snip_configuring_ingress_using_an_ingress_resource_1() {
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: ingress
spec:
  rules:
  - host: httpbin.example.com
    http:
      paths:
      - path: /status/*
        backend:
          serviceName: httpbin
          servicePort: 8000
EOF
}

snip_configuring_ingress_using_an_ingress_resource_2() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
}

! read -r -d '' snip_configuring_ingress_using_an_ingress_resource_2_out <<\ENDSNIP
HTTP/1.1 200 OK
server: istio-envoy
...
ENDSNIP

snip_configuring_ingress_using_an_ingress_resource_3() {
curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

! read -r -d '' snip_configuring_ingress_using_an_ingress_resource_3_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP

! read -r -d '' snip_specifying_ingressclass_1 <<\ENDSNIP
apiVersion: networking.k8s.io/v1beta1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: ingress
spec:
  ingressClassName: istio
  rules:
  - host: httpbin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          serviceName: httpbin
          servicePort: 8000
ENDSNIP

snip_cleanup_1() {
kubectl delete ingress ingress
kubectl delete --ignore-not-found=true -f samples/httpbin/httpbin.yaml
}
