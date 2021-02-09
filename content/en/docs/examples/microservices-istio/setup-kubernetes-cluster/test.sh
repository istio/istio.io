#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2034,SC2153,SC2155,SC2164
#
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

set -e
set -u
set -o pipefail

# @setup profile=none
# @child microservice-example
# @order 2

snip__1

snip__2

istioctl install --set tag="$TAG" --set hub="$HUB" --set profile=demo -y

_wait_for_deployment istio-system istiod

cat <<EOF | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: monitoringdashboards.monitoring.kiali.io
spec:
  group: monitoring.kiali.io
  names:
    kind: MonitoringDashboard
    listKind: MonitoringDashboardList
    plural: monitoringdashboards
    singular: monitoringdashboard
  scope: Namespaced
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        x-kubernetes-preserve-unknown-fields: true
EOF

snip__3

for addon in "grafana" "jaeger" "kiali" "prometheus"; do
    _wait_for_deployment istio-system "$addon"
done

snip__4

snip__5

snip__6

snip__7

snip__8

snip__9

export CLUSTERNAME=$(kubectl config view --minify -o jsonpath='{.clusters[].name}')

snip__10

snip__11

_verify_same snip__12 "$snip__12_out"

# @cleanup
set +e # ignore cleanup errors
