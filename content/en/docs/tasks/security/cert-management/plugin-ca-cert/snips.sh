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
#          docs/tasks/security/cert-management/plugin-ca-cert/index.md
####################################################################################################

snip_plugging_in_existing_certificates_and_key_1() {
kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system --from-file=samples/certs/ca-cert.pem \
    --from-file=samples/certs/ca-key.pem --from-file=samples/certs/root-cert.pem \
    --from-file=samples/certs/cert-chain.pem
}

snip_plugging_in_existing_certificates_and_key_2() {
istioctl install --set profile=demo
}

snip_deploying_example_services_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
}

snip_deploying_example_services_2() {
kubectl apply -n foo -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_verifying_the_certificates_1() {
sleep 20; kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -showcerts -connect httpbin.foo:8000 > httpbin-proxy-cert.txt
}

snip_verifying_the_certificates_2() {
sed -n '/-----BEGIN CERTIFICATE-----/{:start /-----END CERTIFICATE-----/!{N;b start};/.*/p}' httpbin-proxy-cert.txt > certs.pem
awk 'BEGIN {counter=0;} /BEGIN CERT/{counter++} { print > "proxy-cert-" counter ".pem"}' < certs.pem
}

snip_verifying_the_certificates_3() {
openssl x509 -in samples/certs/root-cert.pem -text -noout > /tmp/root-cert.crt.txt
openssl x509 -in ./proxy-cert-3.pem -text -noout > /tmp/pod-root-cert.crt.txt
diff -s /tmp/root-cert.crt.txt /tmp/pod-root-cert.crt.txt
}

! read -r -d '' snip_verifying_the_certificates_3_out <<\ENDSNIP
Files /tmp/root-cert.crt.txt and /tmp/pod-root-cert.crt.txt are identical
ENDSNIP

snip_verifying_the_certificates_4() {
openssl x509 -in samples/certs/ca-cert.pem -text -noout > /tmp/ca-cert.crt.txt
openssl x509 -in ./proxy-cert-2.pem -text -noout > /tmp/pod-cert-chain-ca.crt.txt
diff -s /tmp/ca-cert.crt.txt /tmp/pod-cert-chain-ca.crt.txt
}

! read -r -d '' snip_verifying_the_certificates_4_out <<\ENDSNIP
Files /tmp/ca-cert.crt.txt and /tmp/pod-cert-chain-ca.crt.txt are identical
ENDSNIP

snip_verifying_the_certificates_5() {
openssl verify -CAfile <(cat samples/certs/ca-cert.pem samples/certs/root-cert.pem) ./proxy-cert-1.pem
}

! read -r -d '' snip_verifying_the_certificates_5_out <<\ENDSNIP
./proxy-cert-1.pem: OK
ENDSNIP

snip_cleanup_1() {
kubectl delete secret cacerts -n istio-system
kubectl delete ns foo istio-system
}
