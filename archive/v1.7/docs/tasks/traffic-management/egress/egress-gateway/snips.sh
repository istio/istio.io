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
source "content/en/boilerplates/snips/before-you-begin-egress.sh"

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
kubectl exec "$SOURCE_POD" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
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

snip_egress_gateway_for_http_traffic_5() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_http_traffic_5_out <<\ENDSNIP
...
HTTP/1.1 301 Moved Permanently
...
location: https://edition.cnn.com/politics
...

HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_http_traffic_6() {
kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
}

! read -r -d '' snip_egress_gateway_for_http_traffic_7 <<\ENDSNIP
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
ENDSNIP

snip_cleanup_http_gateway_1() {
kubectl delete gateway istio-egressgateway
kubectl delete serviceentry cnn
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule egressgateway-for-cnn
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
kubectl exec "$SOURCE_POD" -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
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
kubectl exec "$SOURCE_POD" -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
}

! read -r -d '' snip_egress_gateway_for_https_traffic_4_out <<\ENDSNIP
...
HTTP/2 200
Content-Type: text/html; charset=utf-8
...
ENDSNIP

snip_egress_gateway_for_https_traffic_5() {
kubectl logs -l istio=egressgateway -n istio-system
}

! read -r -d '' snip_egress_gateway_for_https_traffic_6 <<\ENDSNIP
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
ENDSNIP

snip_cleanup_https_gateway_1() {
kubectl delete serviceentry cnn
kubectl delete gateway istio-egressgateway
kubectl delete virtualservice direct-cnn-through-egress-gateway
kubectl delete destinationrule egressgateway-for-cnn
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
kubectl label ns kube-system kube-system=true
}

snip_apply_kubernetes_network_policies_7() {
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

snip_apply_kubernetes_network_policies_8() {
kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -v https://edition.cnn.com/politics
}

! read -r -d '' snip_apply_kubernetes_network_policies_8_out <<\ENDSNIP
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

snip_apply_kubernetes_network_policies_9() {
kubectl label namespace test-egress istio-injection=enabled
}

snip_apply_kubernetes_network_policies_10() {
kubectl delete deployment sleep -n test-egress
kubectl apply -f samples/sleep/sleep.yaml -n test-egress
}

snip_apply_kubernetes_network_policies_11() {
kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
}

! read -r -d '' snip_apply_kubernetes_network_policies_11_out <<\ENDSNIP
sleep istio-proxy
ENDSNIP

snip_apply_kubernetes_network_policies_12() {
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

snip_apply_kubernetes_network_policies_13() {
kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
}

! read -r -d '' snip_apply_kubernetes_network_policies_13_out <<\ENDSNIP
200
ENDSNIP

snip_apply_kubernetes_network_policies_14() {
kubectl logs -l istio=egressgateway -n istio-system
}

! read -r -d '' snip_apply_kubernetes_network_policies_15 <<\ENDSNIP
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
ENDSNIP

snip_cleanup_network_policies_1() {
kubectl delete -f samples/sleep/sleep.yaml -n test-egress
kubectl delete destinationrule egressgateway-for-cnn -n test-egress
kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
kubectl label namespace kube-system kube-system-
kubectl label namespace istio-system istio-
kubectl delete namespace test-egress
}

snip_troubleshooting_1() {
kubectl exec -i -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')"  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
}

! read -r -d '' snip_troubleshooting_1_out <<\ENDSNIP
        X509v3 Subject Alternative Name:
            URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
ENDSNIP

snip_troubleshooting_2() {
kubectl exec "$SOURCE_POD" -c sleep -- openssl s_client -connect edition.cnn.com:443 -servername edition.cnn.com
}

! read -r -d '' snip_troubleshooting_2_out <<\ENDSNIP
CONNECTED(00000003)
...
Certificate chain
 0 s:/C=US/ST=California/L=San Francisco/O=Fastly, Inc./CN=turner-tls.map.fastly.net
   i:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
 1 s:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
   i:/C=BE/O=GlobalSign nv-sa/OU=Root CA/CN=GlobalSign Root CA
 ---
 Server certificate
 -----BEGIN CERTIFICATE-----
...
ENDSNIP

snip_troubleshooting_3() {
kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET stats | grep edition.cnn.com.upstream_cx_total
}

! read -r -d '' snip_troubleshooting_3_out <<\ENDSNIP
cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}
