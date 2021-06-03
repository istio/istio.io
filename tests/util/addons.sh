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

source "tests/util/helpers.sh"

GRAFANA_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml"
KIALI_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml"
PROMETHEUS_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml"
ZIPKIN_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/extras/zipkin.yaml"
JAEGER_MANIFEST_URL="https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml"

# Deploy the addons specified and wait for the deployment to complete. Currently
# Zipkin, Jaeger, Grafana, Kiali and Prometheus are supported.
function _deploy_and_wait_for_addons() {
  for arg in "$@"; do
    case "$arg" in
    zipkin)     kubectl apply -f "$ZIPKIN_MANIFEST_URL"
                 _wait_for_deployment istio-system zipkin
                 ;;
    grafana)    kubectl apply -f "$GRAFANA_MANIFEST_URL"
                 _wait_for_deployment istio-system grafana
                 ;;
    jaeger)     kubectl apply -f "$JAEGER_MANIFEST_URL"
                 _wait_for_deployment istio-system jaeger
                 ;;
    kiali)      kubectl apply -f "$KIALI_MANIFEST_URL" || true # ignore first errors
                 kubectl apply -f "$KIALI_MANIFEST_URL" # Need to apply twice due to a reace condition
                 _wait_for_deployment istio-system kiali
                 ;;
    prometheus) kubectl apply -f "$PROMETHEUS_MANIFEST_URL"
                 _wait_for_deployment istio-system prometheus
                 ;;
    *)           echo "unknown parameter $arg"
                 exit 1
    esac
  done
}

# Delete Istio addon deployments. Usually this is meant to be used
# with _deploy_and_wait_for_addons function
function _undeploy_addons() {
  for arg in "$@"; do
    case "$arg" in
    zipkin)      kubectl delete -f "$ZIPKIN_MANIFEST_URL"
                  ;;
    grafana)     kubectl delete -f "$GRAFANA_MANIFEST_URL"
                  ;;
    jaeger)      kubectl delete -f "$JAEGER_MANIFEST_URL"
                  ;;
    kiali)       kubectl delete -f "$KIALI_MANIFEST_URL"
                  ;;
    prometheus)  kubectl delete -f "$PROMETHEUS_MANIFEST_URL"
                  ;;
    *)            echo "unknown parameter $arg"
                  exit 1
    esac
  done
}

# Wait for the distribution of Gateway, VirtualService and DestinationRule
# configuration to sidecar proxies
function _wait_for_addon_config_distribution() {
  for addon in "$@"; do
    _wait_for_istio Gateway istio-system "$addon-gateway"
    _wait_for_istio VirtualService istio-system "$addon-vs"
    _wait_for_istio DestinationRule istio-system "$addon"
  done
}
