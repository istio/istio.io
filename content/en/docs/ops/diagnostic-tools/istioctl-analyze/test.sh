#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154

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

set -e  # Exit on failure
set -u  # Unset is an error
# There is no need to echo, output appears in ops_diagnostic-tools_istioctl-analyze_test_debug.txt
set -o pipefail

# Use 'at' setup profile=default to install default profile?
# This script doesn't need a control plane, but we need base CRDs
# @setup profile=none

# This command is allowed to fail
snip_analyze_all_namespaces || true

# The following step is 'usually' done by cleanup.  Do it here, just in case
kubectl delete vs ratings || true

snip_analyze_sample_destrule

# TODO Check the output on failure for 'Referenced host+subset in destinationrule not found: "details+v2"' 
_verify_failure snip_analyze_networking_directory

snip_analyze_all_networking_yaml

snip_analyze_all_networking_yaml_no_kube

istioctl analyze --help

# TODO Is it safe to install testing Istio with custom config here?
# TODO Uncomment?
# snip_install_with_custom_config_analysis

set +e  # Don't exit on failure
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
  namespace: default
spec:
  gateways:
  - bogus-gateway
  hosts:
  - ratings
  http:
  - route:
    - destination:
        host: ratings
        subset: v1
EOF
set -e  # Exit on failure

kubectl get vs ratings -o yaml
# TODO scrape the above output for 'Referenced gateway not found: "bogus-gateway"'

kubectl create ns frod

_verify_failure analyze_k_frod
# TODO Replace the above with _verify_failure_same when it is available
# _verify_same analyze_k_frod "$snip_analyze_k_frod_out"

_verify_same snip_analyze_suppress0102 "$snip_analyze_suppress0102_out"

# TODO This will return errors on non-Istio namespaces, e.g. ibm-cert-store and kube-node-lease
# It is hard to know what to supply to fix that problem for testing.
snip_analyze_suppress_frod_0107_baz || true

kubectl create deployment my-deployment --image=docker.io/kennethreitz/httpbin

snip_annotate_for_deployment_suppression

kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress-
snip_annotate_for_deployment_suppression_107

# @cleanup
set +e # ignore cleanup errors
snip_cleanup_1
kubectl delete ns frod || true
kubectl delete deployment my-deployment || true
