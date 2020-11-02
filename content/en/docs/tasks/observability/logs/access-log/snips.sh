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
[2020-10-30T12:36:44.547Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 25 24 "-" "curl/7.69.1" "f13c2118-3ef9-9ed9-91b7-5d21358029c3" "httpbin:8000" "10.244.0.30:80" outbound|8000||httpbin.default.svc.cluster.local 10.244.0.29:46348 10.96.148.56:8000 10.244.0.29:44678 - default
ENDSNIP

snip_test_the_access_log_3() {
kubectl logs -l app=httpbin -c istio-proxy
}

! read -r -d '' snip_test_the_access_log_3_out <<\ENDSNIP
[2020-10-30T12:36:44.553Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 3 2 "-" "curl/7.69.1" "f13c2118-3ef9-9ed9-91b7-5d21358029c3" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:42940 10.244.0.30:80 10.244.0.29:46348 outbound_.8000_._.httpbin.default.svc.cluster.local default
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
