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

source "tests/util/addons.sh"

# @setup profile=none

istioctl install --set profile=demo --set hub="$HUB" --set tag="$TAG"
_wait_for_deployment istio-system istiod
_wait_for_deployment istio-system istio-ingressgateway

_deploy_and_wait_for_addons kiali prometheus grafana zipkin

# Setup TLS certificates and ingress access
_set_ingress_environment_variables
INGRESS_DOMAIN="$INGRESS_HOST.nip.io"
INGRESS_URL="$INGRESS_DOMAIN:$SECURE_INGRESS_PORT"

snip_option_1_secure_access_https_1

snip_option_1_secure_access_https_2
snip_option_1_secure_access_https_3
snip_option_1_secure_access_https_4
snip_option_1_secure_access_https_5

_wait_for_addon_config_distribution kiali prometheus grafana tracing

function secure_access_kiali() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://kiali.$INGRESS_URL/kiali/"
}

function secure_access_prometheus() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://prometheus.$INGRESS_URL/api/v1/status/config"
}

function secure_access_grafana() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://grafana.$INGRESS_URL"
}

function secure_access_tracing() {
  curl -s -o /dev/null -w "%{http_code}" --cacert "$CERT_DIR/ca.crt" "https://tracing.$INGRESS_URL/zipkin/api/v2/traces"
}

_verify_same secure_access_kiali "200"
_verify_same secure_access_prometheus "200"
_verify_same secure_access_grafana "200"
_verify_same secure_access_tracing "200"

# @cleanup
set +e
snip_cleanup
snip_cleanup
snip_cleanup
_undeploy_addons kiali prometheus grafana zipkin
kubectl delete ns istio-system
