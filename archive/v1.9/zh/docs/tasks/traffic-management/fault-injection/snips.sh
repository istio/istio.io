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
#          docs/tasks/traffic-management/fault-injection/index.md
####################################################################################################

snip_before_you_begin_1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
}

snip_injecting_an_http_delay_fault_1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
}

snip_injecting_an_http_delay_fault_2() {
kubectl get virtualservice ratings -o yaml
}

! read -r -d '' snip_injecting_an_http_delay_fault_2_out <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        fixedDelay: 7s
        percentage:
          value: 100
    match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: ratings
        subset: v1
  - route:
    - destination:
        host: ratings
        subset: v1
ENDSNIP

! read -r -d '' snip_testing_the_delay_configuration_1 <<\ENDSNIP
Sorry, product reviews are currently unavailable for this book.
ENDSNIP

snip_injecting_an_http_abort_fault_1() {
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml
}

snip_injecting_an_http_abort_fault_2() {
kubectl get virtualservice ratings -o yaml
}

! read -r -d '' snip_injecting_an_http_abort_fault_2_out <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
...
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        httpStatus: 500
        percentage:
          value: 100
    match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: ratings
        subset: v1
  - route:
    - destination:
        host: ratings
        subset: v1
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/bookinfo/networking/virtual-service-all-v1.yaml
}
