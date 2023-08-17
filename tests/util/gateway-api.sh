#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2120,SC2154

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
source "content/en/boilerplates/snips/args.sh"

K8S_GATEWAY_API_CRDS="github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=${bpsnip_args_gateway_api_version}"
GATEWAY_API="true"

function install_gateway_api_crds() {
    kubectl kustomize "${K8S_GATEWAY_API_CRDS}" | kubectl apply -f - --context="$1"
}

function remove_gateway_api_crds() {
    kubectl kustomize "${K8S_GATEWAY_API_CRDS}" | kubectl delete -f - --context="$1"

    kubectl get --context="$1" gateways.gateway.networking.k8s.io >/dev/null 2>&1 || true
    # TODO ^^^ remove this kludge which forces the name "gateway" to not stay bound to the deleted crd
}
