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
#          docs/tasks/traffic-management/ingress/secure-ingress/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_before_you_begin_1() {
kubectl apply -f samples/httpbin/httpbin.yaml
}

snip_before_you_begin_2() {
curl --version | grep LibreSSL
}

! read -r -d '' snip_before_you_begin_2_out <<\ENDSNIP
curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
ENDSNIP

snip_generate_client_and_server_certificates_and_keys_1() {
mkdir example_certs1
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs1/example.com.key -out example_certs1/example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_2() {
openssl req -out example_certs1/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 0 -in example_certs1/httpbin.example.com.csr -out example_certs1/httpbin.example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_3() {
mkdir example_certs2
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs2/example.com.key -out example_certs2/example.com.crt
openssl req -out example_certs2/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs2/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
openssl x509 -req -sha256 -days 365 -CA example_certs2/example.com.crt -CAkey example_certs2/example.com.key -set_serial 0 -in example_certs2/httpbin.example.com.csr -out example_certs2/httpbin.example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_4() {
openssl req -out example_certs1/helloworld.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/helloworld.example.com.key -subj "/CN=helloworld.example.com/O=helloworld organization"
openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/helloworld.example.com.csr -out example_certs1/helloworld.example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_5() {
openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
}

snip_generate_client_and_server_certificates_and_keys_6() {
ls example_cert*
}

! read -r -d '' snip_generate_client_and_server_certificates_and_keys_6_out <<\ENDSNIP
example_certs1:
client.example.com.crt          example.com.key                 httpbin.example.com.crt
client.example.com.csr          helloworld.example.com.crt      httpbin.example.com.csr
client.example.com.key          helloworld.example.com.csr      httpbin.example.com.key
example.com.crt                 helloworld.example.com.key

example_certs2:
example.com.crt         httpbin.example.com.crt httpbin.example.com.key
example.com.key         httpbin.example.com.csr
ENDSNIP

snip_configure_a_tls_ingress_gateway_for_a_single_host_1() {
kubectl create -n istio-system secret tls httpbin-credential \
  --key=example_certs1/httpbin.example.com.key \
  --cert=example_certs1/httpbin.example.com.crt
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_2() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - httpbin.example.com
EOF
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_3() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - mygateway
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

snip_configure_a_tls_ingress_gateway_for_a_single_host_4() {
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_5() {
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_6() {
kubectl wait --for=condition=ready gtw mygateway -n istio-system
export INGRESS_HOST=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.status.addresses[*].value}')
export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_7() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_tls_ingress_gateway_for_a_single_host_7_out <<\ENDSNIP
...
HTTP/2 418
...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
ENDSNIP

snip_configure_a_tls_ingress_gateway_for_a_single_host_8() {
kubectl -n istio-system delete secret httpbin-credential
kubectl create -n istio-system secret tls httpbin-credential \
  --key=example_certs2/httpbin.example.com.key \
  --cert=example_certs2/httpbin.example.com.crt
}

snip_configure_a_tls_ingress_gateway_for_a_single_host_9() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs2/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_tls_ingress_gateway_for_a_single_host_9_out <<\ENDSNIP
...
HTTP/2 418
...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
ENDSNIP

snip_configure_a_tls_ingress_gateway_for_a_single_host_10() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_tls_ingress_gateway_for_a_single_host_10_out <<\ENDSNIP
...
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, Server hello (2):
* curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
ENDSNIP

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_1() {
kubectl -n istio-system delete secret httpbin-credential
kubectl create -n istio-system secret tls httpbin-credential \
  --key=example_certs1/httpbin.example.com.key \
  --cert=example_certs1/httpbin.example.com.crt
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_2() {
kubectl apply -f samples/helloworld/helloworld.yaml -l service=helloworld
kubectl apply -f samples/helloworld/helloworld.yaml -l version=v1
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_3() {
kubectl create -n istio-system secret tls helloworld-credential \
  --key=example_certs1/helloworld.example.com.key \
  --cert=example_certs1/helloworld.example.com.crt
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_4() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https-httpbin
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential
    hosts:
    - httpbin.example.com
  - port:
      number: 443
      name: https-helloworld
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: helloworld-credential
    hosts:
    - helloworld.example.com
EOF
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_5() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.example.com
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
EOF
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_6() {
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https-httpbin
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
  - name: https-helloworld
    hostname: "helloworld.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: helloworld-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_7() {
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["helloworld.example.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
}

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_8() {
curl -v -HHost:helloworld.example.com --resolve "helloworld.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs1/example.com.crt "https://helloworld.example.com:$SECURE_INGRESS_PORT/hello"
}

! read -r -d '' snip_configure_a_tls_ingress_gateway_for_multiple_hosts_8_out <<\ENDSNIP
...
HTTP/2 200
...
ENDSNIP

snip_configure_a_tls_ingress_gateway_for_multiple_hosts_9() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_tls_ingress_gateway_for_multiple_hosts_9_out <<\ENDSNIP
...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
ENDSNIP

snip_configure_a_mutual_tls_ingress_gateway_1() {
kubectl -n istio-system delete secret httpbin-credential
kubectl create -n istio-system secret generic httpbin-credential \
  --from-file=tls.key=example_certs1/httpbin.example.com.key \
  --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
  --from-file=ca.crt=example_certs1/example.com.crt
}

snip_configure_a_mutual_tls_ingress_gateway_2() {
cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # use istio default ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL
      credentialName: httpbin-credential # must be the same as secret
    hosts:
    - httpbin.example.com
EOF
}

snip_configure_a_mutual_tls_ingress_gateway_3() {
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
      options:
        gateway.istio.io/tls-terminate-mode: MUTUAL
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
}

snip_configure_a_mutual_tls_ingress_gateway_4() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
--cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_mutual_tls_ingress_gateway_4_out <<\ENDSNIP
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* TLSv1.3 (IN), TLS alert, unknown (628):
* OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
ENDSNIP

snip_configure_a_mutual_tls_ingress_gateway_5() {
curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
  --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
  "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
}

! read -r -d '' snip_configure_a_mutual_tls_ingress_gateway_5_out <<\ENDSNIP
...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
ENDSNIP

snip_troubleshooting_1() {
kubectl get svc -n istio-system
echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
}

snip_troubleshooting_3() {
kubectl -n istio-system get secrets
}

snip_cleanup_1() {
kubectl delete gateway mygateway
kubectl delete virtualservice httpbin helloworld
}

snip_cleanup_2() {
kubectl delete -n istio-system gtw mygateway
kubectl delete httproute httpbin helloworld
}

snip_cleanup_3() {
kubectl delete -n istio-system secret httpbin-credential helloworld-credential
rm -rf ./example_certs1 ./example_certs2
}

snip_cleanup_4() {
kubectl delete -f samples/httpbin/httpbin.yaml
kubectl delete deployment helloworld-v1
kubectl delete service helloworld
}
