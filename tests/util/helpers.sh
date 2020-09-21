#!/bin/bash
# shellcheck disable=SC2155

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

# Set the INGRESS_HOST, INGRESS_PORT, SECURE_INGRESS_PORT, and TCP_INGRESS_PORT environment variables
_set_ingress_environment_variables() {
    # check for external load balancer
    local extlb=$(kubectl get svc istio-ingressgateway -n istio-system)
    if [[ "$extlb" != *"<none>"* && "$extlb" != *"<pending>"* ]]; then
        # external load balancer
        export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
        export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
        export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
    else
        # node port
        export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
        export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
        export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
        export TCP_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
    fi
}

# TODO: should we have functions for these?
#   kubectl wait --for=condition=available deployment --all --timeout=60s
#   kubectl wait --for=condition=Ready pod --all --timeout=60s

# Wait for rollout of named deployment
# usage: _wait_for_deployment <namespace> <deployment name>
_wait_for_deployment() {
    local namespace="$1"
    local name="$2"
    if ! kubectl -n "$namespace" rollout status deployment "$name" --timeout 5m; then
        echo "Failed rollout of deployment $name in namespace $namespace"
        exit 1
    fi
}

# Wait for Istio config to propagate
# usage: _wait_for_istio <kind> <namespace> <name>
_wait_for_istio() {
    local kind="$1"
    local namespace="$2"
    local name="$3"
    local start=$(date +%s)
# TODO: Put back when istioctl wait is functiuoning correctly
#    if ! istioctl experimental wait --for=distribution --timeout=10s "$kind" "$name.$namespace"; then
#        echo "Failed distribution of $kind $name in namespace $namespace"
#        istioctl ps
#        echo "TEST: wait for failed, but continuing."
#    fi
    echo "Duration: $(($(date +%s)-start)) seconds"
}

# Encode the string to a URL
_urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''$1'''))"
}
