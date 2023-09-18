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
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_before_you_begin_1() {
kubectl create ns foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -f samples/httpbin/httpbin.yaml -n foo
}

snip_before_you_begin_2() {
kubectl apply -f samples/httpbin/httpbin-gateway.yaml -n foo
}

snip_before_you_begin_3() {
kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n istio-system --level rbac:debug; done
}

snip_before_you_begin_4() {
kubectl apply -f samples/httpbin/gateway-api/httpbin-gateway.yaml -n foo
kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
}

snip_before_you_begin_5() {
kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do istioctl proxy-config log "$pod" -n foo --level rbac:debug; done
}

snip_before_you_begin_6() {
export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
}

snip_before_you_begin_7() {
curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_before_you_begin_7_out <<\ENDSNIP
200
ENDSNIP

! read -r -d '' snip_source_ip_address_of_the_original_client_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
  components:
    ingressGateways:
    - enabled: true
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
ENDSNIP

! read -r -d '' snip_source_ip_address_of_the_original_client_2 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  gatewayClassName: istio
  ...
ENDSNIP

! read -r -d '' snip_tcpudp_proxy_load_balancer_1 <<\ENDSNIP
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER_FILTER
    patch:
      operation: INSERT_FIRST
      value:
        name: proxy_protocol
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
  workloadSelector:
    labels:
      istio: ingressgateway
ENDSNIP

! read -r -d '' snip_tcpudp_proxy_load_balancer_2 <<\ENDSNIP
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: foo
spec:
  configPatches:
  - applyTo: LISTENER_FILTER
    patch:
      operation: INSERT_FIRST
      value:
        name: proxy_protocol
        typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.listener.proxy_protocol.v3.ProxyProtocol"
  workloadSelector:
    labels:
      istio.io/gateway-name: httpbin-gateway
ENDSNIP

! read -r -d '' snip_tcpudp_proxy_load_balancer_3 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
  components:
    ingressGateways:
    - enabled: true
      name: istio-ingressgateway
      k8s:
        hpaSpec:
          maxReplicas: 10
          minReplicas: 5
        serviceAnnotations:
          service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
        ...
ENDSNIP

! read -r -d '' snip_tcpudp_proxy_load_balancer_4 <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
spec:
  gatewayClassName: istio
  ...
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: httpbin-gateway
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: httpbin-gateway-istio
  minReplicas: 5
  maxReplicas: 10
ENDSNIP

snip_network_load_balancer_1() {
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec":{"externalTrafficPolicy":"Local"}}'
}

snip_network_load_balancer_2() {
kubectl patch svc httpbin-gateway-istio -n foo -p '{"spec":{"externalTrafficPolicy":"Local"}}'
}

! read -r -d '' snip_httphttps_load_balancer_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogEncoding: JSON
    accessLogFile: /dev/stdout
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: 1
ENDSNIP

snip_ipbased_allow_list_and_deny_list_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
}

snip_ipbased_allow_list_and_deny_list_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
}

snip_ipbased_allow_list_and_deny_list_4() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24"]
EOF
}

snip_ipbased_allow_list_and_deny_list_5() {
curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_5_out <<\ENDSNIP
403
ENDSNIP

snip_ipbased_allow_list_and_deny_list_6() {
CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_6_out <<\ENDSNIP
192.168.10.15
ENDSNIP

snip_ipbased_allow_list_and_deny_list_7() {
CLIENT_IP=$(kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_7_out <<\ENDSNIP
192.168.10.15
ENDSNIP

snip_ipbased_allow_list_and_deny_list_8() {
CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $3}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_8_out <<\ENDSNIP
192.168.10.15
ENDSNIP

snip_ipbased_allow_list_and_deny_list_9() {
CLIENT_IP=$(kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo | grep remoteIP; done | tail -1 | awk -F, '{print $4}' | awk -F: '{print $2}' | sed 's/ //') && echo "$CLIENT_IP"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_9_out <<\ENDSNIP
192.168.10.15
ENDSNIP

snip_ipbased_allow_list_and_deny_list_10() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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

snip_ipbased_allow_list_and_deny_list_11() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_12() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        ipBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_13() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: ALLOW
  rules:
  - from:
    - source:
        remoteIpBlocks: ["1.2.3.4", "5.6.7.0/24", "$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_14() {
curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_14_out <<\ENDSNIP
200
ENDSNIP

snip_ipbased_allow_list_and_deny_list_15() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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

snip_ipbased_allow_list_and_deny_list_16() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
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
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_17() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        ipBlocks: ["$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_18() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-policy
  namespace: foo
spec:
  selector:
    matchLabels:
      istio.io/gateway-name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        remoteIpBlocks: ["$CLIENT_IP"]
EOF
}

snip_ipbased_allow_list_and_deny_list_19() {
curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_ipbased_allow_list_and_deny_list_19_out <<\ENDSNIP
403
ENDSNIP

snip_ipbased_allow_list_and_deny_list_20() {
kubectl get pods -n istio-system -o name -l istio=ingressgateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n istio-system; done
}

snip_ipbased_allow_list_and_deny_list_21() {
kubectl get pods -n foo -o name -l istio.io/gateway-name=httpbin-gateway | sed 's|pod/||' | while read -r pod; do kubectl logs "$pod" -n foo; done
}

snip_clean_up_1() {
kubectl delete authorizationpolicy ingress-policy -n istio-system
}

snip_clean_up_2() {
kubectl delete authorizationpolicy ingress-policy -n foo
}

snip_clean_up_3() {
kubectl delete namespace foo
}
