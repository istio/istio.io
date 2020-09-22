#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155

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
#          docs/tasks/traffic-management/tcp-traffic-shifting/index.md
####################################################################################################

snip_set_up_the_test_environment_1() {
kubectl create namespace istio-io-tcp-traffic-shifting
kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
}

snip_set_up_the_test_environment_2() {
kubectl apply -f samples/sleep/sleep.yaml -n istio-io-tcp-traffic-shifting
}

snip_set_up_the_test_environment_3() {
kubectl apply -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_1() {
kubectl apply -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_2() {
for i in {1..20}; do \
kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
-c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_2_out <<\ENDSNIP
one Mon Nov 12 23:24:57 UTC 2018
one Mon Nov 12 23:25:00 UTC 2018
one Mon Nov 12 23:25:02 UTC 2018
one Mon Nov 12 23:25:05 UTC 2018
one Mon Nov 12 23:25:07 UTC 2018
one Mon Nov 12 23:25:10 UTC 2018
one Mon Nov 12 23:25:12 UTC 2018
one Mon Nov 12 23:25:15 UTC 2018
one Mon Nov 12 23:25:17 UTC 2018
one Mon Nov 12 23:25:19 UTC 2018
...
ENDSNIP

snip_apply_weightbased_tcp_routing_3() {
kubectl apply -f samples/tcp-echo/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_4() {
kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
}

! read -r -d '' snip_apply_weightbased_tcp_routing_4_out <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
  ...
spec:
  ...
  tcp:
  - match:
    - port: 31400
    route:
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v1
      weight: 80
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v2
      weight: 20
ENDSNIP

snip_apply_weightbased_tcp_routing_5() {
for i in {1..20}; do \
kubectl exec "$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})" \
-c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_5_out <<\ENDSNIP
one Mon Nov 12 23:38:45 UTC 2018
two Mon Nov 12 23:38:47 UTC 2018
one Mon Nov 12 23:38:50 UTC 2018
one Mon Nov 12 23:38:52 UTC 2018
one Mon Nov 12 23:38:55 UTC 2018
two Mon Nov 12 23:38:57 UTC 2018
one Mon Nov 12 23:39:00 UTC 2018
one Mon Nov 12 23:39:02 UTC 2018
one Mon Nov 12 23:39:05 UTC 2018
one Mon Nov 12 23:39:07 UTC 2018
...
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/sleep/sleep.yaml -n istio-io-tcp-traffic-shifting
kubectl delete namespace istio-io-tcp-traffic-shifting
}
