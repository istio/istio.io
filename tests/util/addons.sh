#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155,SC2034

# Copyright Istio Authors
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

GRAFANA_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml"
KIALI_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml"
PROMETHEUS_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml"
ZIPKIN_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/extras/zipkin.yaml"

function _deploy_addons() {
  kubectl apply -f "$GRAFANA_MANIFEST_URL"
  kubectl apply -f "$KIALI_MANIFEST_URL"
  kubectl apply -f "$PROMETHEUS_MANIFEST_URL"
  kubectl apply -f "$ZIPKIN_MANIFEST_URL"
}

function _undeploy_addons() {
  kubectl delete -f "$GRAFANA_MANIFEST_URL"
  kubectl delete -f "$KIALI_MANIFEST_URL"
  kubectl delete -f "$PROMETHEUS_MANIFEST_URL"
  kubectl delete -f "$ZIPKIN_MANIFEST_URL"
}

function _wait_for_addon_deployment() {
  local addon_list=( grafana kiali prometheus zipkin )
  for addon in "${addon_list[@]}"; do
    _wait_for_deployment istio-system "$addon"
  done
}

function _wait_for_config_distribution() {
  local addon_list=( grafana kiali prometheus tracing )
  for addon in "${addon_list[@]}"; do
    _wait_for_istio Gateway istio-system "$addon-gateway"
    _wait_for_istio VirtualService istio-system "$addon-vs"
    _wait_for_istio DestinationRule istio-system "$addon"
  done
}
