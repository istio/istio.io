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
#          docs/setup/additional-setup/dual-stack/index.md
####################################################################################################

snip_verification_1() {
kubectl create namespace dual-stack
kubectl create namespace ipv4
kubectl create namespace ipv6
}

snip_verification_2() {
kubectl label --overwrite namespace default istio-injection=enabled
kubectl label --overwrite namespace dual-stack istio-injection=enabled
kubectl label --overwrite namespace ipv4 istio-injection=enabled
kubectl label --overwrite namespace ipv6 istio-injection=enabled
}

snip_verification_3() {
kubectl apply --namespace dual-stack -f samples/tcp-echo/tcp-echo-dual-stack.yaml
kubectl apply --namespace ipv4 -f samples/tcp-echo/tcp-echo-ipv4.yaml
kubectl apply --namespace ipv6 -f samples/tcp-echo/tcp-echo-ipv6.yaml
}

snip_verification_4() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_verification_5() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo dualstack | nc tcp-echo.dual-stack 9000"
}

! read -r -d '' snip_verification_5_out <<\ENDSNIP
hello dualstack
ENDSNIP

snip_verification_6() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv4 | nc tcp-echo.ipv4 9000"
}

! read -r -d '' snip_verification_6_out <<\ENDSNIP
hello ipv4
ENDSNIP

snip_verification_7() {
kubectl exec "$(kubectl get pod -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "echo ipv6 | nc tcp-echo.ipv6 9000"
}

! read -r -d '' snip_verification_7_out <<\ENDSNIP
hello ipv6
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete ns dual-stack ipv4 ipv6
}
