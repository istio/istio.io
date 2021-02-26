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
#          docs/tasks/security/authorization/authz-ingress/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin-gateway.yaml) -n foo
}

snip_before_you_begin_2() {
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
}

snip_before_you_begin_3() {
curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_3_out <<\ENDSNIP
200
ENDSNIP

snip_before_you_begin_4() {
CLIENT_IP=$(curl "$INGRESS_HOST":"$INGRESS_PORT"/ip -s | grep "origin" | cut -d'"' -f 4) && echo "$CLIENT_IP"
}

! read -r -d '' snip_before_you_begin_4_out <<\ENDSNIP
105.133.10.12
ENDSNIP

snip_ipbased_allow_list_and_deny_list_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
       ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
}

snip_ipbased_allow_list_and_deny_list_2() {
curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_2_out <<\ENDSNIP
403
ENDSNIP

snip_ipbased_allow_list_and_deny_list_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
       ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_4() {
curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_4_out <<\ENDSNIP
200
ENDSNIP

snip_ipbased_allow_list_and_deny_list_5() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - from:
    - source:
       ipBlocks: ["$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_6() {
curl "$INGRESS_HOST":"$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_6_out <<\ENDSNIP
403
ENDSNIP

snip_clean_up_1() {
kubectl delete namespace foo
}

snip_clean_up_2() {
kubectl delete authorizationpolicy ingress-policy -n istio-system
}
