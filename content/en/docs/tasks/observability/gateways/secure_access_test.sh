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

set -e
set -u
set -o pipefail

source "tests/util/samples.sh"
source "content/en/docs/tasks/observability/gateways/deploy_addons.sh"

# @setup profile=none

####### TODO: Lots of copy paste from insecure_access_test.sh
####### REFACTOR to a common file and source it.

istioctl install --set profile=demo --set hub="$HUB" --set tag="$TAG"
_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system istio-ingressgateway

_deploy_addons
_wait_for_deployment istio-system grafana
_wait_for_deployment istio-system kiali
_wait_for_deployment istio-system prometheus
_wait_for_deployment istio-system zipkin

# Setup TLS certificates and ingress access
snip_configuring_remote_access_2

kubectl delete secret telemetry-gw-cert -n istio-system --ignore-not-found
snip_option_1_secure_access_https_1

_verify_lines snip_option_1_secure_access_https_2 snip_option_1_secure_access_https_2_out
_verify_lines snip_option_1_secure_access_https_3 snip_option_1_secure_access_https_3_out
_verify_lines snip_option_1_secure_access_https_4 snip_option_1_secure_access_https_4_out
_verify_lines snip_option_1_secure_access_https_5 snip_option_1_secure_access_https_5_out

function wait_for_addon() {
  local addon_name=$1
  _wait_for_istio Gateway istio-system "$addon_name-gateway"
  _wait_for_istio VirtualService istio-system "$addon_name-vs"
  _wait_for_istio DestinationRule istio-system "$addon_name"
}

wait_for_addon grafana
wait_for_addon kiali
wait_for_addon prometheus
wait_for_addon tracing

function access_kiali() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://kiali.$INGRESS_DOMAIN/kiali/"
}

function access_prometheus() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://prometheus.$INGRESS_DOMAIN/api/v1/status/config"
}

function access_grafana() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://grafana.$INGRESS_DOMAIN"
}

function access_tracing() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://tracing.$INGRESS_DOMAIN/zipkin/api/v2/traces"
}

_verify_same access_kiali "200"
_verify_same access_prometheus "200"
_verify_same access_grafana "200"
_verify_same access_tracing "200"

# @cleanup
set +e
snip_cleanup_1
snip_cleanup_2
snip_cleanup_3

_undeploy_addons
kubectl delete ns istio-system
