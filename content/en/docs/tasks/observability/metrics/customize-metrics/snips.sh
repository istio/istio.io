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
#          docs/tasks/observability/metrics/customize-metrics/index.md
####################################################################################################

snip_enable_custom_metrics_1() {
kubectl -n istio-system get envoyfilter | grep ^stats-filter-1.6
}

! read -r -d '' snip_enable_custom_metrics_1_out <<\ENDSNIP
stats-filter-1.6                    2d
ENDSNIP

snip_enable_custom_metrics_2() {
kubectl -n istio-system get envoyfilter stats-filter-1.6 -o yaml > stats-filter-1.6.yaml
}

! read -r -d '' snip_enable_custom_metrics_3 <<\ENDSNIP
{
"debug": "false",
"stat_prefix": "istio"
}
ENDSNIP

! read -r -d '' snip_enable_custom_metrics_4 <<\ENDSNIP
{
    "debug": "false",
    "stat_prefix": "istio",
    "metrics": [
        {
            "name": "requests_total",
            "dimensions": {
                "destination_port": "string(destination.port)",
                "request_host": "request.host"
            }
        }
    ]
}
ENDSNIP

snip_enable_custom_metrics_5() {
kubectl -n istio-system apply -f stats-filter-1.6.yaml
}

! read -r -d '' snip_enable_custom_metrics_6 <<\ENDSNIP
apiVersion: apps/v1
kind: Deployment
spec:
  template: # pod template
    metadata:
      annotations:
        sidecar.istio.io/extraStatTags: destination_port,request_host
ENDSNIP

snip_verify_the_results_1() {
kubectl exec pod-name -c istio-proxy -- curl 'localhost:15000/stats/prometheus' | grep istio
}

! read -r -d '' snip_use_expressions_for_values_1 <<\ENDSNIP
has(request.host) ? request.host : "unknown"
ENDSNIP
