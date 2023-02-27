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
#          docs/tasks/observability/logs/otel-provider/index.md
####################################################################################################
source "content/en/boilerplates/snips/before-you-begin-egress.sh"
source "content/en/boilerplates/snips/start-httpbin-service.sh"
source "content/en/boilerplates/snips/start-otel-collector-service.sh"

! read -r -d '' snip_enable_envoys_access_logging_1 <<\ENDSNIP
extensionProviders:
- name: otel
  envoyOtelAls:
    service: opentelemetry-collector.istio-system.svc.cluster.local
    port: 4317
ENDSNIP

! read -r -d '' snip_enable_envoys_access_logging_2 <<\ENDSNIP
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio
  namespace: istio-system
data:
  mesh: |-
    accessLogFile: /dev/stdout
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
    enablePrometheusMerge: true
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.istio-system.svc.cluster.local
        port: 4317
    rootNamespace: istio-system
    trustDomain: cluster.local
  meshNetworks: 'networks: {}'
ENDSNIP

snip_enable_envoys_access_logging_3() {
cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: sleep-logging
spec:
  selector:
    matchLabels:
      app: sleep
  accessLogging:
    - providers:
      - name: otel
EOF
}

! read -r -d '' snip_using_mesh_config_1 <<\ENDSNIP
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.istio-system.svc.cluster.local
        port: 4317
    defaultProviders:
      accessLogging:
      - envoy
      - otel
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
kubectl logs -l app=opentelemetry-collector -n istio-system
}

! read -r -d '' snip_test_the_access_log_2_out <<\ENDSNIP
[2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
ENDSNIP

snip_cleanup_1() {
kubectl delete telemetry sleep-logging
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/httpbin/httpbin.yaml
kubectl delete -f samples/open-telemetry/otel.yaml
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
