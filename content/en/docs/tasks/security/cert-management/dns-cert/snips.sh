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
#          docs/tasks/security/cert-management/dns-cert/index.md
####################################################################################################

snip_before_you_begin_1() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    certificates:
      - secretName: dns.example1-service-account
        dnsNames: [example1.istio-system.svc, example1.istio-system]
      - secretName: dns.example2-service-account
        dnsNames: [example2.istio-system.svc, example2.istio-system]
EOF
istioctl install -f ./istio.yaml
}

snip_check_the_provisioning_of_dns_certificates_1() {
kubectl get secret dns.example1-service-account -n istio-system -o jsonpath="{.data['cert-chain\.pem']}" | base64 --decode | openssl x509 -in /dev/stdin -text -noout
}

! read -r -d '' snip_check_the_provisioning_of_dns_certificates_2 <<\ENDSNIP
            X509v3 Subject Alternative Name:
                DNS:example1.istio-system.svc, DNS:example1.istio-system
ENDSNIP

snip_regenerating_a_dns_certificate_1() {
kubectl delete secret dns.example1-service-account -n istio-system
}

snip_regenerating_a_dns_certificate_2() {
sleep 10; kubectl get secret dns.example1-service-account -n istio-system -o jsonpath="{.data['cert-chain\.pem']}" | base64 --decode | openssl x509 -in /dev/stdin -text -noout
}

! read -r -d '' snip_regenerating_a_dns_certificate_3 <<\ENDSNIP
            X509v3 Subject Alternative Name:
                DNS:example1.istio-system.svc, DNS:example1.istio-system
ENDSNIP

snip_cleanup_1() {
kubectl delete ns istio-system
}
