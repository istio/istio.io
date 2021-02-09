#!/bin/bash
# shellcheck disable=SC1090,SC2154,SC2034,SC2153,SC2155,SC2164

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
export NAMESPACE=tutorial
export MY_INGRESS_GATEWAY_HOST=istio.$NAMESPACE.bookinfo.com

_verify_same snip__2 "$snip__2_out"

snip__3

snip__4

snip__6

_verify_contains snip__8 "$snip__8_out"

# @cleanup
set +e # ignore cleanup errors

rm -rf ratings

rm -rf tutorial-user-config.yaml

protos=( destinationrules virtualservices gateways serviceaccount service deployment )
for proto in "${protos[@]}"; do
   for resource in $(kubectl get -n $NAMESPACE "$proto" -o name); do
     kubectl delete -n $NAMESPACE "$resource";   
   done
done

kubectl delete ingress istio-system -n istio-system

kubectl delete role istio-system-access -n istio-system

kubectl delete serviceaccount tutorial-user -n tutorial

kubectl delete role tutorial-access -n tutorial

_undeploy_addons grafana jaeger kiali prometheus

istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -

kubectl delete namespace istio-system tutorial --ignore-not-found=true
