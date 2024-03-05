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
#          docs/tasks/traffic-management/egress/egress-gateway/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-gamma-support.sh"

snip_before_you_begin_1() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_2() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
}

! read -r -d '' snip_before_you_begin_3 <<\ENDSNIP
$ istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
ENDSNIP

snip_deploy_istio_egress_gateway_1() {
kubectl get pod -l istio=egressgateway -n istio-system
}

! read -r -d '' snip_deploy_istio_egress_gateway_2 <<\ENDSNIP
spec:
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
ENDSNIP

snip_egress_gateway_for_http_traffic_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: cnn
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 80
    name: http-port
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
EOF
}

snip_egress_gateway_for_http_traffic_2() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_http_traffic_2_out <<\ENDSNIP
...
HTTP/1.1 301 Moved Permanently
...
location: https://edition.cnn.com/politics
...

HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_http_traffic_3() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
}

snip_egress_gateway_for_http_traffic_4() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
}

snip_egress_gateway_for_http_traffic_5() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
EOF
}

snip_egress_gateway_for_http_traffic_6() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
}

snip_egress_gateway_for_http_traffic_7() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_http_traffic_7_out <<\ENDSNIP
...
HTTP/1.1 301 Moved Permanently
...
location: https://edition.cnn.com/politics
...

HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_http_traffic_8() {
kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
}

! read -r -d '' snip_egress_gateway_for_http_traffic_9 <<\ENDSNIP
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
ENDSNIP

snip_egress_gateway_for_http_traffic_10() {
istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
}

! read -r -d '' snip_egress_gateway_for_http_traffic_10_out <<\ENDSNIP
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
ENDSNIP

snip_egress_gateway_for_http_traffic_11() {
kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
}

! read -r -d '' snip_egress_gateway_for_http_traffic_12 <<\ENDSNIP
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
ENDSNIP

snip_egress_gateway_for_http_traffic_13() {
istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
}

! read -r -d '' snip_egress_gateway_for_http_traffic_13_out <<\ENDSNIP
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
ENDSNIP

snip_cleanup_http_gateway_1() {
kubectl delete serviceentry cnn
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule egressgateway-for-cnn
}

snip_cleanup_http_gateway_2() {
kubectl delete serviceentry cnn
kubectl delete gtw cnn-egress-gateway
kubectl delete httproute direct-cnn-to-egress-gateway
kubectl delete httproute forward-cnn-from-egress-gateway
}

snip_egress_gateway_for_https_traffic_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: cnn
spec:
  hosts:
  - edition.cnn.com
  ports:
  - number: 443
    name: tls
    protocol: TLS
  resolution: DNS
EOF
}

snip_egress_gateway_for_https_traffic_2() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_https_traffic_2_out <<\ENDSNIP
...
HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_https_traffic_3() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF
}

snip_egress_gateway_for_https_traffic_4() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
}

snip_egress_gateway_for_https_traffic_5() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_https_traffic_5_out <<\ENDSNIP
...
HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_https_traffic_6() {
kubectl logs -l istio=egressgateway -n istio-system
}

! read -r -d '' snip_egress_gateway_for_https_traffic_7 <<\ENDSNIP
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
ENDSNIP

snip_egress_gateway_for_https_traffic_8() {
kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
}

! read -r -d '' snip_egress_gateway_for_https_traffic_9 <<\ENDSNIP
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
ENDSNIP

snip_cleanup_https_gateway_1() {
kubectl delete serviceentry cnn
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule egressgateway-for-cnn
}

snip_cleanup_https_gateway_2() {
kubectl delete serviceentry cnn
kubectl delete gtw cnn-egress-gateway
kubectl delete tlsroute direct-cnn-to-egress-gateway
kubectl delete tlsroute forward-cnn-from-egress-gateway
}

snip_apply_kubernetes_network_policies_1() {
kubectl create namespace test-egress
}

snip_apply_kubernetes_network_policies_2() {
kubectl apply -n test-egress -f samples/sleep/sleep.yaml
}

snip_apply_kubernetes_network_policies_3() {
kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress
}

! read -r -d '' snip_apply_kubernetes_network_policies_3_out <<\ENDSNIP
NAME                     READY     STATUS    RESTARTS   AGE
sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
ENDSNIP

snip_apply_kubernetes_network_policies_4() {
kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
}

! read -r -d '' snip_apply_kubernetes_network_policies_4_out <<\ENDSNIP
200
ENDSNIP

snip_apply_kubernetes_network_policies_5() {
kubectl label namespace istio-system istio=system
}

snip_apply_kubernetes_network_policies_6() {
kubectl label namespace istio-system istio=system
kubectl label namespace default gateway=true
}

snip_apply_kubernetes_network_policies_7() {
kubectl label ns kube-system kube-system=true
}

snip_apply_kubernetes_network_policies_8() {
cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
EOF
}

snip_apply_kubernetes_network_policies_9() {
cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
}

snip_apply_kubernetes_network_policies_10() {
kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -v -sS https://edition.cnn.com/politics
}

! read -r -d '' snip_apply_kubernetes_network_policies_10_out <<\ENDSNIP
Hostname was NOT found in DNS cache
  Trying 151.101.65.67...
  Trying 2a04:4e42:200::323...
Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
  Trying 2a04:4e42:400::323...
Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
  Trying 2a04:4e42:600::323...
Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
  Trying 2a04:4e42::323...
Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
connect to 151.101.65.67 port 443 failed: Connection timed out
ENDSNIP

snip_apply_kubernetes_network_policies_11() {
kubectl label namespace test-egress istio-injection=enabled
}

snip_apply_kubernetes_network_policies_12() {
kubectl delete deployment sleep -n test-egress
kubectl apply -f samples/sleep/sleep.yaml -n test-egress
}

snip_apply_kubernetes_network_policies_13() {
kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
}

! read -r -d '' snip_apply_kubernetes_network_policies_13_out <<\ENDSNIP
sleep istio-proxy
ENDSNIP

snip_apply_kubernetes_network_policies_14() {
kubectl apply -n test-egress -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
}

snip_apply_kubernetes_network_policies_15() {
kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
}

! read -r -d '' snip_apply_kubernetes_network_policies_15_out <<\ENDSNIP
sleep istio-proxy
ENDSNIP

snip_apply_kubernetes_network_policies_16() {
kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -sS -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
}

! read -r -d '' snip_apply_kubernetes_network_policies_16_out <<\ENDSNIP
200
ENDSNIP

snip_apply_kubernetes_network_policies_17() {
kubectl logs -l istio=egressgateway -n istio-system
}

! read -r -d '' snip_apply_kubernetes_network_policies_18 <<\ENDSNIP
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
ENDSNIP

snip_apply_kubernetes_network_policies_19() {
kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
}

! read -r -d '' snip_apply_kubernetes_network_policies_20 <<\ENDSNIP
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504837 46 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
ENDSNIP

snip_cleanup_network_policies_1() {
kubectl delete -f samples/sleep/sleep.yaml -n test-egress
kubectl delete destinationrule egressgateway-for-cnn -n test-egress
kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
kubectl label namespace kube-system kube-system-
kubectl label namespace istio-system istio-
kubectl delete namespace test-egress
}

snip_cleanup_network_policies_2() {
kubectl delete -f samples/sleep/sleep.yaml -n test-egress
kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
kubectl label namespace kube-system kube-system-
kubectl label namespace istio-system istio-
kubectl label namespace default gateway-
kubectl delete namespace test-egress
}

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}
