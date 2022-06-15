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

# This script doesn't need a control plane initially and will install Istio when needed
# @setup profile=none

# The test harness labels the default namespace.  Remove that label
# so the output matches the expect output on a fresh K8s cluster.
kubectl label namespace default istio-injection- || true

echo '*** istioctl-analyze step 1 ***'
_verify_contains snip_analyze_all_namespaces "$snip_analyze_all_namespace_sample_response"

echo '*** istioctl-analyze step 2 ***'
snip_fix_default_namespace
_verify_contains snip_try_with_fixed_namespace "$snip_try_with_fixed_namespace_out"

echo '*** istioctl-analyze step 3 ***'
_verify_contains snip_analyze_sample_destrule "$snip_analyze_sample_destrule_out"

# There are multiple DestinationRules, some are valid for the VirtualService, some lack subsets
echo '*** istioctl-analyze step 4 ***'
snip_analyze_networking_directory || true

echo '*** istioctl-analyze step 5 ***'
snip_analyze_all_networking_yaml

echo '*** istioctl-analyze step 6 ***'
snip_analyze_all_networking_yaml_no_kube

echo '*** istioctl-analyze step 7 ***'
istioctl analyze --help

echo '*** istioctl-analyze step 8 ***'
echo y | snip_install_with_custom_config_analysis
_wait_for_deployment istio-system istiod

echo '*** istioctl-analyze step 9 ***'
set +e  # Don't exit on failure
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
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
EOF
set -e  # Exit on failure

echo '*** istioctl-analyze step 10 ***'
get_ratings_virtual_service() {
kubectl get vs ratings -o yaml
}
_verify_elided get_ratings_virtual_service "$snip_vs_yaml_with_status"

echo '*** istioctl-analyze step 11 ***'
kubectl create ns frod
_verify_contains snip_analyze_k_frod "$snip_analyze_k_frod_out"

echo '*** istioctl-analyze step 12 ***'
_verify_contains snip_analyze_suppress0102 "$snip_analyze_suppress0102_out"

echo '*** istioctl-analyze step 13 ***'
_verify_lines snip_analyze_suppress_frod_0107_baz "- Info [IST0102] (Namespace frod) The namespace is not enabled for Istio injection. Run 'kubectl label namespace frod istio-injection=enabled' to enable it, or 'kubectl label namespace frod istio-injection=disabled' to explicitly mark it as not needing injection."

echo '*** istioctl-analyze step 14 ***'
kubectl create deployment my-deployment --image=docker.io/kennethreitz/httpbin
snip_annotate_for_deployment_suppression

echo '*** istioctl-analyze step 15 ***'
kubectl annotate deployment my-deployment galley.istio.io/analyze-suppress-
snip_annotate_for_deployment_suppression_107

# @cleanup
kubectl label namespace default istio-injection-
kubectl delete ns frod
kubectl delete deployment my-deployment
kubectl delete vs ratings
# Delete the Istio this test installed
kubectl delete ValidatingWebhookConfiguration istiod-istio-system
kubectl get mutatingwebhookconfigurations -o custom-columns=NAME:.metadata.name --no-headers | xargs kubectl delete mutatingwebhookconfigurations
kubectl delete ns istio-system
