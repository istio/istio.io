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
#          docs/tasks/observability/distributed-tracing/opentelemetry/index.md
####################################################################################################

snip_mesh_grpc_exporter() {
cat <<EOF > ./tracing-grpc.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.otel-collector.svc.cluster.local
EOF
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f ./tracing.yaml --skip-confirmation
kubectl label namespace default istio-injection=enabled
}

snip_mesh_http_exporter() {
cat <<EOF > ./tracing-http.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4318
        service: opentelemetry-collector.otel-collector.svc.cluster.local
        http:
          path: "v1/traces"
          timeout: 10s
          headers:
          - name: "my-custom-header"
            value: "some-value"
EOF
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f ./tracing.yaml --skip-confirmation
kubectl label namespace default istio-injection=enabled
}

snip_enable_telemetry() {
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: otel-demo
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 100
    customTags:
      "my-attribute":
        literal:
          value: "default-value"
EOF
}

snip_cleanup_1() {
killall istioctl
}
