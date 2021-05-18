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
#          docs/tasks/security/authentication/mtls-migration/index.md
####################################################################################################

snip_set_up_the_cluster_1() {
kubectl create ns foo
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n foo
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n foo
kubectl create ns bar
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml) -n bar
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml) -n bar
}

snip_set_up_the_cluster_2() {
kubectl create ns legacy
kubectl apply -f samples/sleep/sleep.yaml -n legacy
}

snip_set_up_the_cluster_3() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! read -r -d '' snip_set_up_the_cluster_3_out <<\ENDSNIP
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.bar: 200
ENDSNIP

snip_set_up_the_cluster_4() {
kubectl get peerauthentication --all-namespaces
}

! read -r -d '' snip_set_up_the_cluster_4_out <<\ENDSNIP
No resources found
ENDSNIP

snip_set_up_the_cluster_5() {
kubectl get destinationrule --all-namespaces
}

! read -r -d '' snip_set_up_the_cluster_5_out <<\ENDSNIP
No resources found
ENDSNIP

snip_lock_down_to_mutual_tls_by_namespace_1() {
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

snip_lock_down_to_mutual_tls_by_namespace_2() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

! read -r -d '' snip_lock_down_to_mutual_tls_by_namespace_2_out <<\ENDSNIP
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
ENDSNIP

snip_lock_down_to_mutual_tls_by_namespace_3() {
kubectl exec -nfoo "$(kubectl get pod -nfoo -lapp=httpbin -ojsonpath={.items..metadata.name})" -c istio-proxy -- sudo tcpdump dst port 80  -A
}

! read -r -d '' snip_lock_down_to_mutual_tls_by_namespace_3_out <<\ENDSNIP
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
ENDSNIP

snip_lock_down_mutual_tls_for_the_entire_mesh_1() {
kubectl apply -n istio-system -f - <<EOF
apiVersion: "security.istio.io/v1beta1"
kind: "PeerAuthentication"
metadata:
  name: "default"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_lock_down_mutual_tls_for_the_entire_mesh_2() {
for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
}

snip_clean_up_the_example_1() {
kubectl delete peerauthentication -n istio-system default
}

snip_clean_up_the_example_2() {
kubectl delete ns foo bar legacy
}

! read -r -d '' snip_clean_up_the_example_2_out <<\ENDSNIP
Namespaces foo bar legacy deleted.
ENDSNIP
