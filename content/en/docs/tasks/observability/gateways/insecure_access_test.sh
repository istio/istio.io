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

# @setup profile=demo

_deploy_addons
_wait_for_deployment istio-system grafana
_wait_for_deployment istio-system kiali
_wait_for_deployment istio-system prometheus
_wait_for_deployment istio-system zipkin

# Setup ingress URL (using nip.io here)
snip_configuring_remote_access_2

_verify_lines snip_option_2_insecure_access_http_1 snip_option_2_insecure_access_http_1_out
_verify_lines snip_option_2_insecure_access_http_2 snip_option_2_insecure_access_http_2_out
_verify_lines snip_option_2_insecure_access_http_3 snip_option_2_insecure_access_http_3_out
_verify_lines snip_option_2_insecure_access_http_4 snip_option_2_insecure_access_http_4_out

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
  curl -s -o /dev/null -w "%{http_code}" "http://kiali.$INGRESS_DOMAIN/kiali/"
}

function access_prometheus() {
  curl -s -o /dev/null -w "%{http_code}" "http://prometheus.$INGRESS_DOMAIN/api/v1/status/config"
}

function access_grafana() {
  curl -s -o /dev/null -w "%{http_code}" "http://grafana.$INGRESS_DOMAIN"
}

function access_tracing() {
  curl -s -o /dev/null -w "%{http_code}" "http://tracing.$INGRESS_DOMAIN/zipkin/api/v2/traces"
}

_verify_same access_kiali "200"
_verify_same access_prometheus "200"
_verify_same access_grafana "200"
_verify_same access_tracing "200"

# @cleanup
_verify_same snip_cleanup_1 "$snip_cleanup_1_out"
_verify_same snip_cleanup_2 "$snip_cleanup_2_out"
_verify_same snip_cleanup_3 "$snip_cleanup_3_out"

set +e
_undeploy_addons
