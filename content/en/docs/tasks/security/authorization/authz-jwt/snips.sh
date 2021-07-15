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
#          docs/tasks/security/authorization/authz-jwt/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
}

snip_before_you_begin_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
200
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  selector:
    matchLabels:
      app: httpbin
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.11/security/tools/jwt/samples/jwks.json"
EOF
}

snip_allow_requests_with_valid_jwt_and_listtyped_claims_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_2_out <<\ENDSNIP
401
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_3_out <<\ENDSNIP
200
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_4() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: foo
spec:
  selector:
    matchLabels:
      app: httpbin
  action: ALLOW
  rules:
  - from:
    - source:
       requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
EOF
}

snip_allow_requests_with_valid_jwt_and_listtyped_claims_5() {
TOKEN=$(curl https://raw.githubusercontent.com/istio/istio/release-1.11/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_5_out <<\ENDSNIP
{"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_6() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_6_out <<\ENDSNIP
200
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_7() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_7_out <<\ENDSNIP
403
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_8() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: foo
spec:
  selector:
    matchLabels:
      app: httpbin
  action: ALLOW
  rules:
  - from:
    - source:
       requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
    when:
    - key: request.auth.claims[groups]
      values: ["group1"]
EOF
}

snip_allow_requests_with_valid_jwt_and_listtyped_claims_9() {
TOKEN_GROUP=$(curl https://raw.githubusercontent.com/istio/istio/release-1.11/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode -
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_9_out <<\ENDSNIP
{"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_10() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN_GROUP" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_10_out <<\ENDSNIP
200
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_11() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_11_out <<\ENDSNIP
403
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}
