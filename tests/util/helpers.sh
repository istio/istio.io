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

# Normalize INGRESS_HOST for IPv6: wrap bare IPv6 addresses in brackets for correct
# URL and curl --resolve formatting.
_normalize_ingress_host() {
    if [[ -n "${INGRESS_HOST:-}" && "$INGRESS_HOST" == *:* && "$INGRESS_HOST" != \[* ]]; then
        export INGRESS_HOST="[$INGRESS_HOST]"
    fi
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
    _normalize_ingress_host
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

# Wait for rollout of named daemonset
# usage: _wait_for_daemonset <namespace> <daemonset name> <optional: context>
_wait_for_daemonset() {
    local namespace="$1"
    local name="$2"
    local context="${3:-}"
    if ! kubectl --context="$context" -n "$namespace" rollout status daemonset "$name" --timeout 5m; then
        echo "Failed rollout of daemonset $name in namespace $namespace"
        exit 1
    fi
}

# Wait for rollout of named statefulset
# usage: _wait_for_statefulset <namespace> <statefulset name> <optional: context>
_wait_for_statefulset() {
    local namespace="$1"
    local name="$2"
    local context="${3:-}"
    if ! kubectl --context="$context" -n "$namespace" rollout status statefulset "$name" --timeout 5m; then
        echo "Failed rollout of statefulset $name in namespace $namespace"
        exit 1
    fi
}

# Wait for resource to be created
# usage: _wait_for_resource <kind> <namespace> <name>
_wait_for_resource() {
    local kind="$1"
    local namespace="$2"
    local name="$3"
    local start_time=$(date +%s)
    if ! kubectl wait --for=create -n "$namespace" "$kind/$name" --timeout 30s; then
        local end_time=$(date +%s)
        echo "Timed out waiting for $kind $name in namespace $namespace to be created."
        echo "Duration: $(( end_time - start_time )) seconds"
        return 1
    fi
    sleep 2s
}

# Wait for named Gateway API gateway to be ready
# usage: _wait_for_gateway <namespace> <gateway name> <optional: context>
_wait_for_gateway() {
    local namespace="$1"
    local name="$2"
    local context="${3:-}"
    if ! kubectl --context="$context" -n "$namespace" wait --for=condition=programmed gtw "$name" --timeout=2m; then
        echo "Failed to deploy gateway $name in namespace $namespace"
        exit 1
    fi
}

# Encode the string to a URL
_urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''$1'''))"
}

# Invokes bash make to rewrite a snippet to avoid installing from a real helm repository, and instead uses
# local files
# usage: _rewrite_helm_repo <commands>
# shellcheck disable=SC2001
_rewrite_helm_repo() {
  # get function definition: https://stackoverflow.com/a/6916952/374797
  cmd="$(type "${1:?snip}" | sed '1,3d;$d')"
  cmd="$(echo "${cmd}" | sed 's|istio/base|manifests/charts/base|')"
  cmd="$(echo "${cmd}" | sed 's|istio/istiod|manifests/charts/istio-control/istio-discovery|')"
  cmd="$(echo "${cmd}" | sed 's|istio/cni|manifests/charts/istio-cni|')"
  cmd="$(echo "${cmd}" | sed 's|istio/ztunnel|manifests/charts/ztunnel|')"
  cmd="$(echo "${cmd}" | sed 's|istio/gateway|manifests/charts/gateway|')"
  cmd="$(echo "${cmd}" | sed 's|istio/ambient|manifests/sample-charts/ambient|')"
  cmd="$(echo "${cmd}" | sed -E "s|(helm[[:space:]]+[^[:space:]]+)|\1 --set global.tag=${ISTIO_IMAGE_VERSION=SHOULD_BE_SET}.${ISTIO_LONG_SHA=latest}|g")"
  # Since we are using local charts here, we may need to manually rebundle the updates
  # This is not required if installing directly from a real Helm repo
  if [[ $cmd =~ "manifests/sample-charts/ambient" ]]; then
    pushd manifests/sample-charts/ambient && helm dep update
    popd || exit
  fi

  eval "${cmd}"
}

# Pre-generated JWT tokens for docs tests, signed with security/tools/jwt/samples/key.pem.
# demo.jwt: exp 4685989700 (year 2118), iss testing@secure.istio.io, foo=bar
# shellcheck disable=SC2034
_DOCS_DEMO_JWT="eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNnxWP2tcnR9q0vxyxweaF3ovQYHYZl82hAUsn21bwQd9zP7c-LS9qd_vpdLG4Tn1A15NxfCjp5f7QNBUo-KC9PJqYpgGbaXhaGx7bEdFWjcwv3nZzvc7M__ZpaCERdwU7igUmJqYGBYQ51vr2njU9ZimyKkfDe3axcyiBZde7G6dabliUosJvvKOPcKIWPccCgefSj_GNfwIip3-SsFdlR7BtbVUcqR-yv-XOxJ3Uc1MI0tz3uMiiZcyPV7sNCU4KRnemRIMHVOfuvHsU60_GhGbiSFzgPTAa9WTltbnarTbxudb_YEOx12JiwYToeX0DCPb43W1tzIBxgm8NxUg"

# groups-scope.jwt: exp 3537391104 (year 2082), iss testing@secure.istio.io, groups=[group1,group2]
# shellcheck disable=SC2034
_DOCS_GROUPS_SCOPE_JWT="eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjM1MzczOTExMDQsImdyb3VwcyI6WyJncm91cDEiLCJncm91cDIiXSwiaWF0IjoxNTM3MzkxMTA0LCJpc3MiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyIsInNjb3BlIjpbInNjb3BlMSIsInNjb3BlMiJdLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.EdJnEZSH6X8hcyEii7c8H5lnhgjB5dwo07M5oheC8Xz8mOllyg--AHCFWHybM48reunF--oGaG6IXVngCEpVF0_P5DwsUoBgpPmK1JOaKN6_pe9sh0ZwTtdgK_RP01PuI7kUdbOTlkuUi2AO-qUyOm7Art2POzo36DLQlUXv8Ad7NBOqfQaKjE9ndaPWT7aexUsBHxmgiGbz1SyLH879f7uHYPbPKlpHU6P9S-DaKnGLaEchnoKnov7ajhrEhGXAQRukhDPKUHO9L30oPIr5IJllEQfHYtt6IZvlNUGeLUcif3wpry1R5tBXRicx2sXMQ7LyuDremDbcNy_iE76Upg"

# Rewrite a snip to replace external jwksUri with an inline jwks value, avoiding
# external network fetches for JWT public keys. Also rewrites inline curl calls
# that fetch static JWT token files from raw.githubusercontent.com.
# raw.githubusercontent.com is unreachable in IPv6-only Kind clusters because
# Docker's embedded DNS is IPv4-only (kubernetes-sigs/kind#3114).
# usage: _rewrite_jwks_uri <snip_function>
# shellcheck disable=SC2001
_rewrite_jwks_uri() {
  local _docs_jwks='{"keys":[{"e":"AQAB","kid":"DHFbpoIUqrY8t2zpA2qXfCmr5VO5ZEr4RzHU_-envvQ","kty":"RSA","n":"xAE7eB6qugXyCAG3yhh7pkDkT65pHymX-P7KfIupjf59vsdo91bSP9C8H07pSAGQO1MV_xFj9VswgsCg4R6otmg5PV2He95lZdHtOcU5DXIg_pbhLdKXbi66GlVeK6ABZOUW3WYtnNHD-91gVuoeJT_DwtGGcp4ignkgXfkiEm4sw-4sfb4qdt5oLbyVpmW6x9cfa7vs2WTfURiCrBoUqgBo_-4WTiULmmHSGZHOjzwa8WtrtOQGsAFjIbno85jp6MnGGGZPYZbDAa_b3y5u-YpW7ypZrvD8BgtKVjgtQgZhLAGezMt0ua3DRrWnKqTZ0BJ_EyxOGuHJrLsn00fnMQ"}]}'
  cmd="$(type "${1:?snip}" | sed '1,3d;$d')"
  # Replace jwksUri pointing to raw.githubusercontent.com with inline jwks
  cmd="$(echo "${cmd}" | sed "s|jwksUri: \"https://raw\.githubusercontent\.com/[^\"]*jwks\.json\"|jwks: '${_docs_jwks}'|g")"
  # Replace inline curl fetches of demo.jwt with the pre-generated token
  cmd="$(echo "${cmd}" | sed "s|curl https://raw\.githubusercontent\.com/[^ ]*/demo\.jwt -s|echo \"${_DOCS_DEMO_JWT}\"|g")"
  # Replace wget fetches of gen-jwt.py and key.pem with copies from tests/util/
  # (populated by bin/init.sh from security/tools/jwt/samples/ in the istio repo)
  cmd="$(echo "${cmd}" | sed "s|wget --no-verbose https://raw\.githubusercontent\.com/[^ ]*/gen-jwt\.py|cp \"\${REPO_ROOT}/tests/util/gen-jwt.py\" . #|g")"
  cmd="$(echo "${cmd}" | sed "s|wget --no-verbose https://raw\.githubusercontent\.com/[^ ]*/key\.pem|cp \"\${REPO_ROOT}/tests/util/key.pem\" . #|g")"
  eval "${cmd}"
}

# Skip the current test if running on an IPv6-only Kind cluster. In such clusters
# there is no IPv6 internet connectivity because Docker's embedded DNS is IPv4-only
# (kubernetes-sigs/kind#3114). Pass a short reason string to describe what the
# test requires (e.g. "test requires internet egress").
# usage: _skip_if_kind_ipv6 <reason>
_skip_if_kind_ipv6() {
  if [[ "${KIND_IP_FAMILY:-}" == "ipv6" ]]; then
    echo "Skipping (KIND_IP_FAMILY=ipv6): ${1:?reason} (no IPv6 internet connectivity in Kind; kubernetes-sigs/kind#3114)"
    exit 0
  fi
}

# Rewrite a snip to replace oci://ghcr.io/ OCI registry URLs with the local
# kind-registry when running in IPv6-only Kind CI. ghcr.io is unreachable because
# Docker's embedded DNS is IPv4-only (kubernetes-sigs/kind#3114).
# The kind-registry must be pre-seeded with the required images via crane copy
# in prow/integ-suite-kind.sh before tests run.
# usage: _rewrite_oci_registry <snip_function>
# shellcheck disable=SC2001
_rewrite_oci_registry() {
  if [[ "${KIND_IP_FAMILY:-}" != "ipv6" ]]; then
    "${1:?snip}"
    return
  fi
  local registry="kind-registry:${KIND_REGISTRY_PORT:-5000}"
  cmd="$(type "${1:?snip}" | sed '1,3d;$d')"
  cmd="$(echo "${cmd}" | sed "s|oci://ghcr\.io/|oci://${registry}/|g")"
  eval "${cmd}"
}
