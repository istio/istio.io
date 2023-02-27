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

! read -r -d '' snip_using_telemetry_api_1 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy
ENDSNIP

! read -r -d '' snip_using_mesh_config_1 <<\ENDSNIP
spec:
  meshConfig:
    accessLogFile: /dev/stdout
ENDSNIP

! read -r -d '' snip_default_access_log_format_1 <<\ENDSNIP
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
ENDSNIP

snip_test_the_access_log_1() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v httpbin:8000/status/418
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
[2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 4 4 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "10.44.1.27:80" outbound|8000||httpbin.foo.svc.cluster.local 10.44.1.23:37652 10.0.45.184:8000 10.44.1.23:46520 - default
ENDSNIP

snip_test_the_access_log_3() {
kubectl logs -l app=httpbin -c istio-proxy
}

! read -r -d '' snip_test_the_access_log_3_out <<\ENDSNIP
[2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
}

snip_disable_envoys_access_logging_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=default
}

! read -r -d '' snip_disable_envoys_access_logging_1_out <<\ENDSNIP
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
ENDSNIP
