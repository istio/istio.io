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
#          docs/tasks/observability/logs/access-log/index.md
####################################################################################################
source "content/en/boilerplates/snips/before-you-begin-egress.sh"
source "content/en/boilerplates/snips/start-httpbin-service.sh"

! read -r -d '' snip_enable_envoys_access_logging_1 <<\ENDSNIP
spec:
  meshConfig:
    accessLogFile: /dev/stdout
ENDSNIP

snip_test_the_access_log_1() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -v httpbin:8000/status/418
}

! read -r -d '' snip_test_the_access_log_1_out <<\ENDSNIP
...
< HTTP/1.1 418 Unknown
< server: envoy
...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
ENDSNIP

snip_test_the_access_log_2() {
kubectl logs -l app=sleep -c istio-proxy
}

! read -r -d '' snip_test_the_access_log_2_out <<\ENDSNIP
[2019-03-06T09:31:27.354Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 11 10 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "172.30.146.73:80" outbound|8000||httpbin.default.svc.cluster.local - 172.21.13.94:8000 172.30.146.82:60290 -
ENDSNIP

snip_test_the_access_log_3() {
kubectl logs -l app=httpbin -c istio-proxy
}

! read -r -d '' snip_test_the_access_log_3_out <<\ENDSNIP
[2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
}

snip_disable_envoys_access_logging_1() {
istioctl install --set profile=default
}

! read -r -d '' snip_disable_envoys_access_logging_1_out <<\ENDSNIP
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
ENDSNIP
