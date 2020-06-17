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
#          docs/tasks/traffic-management/circuit-breaking/index.md
####################################################################################################

snip_configuring_the_circuit_breaker_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutiveErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
EOF
}

snip_configuring_the_circuit_breaker_2() {
kubectl get destinationrule httpbin -o yaml
}

! read -r -d '' snip_configuring_the_circuit_breaker_2_out <<\ENDSNIP
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
...
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
      tcp:
        maxConnections: 1
    outlierDetection:
      baseEjectionTime: 3m
      consecutiveErrors: 1
      interval: 1s
      maxEjectionPercent: 100
ENDSNIP

snip_adding_a_client_1() {
kubectl apply -f samples/httpbin/sample-client/fortio-deploy.yaml
}

snip_adding_a_client_2() {
kubectl apply -f <(istioctl kube-inject -f samples/httpbin/sample-client/fortio-deploy.yaml)
}

snip_adding_a_client_3() {
FORTIO_POD=$(kubectl get pods -lapp=fortio -o 'jsonpath={.items[0].metadata.name}')
kubectl exec -it "$FORTIO_POD"  -c fortio -- /usr/bin/fortio load -curl http://httpbin:8000/get
}

! read -r -d '' snip_adding_a_client_3_out <<\ENDSNIP
HTTP/1.1 200 OK
server: envoy
date: Tue, 25 Feb 2020 20:25:52 GMT
content-type: application/json
content-length: 586
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 36

{
  "args": {},
  "headers": {
    "Content-Length": "0",
    "Host": "httpbin:8000",
    "User-Agent": "fortio.org/fortio-1.3.1",
    "X-B3-Parentspanid": "8fc453fb1dec2c22",
    "X-B3-Sampled": "1",
    "X-B3-Spanid": "071d7f06bc94943c",
    "X-B3-Traceid": "86a929a0e76cda378fc453fb1dec2c22",
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/default/sa/httpbin;Hash=68bbaedefe01ef4cb99e17358ff63e92d04a4ce831a35ab9a31d3c8e06adb038;Subject=\"\";URI=spiffe://cluster.local/ns/default/sa/default"
  },
  "origin": "127.0.0.1",
  "url": "http://httpbin:8000/get"
}
ENDSNIP

snip_tripping_the_circuit_breaker_1() {
kubectl exec -it "$FORTIO_POD"  -c fortio -- /usr/bin/fortio load -c 2 -qps 0 -n 20 -loglevel Warning http://httpbin:8000/get
}

! read -r -d '' snip_tripping_the_circuit_breaker_1_out <<\ENDSNIP
20:33:46 I logger.go:97> Log level is now 3 Warning (was 2 Info)
Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 20 calls: http://httpbin:8000/get
Starting at max qps with 2 thread(s) [gomax 6] for exactly 20 calls (10 per thread + 0)
20:33:46 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:33:47 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
Ended after 59.8524ms : 20 calls. qps=334.16
Aggregated Function Time : count 20 avg 0.0056869 +/- 0.003869 min 0.000499 max 0.0144329 sum 0.113738
# range, mid point, percentile, count
>= 0.000499 <= 0.001 , 0.0007495 , 10.00, 2
> 0.001 <= 0.002 , 0.0015 , 15.00, 1
> 0.003 <= 0.004 , 0.0035 , 45.00, 6
> 0.004 <= 0.005 , 0.0045 , 55.00, 2
> 0.005 <= 0.006 , 0.0055 , 60.00, 1
> 0.006 <= 0.007 , 0.0065 , 70.00, 2
> 0.007 <= 0.008 , 0.0075 , 80.00, 2
> 0.008 <= 0.009 , 0.0085 , 85.00, 1
> 0.011 <= 0.012 , 0.0115 , 90.00, 1
> 0.012 <= 0.014 , 0.013 , 95.00, 1
> 0.014 <= 0.0144329 , 0.0142165 , 100.00, 1
# target 50% 0.0045
# target 75% 0.0075
# target 90% 0.012
# target 99% 0.0143463
# target 99.9% 0.0144242
Sockets used: 4 (for perfect keepalive, would be 2)
Code 200 : 17 (85.0 %)
Code 503 : 3 (15.0 %)
Response Header Sizes : count 20 avg 195.65 +/- 82.19 min 0 max 231 sum 3913
Response Body/Total Sizes : count 20 avg 729.9 +/- 205.4 min 241 max 817 sum 14598
All done 20 calls (plus 0 warmup) 5.687 ms avg, 334.2 qps
ENDSNIP

! read -r -d '' snip_tripping_the_circuit_breaker_2 <<\ENDSNIP
Code 200 : 17 (85.0 %)
Code 503 : 3 (15.0 %)
ENDSNIP

snip_tripping_the_circuit_breaker_3() {
kubectl exec -it "$FORTIO_POD"  -c fortio /usr/bin/fortio -- load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
}

! read -r -d '' snip_tripping_the_circuit_breaker_3_out <<\ENDSNIP
20:32:30 I logger.go:97> Log level is now 3 Warning (was 2 Info)
Fortio 1.3.1 running at 0 queries per second, 6->6 procs, for 30 calls: http://httpbin:8000/get
Starting at max qps with 3 thread(s) [gomax 6] for exactly 30 calls (10 per thread + 0)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
20:32:30 W http_client.go:679> Parsed non ok code 503 (HTTP/1.1 503)
Ended after 51.9946ms : 30 calls. qps=576.98
Aggregated Function Time : count 30 avg 0.0040001633 +/- 0.003447 min 0.0004298 max 0.015943 sum 0.1200049
# range, mid point, percentile, count
>= 0.0004298 <= 0.001 , 0.0007149 , 16.67, 5
> 0.001 <= 0.002 , 0.0015 , 36.67, 6
> 0.002 <= 0.003 , 0.0025 , 50.00, 4
> 0.003 <= 0.004 , 0.0035 , 60.00, 3
> 0.004 <= 0.005 , 0.0045 , 66.67, 2
> 0.005 <= 0.006 , 0.0055 , 76.67, 3
> 0.006 <= 0.007 , 0.0065 , 83.33, 2
> 0.007 <= 0.008 , 0.0075 , 86.67, 1
> 0.008 <= 0.009 , 0.0085 , 90.00, 1
> 0.009 <= 0.01 , 0.0095 , 96.67, 2
> 0.014 <= 0.015943 , 0.0149715 , 100.00, 1
# target 50% 0.003
# target 75% 0.00583333
# target 90% 0.009
# target 99% 0.0153601
# target 99.9% 0.0158847
Sockets used: 20 (for perfect keepalive, would be 3)
Code 200 : 11 (36.7 %)
Code 503 : 19 (63.3 %)
Response Header Sizes : count 30 avg 84.366667 +/- 110.9 min 0 max 231 sum 2531
Response Body/Total Sizes : count 30 avg 451.86667 +/- 277.1 min 241 max 817 sum 13556
All done 30 calls (plus 0 warmup) 4.000 ms avg, 577.0 qps
ENDSNIP

! read -r -d '' snip_tripping_the_circuit_breaker_4 <<\ENDSNIP
Code 200 : 11 (36.7 %)
Code 503 : 19 (63.3 %)
ENDSNIP

snip_tripping_the_circuit_breaker_5() {
kubectl exec "$FORTIO_POD" -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
}

! read -r -d '' snip_tripping_the_circuit_breaker_5_out <<\ENDSNIP
cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.default.rq_pending_open: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.circuit_breakers.high.rq_pending_open: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_active: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_failure_eject: 0
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_overflow: 21
cluster.outbound|8000||httpbin.default.svc.cluster.local.upstream_rq_pending_total: 29
ENDSNIP

snip_cleaning_up_1() {
kubectl delete destinationrule httpbin
}

snip_cleaning_up_2() {
kubectl delete deploy httpbin fortio-deploy
kubectl delete svc httpbin fortio
}
