#!/usr/bin/env bash
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

# rewrite-repo invokes bash make to rewrite a snippet to avoid installing from a real helm repository, and instead uses
# local files
# shellcheck disable=SC2001
function rewrite-repo() {
  # get function definition: https://stackoverflow.com/a/6916952/374797
  cmd="$(type "${1:?snip}" | sed '1,3d;$d')"
  cmd="$(echo "${cmd}" | sed 's|istio/base|manifests/charts/base|')"
  cmd="$(echo "${cmd}" | sed 's|istio/istiod|manifests/charts/istio-control/istio-discovery|')"
  cmd="$(echo "${cmd}" | sed 's|istio/gateway|manifests/charts/gateway|')"
  eval "${cmd} --set global.tag=${ISTIO_IMAGE_VERSION=SHOULD_BE_SET}.${ISTIO_LONG_SHA=latest}"
}

# @setup profile=none

# Delete a vailidatingwebhookconfiguration that seems to have been left around from a prior test.
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io istiod-default-validator  --ignore-not-found

snip_create_istio_system_namespace
rewrite-repo snip_install_base

rewrite-repo snip_install_discovery
_wait_for_deployment istio-system istiod

rewrite-repo snip_install_ingressgateway
_wait_for_deployment istio-ingress istio-ingress

# shellcheck disable=SC2154
_verify_like snip_helm_ls "$snip_helm_ls_out"

# @cleanup
snip_delete_delete_gateway_charts
snip_helm_delete_discovery_chart
snip_helm_delete_base_chart
snip_delete_crds
snip_delete_istio_system_namespace
