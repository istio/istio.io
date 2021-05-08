#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

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

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/examples/microservices-istio/single/index.md
####################################################################################################

set -e
set -u
set -o pipefail

source "tests/util/addons.sh"

# @setup profile=none
# @child microservice-example
# @order 11

export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

_verify_same snip__1 "$snip__1_out"

_verify_same snip__2 "$snip__2_out"

snip__3

snip__4 >> /etc/hosts

cat /etc/hosts

_verify_same snip__5 "$snip__5_out"

snip__6

# Verify external access
get_bookinfo_productpage() {
    curl -s "http://$MY_INGRESS_GATEWAY_HOST:$INGRESS_PORT/productpage" | grep -o "<title>.*</title>"
}
_verify_contains get_bookinfo_productpage "<title>Simple Bookstore App</title>"

_verify_same snip__8 "$snip__8_out"

# @cleanup
set +e # ignore cleanup errors

export NAMESPACE=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}")

rm -rf ratings

rm -rf "${NAMESPACE}"-user-config.yaml

protos=( destinationrules virtualservices gateways serviceaccount service deployment )
for proto in "${protos[@]}"; do
   for resource in $(kubectl get -n "${NAMESPACE}" "$proto" -o name); do
     kubectl delete -n "${NAMESPACE}" "$resource";   
   done
done

kubectl delete ingress istio-system -n istio-system

kubectl delete role istio-system-access -n istio-system

kubectl delete serviceaccount "${NAMESPACE}"-user -n "${NAMESPACE}"

kubectl delete role "${NAMESPACE}"-access -n "${NAMESPACE}"

kubectl delete namespace "${NAMESPACE}"

_undeploy_addons grafana jaeger kiali prometheus
