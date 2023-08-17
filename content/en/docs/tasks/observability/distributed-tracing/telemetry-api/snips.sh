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
#          docs/tasks/observability/distributed-tracing/telemetry-api/index.md
####################################################################################################

snip_installation_1() {
cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disabled MeshConfig tracing options
    extensionProviders:
    # add zipkin provider
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f ./tracing.yaml --skip-confirmation
}

snip_enable_tracing_for_mesh_1() {
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
EOF
}

snip_customizing_trace_sampling_1() {
kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
      randomSamplingPercentage: 100.00
EOF
}

! read -r -d '' snip_customizing_tracing_tags_1 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
name: mesh-default
namespace: istio-system
spec:
tracing:
    - providers:
        - name: "zipkin"
    randomSamplingPercentage: 100.00
    customTags:
      "provider":
        literal:
          value: "zipkin"
ENDSNIP

! read -r -d '' snip_customizing_tracing_tags_2 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
      randomSamplingPercentage: 100.00
      customTags:
        "cluster_id":
          environment:
            name: ISTIO_META_CLUSTER_ID
            defaultValue: Kubernetes # optional
ENDSNIP

! read -r -d '' snip_customizing_tracing_tags_3 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
      randomSamplingPercentage: 100.00
      custom_tags:
        my_tag_header:
          header:
            name: <CLIENT-HEADER>
            defaultValue: <VALUE>      # optional
ENDSNIP

! read -r -d '' snip_customizing_tracing_tag_length_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # disabled tracing options via `MeshConfig`
    extensionProviders:
    # add zipkin provider
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
ENDSNIP
