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
#          docs/tasks/observability/metrics/telemetry-api/index.md
####################################################################################################

! read -r -d '' snip_before_you_begin_1 <<\ENDSNIP
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    telemetry:
      enabled: true
      v2:
        enabled: false
ENDSNIP

! read -r -d '' snip_override_metrics_1 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: remove-tags
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      overrides:
        - match:
            mode: CLIENT_AND_SERVER
            metric: REQUEST_COUNT
          tagOverrides:
            grpc_response_status:
              operation: REMOVE
ENDSNIP

! read -r -d '' snip_override_metrics_2 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: custom-tags
  namespace: istio-system
spec:
  metrics:
    - overrides:
        - match:
            metric: REQUEST_COUNT
            mode: CLIENT
          tagOverrides:
            destination_x:
              value: upstream_peer.labels['app'].value
        - match:
            metric: REQUEST_COUNT
            mode: SERVER
          tagOverrides:
            source_x:
              value: downstream_peer.labels['app'].value
      providers:
        - name: prometheus
ENDSNIP

! read -r -d '' snip_disable_metrics_1 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: remove-all-metrics
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      overrides:
        - disabled: true
          match:
            mode: CLIENT_AND_SERVER
            metric: ALL_METRICS
ENDSNIP

! read -r -d '' snip_disable_metrics_2 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: remove-request-count
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      overrides:
        - disabled: true
          match:
            mode: CLIENT_AND_SERVER
            metric: REQUEST_COUNT
ENDSNIP

! read -r -d '' snip_disable_metrics_3 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: remove-client
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      overrides:
        - disabled: true
          match:
            mode: CLIENT
            metric: REQUEST_COUNT
ENDSNIP

! read -r -d '' snip_disable_metrics_4 <<\ENDSNIP
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: remove-server
  namespace: istio-system
spec:
  metrics:
    - providers:
        - name: prometheus
      overrides:
        - disabled: true
          match:
            mode: SERVER
            metric: REQUEST_COUNT
ENDSNIP

snip_verify_the_results_1() {
curl "http://$GATEWAY_URL/productpage"
}

snip_verify_the_results_2() {
istioctl x es "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total | grep -v TYPE |grep -v 'reporter="destination"'
}

snip_verify_the_results_3() {
istioctl x es "$(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total
}
