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
#          docs/tasks/observability/logs/telemetry-api/index.md
####################################################################################################
source "content/en/boilerplates/snips/before-you-begin-egress.sh"
source "content/en/boilerplates/snips/start-httpbin-service.sh"

snip_install_loki() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f samples/open-telemetry/loki/iop.yaml --skip-confirmation
kubectl apply -f samples/addons/loki.yaml -n istio-system
kubectl apply -f samples/open-telemetry/loki/otel.yaml -n istio-system
}

snip_get_started_with_telemetry_api_1() {
cat <<EOF | kubectl apply -n istio-system -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-logging-default
spec:
  accessLogging:
  - providers:
    - name: otel
EOF
}

snip_get_started_with_telemetry_api_2() {
cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: disable-sleep-logging
  namespace: default
spec:
  selector:
    matchLabels:
      app: sleep
  accessLogging:
  - providers:
    - name: otel
    disabled: true
EOF
}

snip_get_started_with_telemetry_api_3() {
cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: disable-httpbin-logging
spec:
  selector:
    matchLabels:
      app: httpbin
  accessLogging:
  - providers:
    - name: otel
    match:
      mode: SERVER
    disabled: true
EOF
}

snip_get_started_with_telemetry_api_4() {
cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: filter-sleep-logging
spec:
  selector:
    matchLabels:
      app: sleep
  accessLogging:
  - providers:
    - name: otel
    filter:
      expression: response.code >= 500
EOF
}

snip_get_started_with_telemetry_api_5() {
cat <<EOF | kubectl apply -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: default-exception-logging
  namespace: istio-system
spec:
  accessLogging:
  - providers:
    - name: otel
    filter:
      expression: "response.code >= 400 || xds.cluster_name == 'BlackHoleCluster' ||  xds.cluster_name == 'PassthroughCluster' "

EOF
}

snip_get_started_with_telemetry_api_6() {
cat <<EOF | kubectl apply -f -
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: filter-health-check-logging
spec:
  accessLogging:
  - providers:
    - name: otel
    filter:
      expression: "!has(request.useragent) || !(request.useragent.startsWith("Amazon-Route53-Health-Check-Service"))"
EOF
}

snip_cleanup_1() {
kubectl delete telemetry --all -A
}

snip_cleanup_2() {
kubectl delete -f samples/addons/loki.yaml -n istio-system
kubectl delete -f samples/open-telemetry/loki/otel.yaml -n istio-system
}

snip_cleanup_3() {
istioctl uninstall --purge --skip-confirmation
}
