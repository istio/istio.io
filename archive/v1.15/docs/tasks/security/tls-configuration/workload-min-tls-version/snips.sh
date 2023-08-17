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
#          docs/tasks/security/tls-configuration/workload-min-tls-version/index.md
####################################################################################################

snip_configuration_of_minimum_tls_version_for_istio_workloads_1() {
cat <<EOF > ./istio.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    meshMTLS:
      minProtocolVersion: TLSV1_3
EOF
istioctl install -f ./istio.yaml
}

snip_check_the_tls_configuration_of_istio_workloads_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
}

snip_check_the_tls_configuration_of_istio_workloads_2() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
}

! read -r -d '' snip_check_the_tls_configuration_of_istio_workloads_2_out <<\ENDSNIP
200
ENDSNIP

snip_check_the_tls_configuration_of_istio_workloads_3() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_3 -connect httpbin.foo:8000 | grep "TLSv1.3"
}

! read -r -d '' snip_check_the_tls_configuration_of_istio_workloads_4 <<\ENDSNIP
TLSv1.3
ENDSNIP

snip_check_the_tls_configuration_of_istio_workloads_5() {
kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c istio-proxy -n foo -- openssl s_client -alpn istio -tls1_2 -connect httpbin.foo:8000 | grep "Cipher is (NONE)"
}

! read -r -d '' snip_check_the_tls_configuration_of_istio_workloads_6 <<\ENDSNIP
Cipher is (NONE)
ENDSNIP

snip_cleanup_1() {
kubectl delete ns foo istio-system
}
