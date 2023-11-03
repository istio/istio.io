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
#          docs/tasks/traffic-management/tcp-traffic-shifting/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-support.sh"
source "content/en/boilerplates/snips/gateway-api-experimental.sh"

snip_set_up_the_test_environment_1() {
kubectl create namespace istio-io-tcp-traffic-shifting
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
kubectl apply -f samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_3() {
kubectl wait --for=condition=ready gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting
export INGRESS_HOST=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.status.addresses[*].value}')
export TCP_INGRESS_PORT=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.spec.listeners[?(@.name=="tcp-31400")].port}')
}

snip_apply_weightbased_tcp_routing_4() {
export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
for i in {1..20}; do \
kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_4_out <<\ENDSNIP
one Mon Nov 12 23:24:57 UTC 2022
one Mon Nov 12 23:25:00 UTC 2022
one Mon Nov 12 23:25:02 UTC 2022
one Mon Nov 12 23:25:05 UTC 2022
one Mon Nov 12 23:25:07 UTC 2022
one Mon Nov 12 23:25:10 UTC 2022
one Mon Nov 12 23:25:12 UTC 2022
one Mon Nov 12 23:25:15 UTC 2022
one Mon Nov 12 23:25:17 UTC 2022
one Mon Nov 12 23:25:19 UTC 2022
...
ENDSNIP

snip_apply_weightbased_tcp_routing_5() {
kubectl apply -f samples/tcp-echo/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_6() {
kubectl apply -f samples/tcp-echo/gateway-api/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_7() {
kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
}

! read -r -d '' snip_apply_weightbased_tcp_routing_7_out <<\ENDSNIP
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

snip_apply_weightbased_tcp_routing_8() {
kubectl get tcproute tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
}

! read -r -d '' snip_apply_weightbased_tcp_routing_8_out <<\ENDSNIP
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
  ...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: tcp-echo-gateway
    sectionName: tcp-31400
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: tcp-echo-v1
      port: 9000
      weight: 80
    - group: ""
      kind: Service
      name: tcp-echo-v2
      port: 9000
      weight: 20
...
ENDSNIP

snip_apply_weightbased_tcp_routing_9() {
export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
for i in {1..20}; do \
kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_9_out <<\ENDSNIP
one Mon Nov 12 23:38:45 UTC 2022
two Mon Nov 12 23:38:47 UTC 2022
one Mon Nov 12 23:38:50 UTC 2022
one Mon Nov 12 23:38:52 UTC 2022
one Mon Nov 12 23:38:55 UTC 2022
two Mon Nov 12 23:38:57 UTC 2022
one Mon Nov 12 23:39:00 UTC 2022
one Mon Nov 12 23:39:02 UTC 2022
one Mon Nov 12 23:39:05 UTC 2022
one Mon Nov 12 23:39:07 UTC 2022
...
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
}

snip_cleanup_2() {
kubectl delete -f samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
}

snip_cleanup_3() {
kubectl delete -f samples/sleep/sleep.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
kubectl delete namespace istio-io-tcp-traffic-shifting
}
