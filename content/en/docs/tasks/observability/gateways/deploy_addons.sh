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

GRAFANA_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml"
KIALI_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml"
PROMETHEUS_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml"
ZIPKIN_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/extras/zipkin.yaml"

function _deploy_addons() {
  kubectl apply -f "$GRAFANA_URL"
  kubectl apply -f "$KIALI_URL"
  kubectl apply -f "$PROMETHEUS_URL"
  kubectl apply -f "$ZIPKIN_URL"
}

function _undeploy_addons() {
  kubectl delete -f "$GRAFANA_URL"
  kubectl delete -f "$KIALI_URL"
  kubectl delete -f "$PROMETHEUS_URL"
  kubectl delete -f "$ZIPKIN_URL"
}