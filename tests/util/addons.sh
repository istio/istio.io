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

# Deploy the addons specified and wait for the deployment to complete. Currently
# Zipkin, Jaeger, Grafana, Kiali and Prometheus are supported.
function _deploy_and_wait_for_addons() {
  for arg in "$@"; do
    case "$arg" in
    zipkin)     kubectl apply -f samples/addons/extras/zipkin.yaml
                 _wait_for_deployment istio-system zipkin
                 ;;
    grafana)    kubectl apply -f samples/addons/grafana.yaml
                 _wait_for_deployment istio-system grafana
                 ;;
    jaeger)     kubectl apply -f samples/addons/jaeger.yaml
                 _wait_for_deployment istio-system jaeger
                 ;;
    kiali)      kubectl apply -f samples/addons/kiali.yaml || true # ignore first errors
                 kubectl apply -f samples/addons/kiali.yaml # Need to apply twice due to a race condition
                 _wait_for_deployment istio-system kiali
                 ;;
    prometheus) kubectl apply -f samples/addons/prometheus.yaml
                 _wait_for_deployment istio-system prometheus
                 ;;
    skywalking) kubectl apply -f samples/addons/extras/skywalking.yaml
                 _wait_for_deployment istio-system skywalking-oap
                 _wait_for_deployment istio-system skywalking-ui
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
    zipkin)      kubectl delete -f samples/addons/extras/zipkin.yaml
                  ;;
    grafana)     kubectl delete -f samples/addons/grafana.yaml
                  ;;
    jaeger)      kubectl delete -f samples/addons/jaeger.yaml
                  ;;
    kiali)       kubectl delete -f samples/addons/kiali.yaml
                  ;;
    prometheus)  kubectl delete -f samples/addons/prometheus.yaml
                  ;;
    skywalking)  kubectl delete -f samples/addons/extras/skywalking.yaml
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
