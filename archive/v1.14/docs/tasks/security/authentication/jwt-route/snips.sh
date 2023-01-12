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
#          docs/tasks/security/authentication/jwt-route/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin-gateway.yaml) -n foo
}

snip_before_you_begin_2() {
curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
200
ENDSNIP

snip_configuring_ingress_routing_based_on_jwt_claims_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: ingress-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.14/security/tools/jwt/samples/jwks.json"
EOF
}

snip_configuring_ingress_routing_based_on_jwt_claims_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: foo
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
      headers:
        "@request.auth.claims.groups":
          exact: group1
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
}

snip_validating_ingress_routing_based_on_jwt_claims_1() {
curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_1_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP

snip_validating_ingress_routing_based_on_jwt_claims_2() {
curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer some.invalid.token"
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_2_out <<\ENDSNIP
HTTP/1.1 401 Unauthorized
...
ENDSNIP

snip_validating_ingress_routing_based_on_jwt_claims_3() {
TOKEN_GROUP=$(curl https://raw.githubusercontent.com/istio/istio/release-1.14/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode -
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_3_out <<\ENDSNIP
{"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
ENDSNIP

snip_validating_ingress_routing_based_on_jwt_claims_4() {
curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_GROUP"
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_4_out <<\ENDSNIP
HTTP/1.1 200 OK
...
ENDSNIP

snip_validating_ingress_routing_based_on_jwt_claims_5() {
TOKEN_NO_GROUP=$(curl https://raw.githubusercontent.com/istio/istio/release-1.14/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN_NO_GROUP" | cut -d '.' -f2 - | base64 --decode -
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_5_out <<\ENDSNIP
{"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
ENDSNIP

snip_validating_ingress_routing_based_on_jwt_claims_6() {
curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_NO_GROUP"
}

! read -r -d '' snip_validating_ingress_routing_based_on_jwt_claims_6_out <<\ENDSNIP
HTTP/1.1 404 Not Found
...
ENDSNIP

snip_cleanup_1() {
kubectl delete namespace foo
}

snip_cleanup_2() {
kubectl delete requestauthentication ingress-jwt -n istio-system
}
