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

snip_apply_weightbased_tcp_routing_1() {
kubectl create namespace istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_2() {
kubectl apply -f <(istioctl kube-inject -f samples/tcp-echo/tcp-echo-services.yaml) -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_3() {
kubectl label namespace istio-io-tcp-traffic-shifting istio-injection=enabled
}

snip_apply_weightbased_tcp_routing_4() {
kubectl apply -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_5() {
kubectl apply -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_6() {
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
}

snip_apply_weightbased_tcp_routing_7() {
for i in {1..10}; do \
docker run -e INGRESS_HOST="$INGRESS_HOST" -e INGRESS_PORT="$INGRESS_PORT" -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_7_out <<ENDSNIP
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
ENDSNIP

snip_apply_weightbased_tcp_routing_8() {
kubectl apply -f samples/tcp-echo/tcp-echo-20-v2.yaml -n istio-io-tcp-traffic-shifting
}

snip_apply_weightbased_tcp_routing_9() {
kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
}

! read -r -d '' snip_apply_weightbased_tcp_routing_9_out <<ENDSNIP
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tcp-echo
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

snip_apply_weightbased_tcp_routing_10() {
for i in {1..10}; do \
docker run -e INGRESS_HOST="$INGRESS_HOST" -e INGRESS_PORT="$INGRESS_PORT" -it --rm busybox sh -c "(date; sleep 1) | nc $INGRESS_HOST $INGRESS_PORT"; \
done
}

! read -r -d '' snip_apply_weightbased_tcp_routing_10_out <<ENDSNIP
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
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/tcp-echo/tcp-echo-all-v1.yaml -n istio-io-tcp-traffic-shifting
kubectl delete -f samples/tcp-echo/tcp-echo-services.yaml -n istio-io-tcp-traffic-shifting
kubectl delete namespace istio-io-tcp-traffic-shifting
}
