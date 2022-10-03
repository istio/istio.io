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
#          docs/examples/microservices-istio/istio-ingress-gateway/index.md
####################################################################################################

snip__1() {
export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")
echo "$NAMESPACE"
}

! read -r -d '' snip__1_out <<\ENDSNIP
tutorial
ENDSNIP

snip__2() {
export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com
echo "$MY_INGRESS_GATEWAY_HOST"
}

! read -r -d '' snip__2_out <<\ENDSNIP
istio.tutorial.bookinfo.com
ENDSNIP

snip__3() {
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - $MY_INGRESS_GATEWAY_HOST
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - $MY_INGRESS_GATEWAY_HOST
  gateways:
  - bookinfo-gateway.$NAMESPACE.svc.cluster.local
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /static
    route:
    - destination:
        host: productpage
        port:
          number: 9080
EOF
}

snip__4() {
echo "$INGRESS_HOST" "$MY_INGRESS_GATEWAY_HOST"
}

snip__5() {
curl -s "$MY_INGRESS_GATEWAY_HOST":"$INGRESS_PORT"/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip__5_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip__6() {
echo http://"$MY_INGRESS_GATEWAY_HOST":"$INGRESS_PORT"/productpage
}

snip__7() {
while :; do curl -s \<output of the previous command\> | grep -o "<title>.*</title>"; sleep 1; done
}

! read -r -d '' snip__7_out <<\ENDSNIP
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
<title>Simple Bookstore App</title>
...
ENDSNIP

snip__8() {
kubectl delete ingress bookinfo -n "$NAMESPACE"
}

! read -r -d '' snip__8_out <<\ENDSNIP
ingress.extensions "bookinfo" deleted
ENDSNIP
