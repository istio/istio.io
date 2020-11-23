#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2030,SC2031

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

# _set_kube_vars initializes the following variables based on the value of KUBECONFIG:
#
# KUBECONFIG_FILES: an array containing the individual files in the order specified.
# KUBE_CONTEXTS: the names of the kube contexts, in the order of the KUBECONFIG files specified.
function _set_kube_vars()
{
  # Split out the kube config files and then get the current context in
  # each. We do this because the contexts are stored in a map, which
  # means that order of the context returned by
  # `kubectl config get-contexts` is not guaranteed. By pulling out
  # the context on a per-file basis, we maintain the order of the
  # files in the KUBECONFIG variable.
  KUBE_CONTEXTS=()
  IFS=':' read -r -a KUBECONFIG_FILES <<< "${KUBECONFIG}"
  for KUBECONFIG_FILE in "${KUBECONFIG_FILES[@]}"; do
    CTX="$(export KUBECONFIG=$KUBECONFIG_FILE; kubectl config current-context)"
    if [[ -z "${CTX}" ]]; then
      echo "${KUBECONFIG_FILE} contains no current context"
      exit 1
    fi
    KUBE_CONTEXTS+=("${CTX}")
  done

  export KUBECONFIG_FILES
  export KUBE_CONTEXTS

  echo "KUBECONFIG=${KUBECONFIG}"
  echo "KUBECONFIG_FILES=${KUBECONFIG_FILES[*]}"
  echo "KUBE_CONTEXTS=${KUBE_CONTEXTS[*]}"
}

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
# usage: _wait_for_deployment <namespace> <deployment name> <optional: context>
_wait_for_deployment() {
    local namespace="$1"
    local name="$2"
    local context="${3:-}"
    if ! kubectl --context="$context" -n "$namespace" rollout status deployment "$name" --timeout 5m; then
        echo "Failed rollout of deployment $name in namespace $namespace"
        exit 1
    fi
}

# Wait for Istio config to propagate
# usage: _wait_for_istio <kind> <namespace> <name>
_wait_for_istio() {
# TODO: Put back when istioctl wait is functiuoning correctly
#    local kind="$1"
#    local namespace="$2"
#    local name="$3"
    local start=$(date +%s)
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
