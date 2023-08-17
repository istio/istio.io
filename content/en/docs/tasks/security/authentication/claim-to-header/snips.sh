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
#          docs/tasks/security/authentication/claim-to-header/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n foo
kubectl apply -f samples/sleep/sleep.yaml -n foo
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
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.19/security/tools/jwt/samples/jwks.json"
    outputClaimToHeaders:
    - header: "x-jwt-claim-foo"
      claim: "foo"
EOF
}

snip_allow_requests_with_valid_jwt_and_listtyped_claims_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_2_out <<\ENDSNIP
401
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_3() {
TOKEN=$(curl https://raw.githubusercontent.com/istio/istio/release-1.19/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_3_out <<\ENDSNIP
{"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_4() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_4_out <<\ENDSNIP
200
ENDSNIP

snip_allow_requests_with_valid_jwt_and_listtyped_claims_5() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | grep "X-Jwt-Claim-Foo" | sed -e 's/^[ \t]*//'
}

! read -r -d '' snip_allow_requests_with_valid_jwt_and_listtyped_claims_5_out <<\ENDSNIP
"X-Jwt-Claim-Foo": "bar"
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}
