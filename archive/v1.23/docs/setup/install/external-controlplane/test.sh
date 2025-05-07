#!/usr/bin/env bash
# shellcheck disable=SC1090,SC2154,SC2155

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

# @setup multicluster

set -e
set -u
set -o pipefail

GATEWAY_API="${GATEWAY_API:-false}"

kubectl_get_egress_gateway_for_remote_cluster() {
  kubectl get pod -l app=istio-egressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}" -o jsonpath="{.items[*].status.phase}"
}

kubectl_get_external_cluster_webhooks() {
  kubectl get mutatingwebhookconfiguration --context="${CTX_EXTERNAL_CLUSTER}"
}

# Set the CTX_EXTERNAL_CLUSTER, CTX_REMOTE_CLUSTER, and REMOTE_CLUSTER_NAME env variables.

if [ "$GATEWAY_API" != "true" ]; then
  _set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
  export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
  export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
  export REMOTE_CLUSTER_NAME="${CTX_REMOTE_CLUSTER}"
fi

# Set up the istiod gateway in the external cluster.

snip_set_up_a_gateway_in_the_external_cluster_1
echo y | snip_set_up_a_gateway_in_the_external_cluster_2

_verify_like snip_set_up_a_gateway_in_the_external_cluster_3 "$snip_set_up_a_gateway_in_the_external_cluster_3_out"

snip_set_up_a_gateway_in_the_external_cluster_6

# Set up the remote cluster.

snip_get_remote_config_cluster_iop
snip_set_up_the_remote_config_cluster_2

#set +e #ignore failures here
echo y | snip_set_up_the_remote_config_cluster_3
#set -e

_verify_like snip_set_up_the_remote_config_cluster_4 "$snip_set_up_the_remote_config_cluster_4_out"

mod_snip_set_up_the_remote_config_cluster_5() {
    out=$(snip_set_up_the_remote_config_cluster_5 | grep -v metallb)
    echo "$out"
}
_verify_like mod_snip_set_up_the_remote_config_cluster_5 "$snip_set_up_the_remote_config_cluster_5_out"

# Install istiod on the external cluster.

snip_set_up_the_control_plane_in_the_external_cluster_1
snip_set_up_the_control_plane_in_the_external_cluster_2

snip_get_external_istiod_iop
snip_set_up_the_control_plane_in_the_external_cluster_4

echo y | snip_set_up_the_control_plane_in_the_external_cluster_5

_verify_not_contains kubectl_get_external_cluster_webhooks "external-istiod" # external istiod install should not affect local webhooks

_verify_like snip_set_up_the_control_plane_in_the_external_cluster_6 "$snip_set_up_the_control_plane_in_the_external_cluster_6_out"

snip_get_external_istiod_gateway_config
snip_set_up_the_control_plane_in_the_external_cluster_8

snip_set_up_the_control_plane_in_the_external_cluster_9

# Validate the installation.

snip_deploy_a_sample_application_1
snip_deploy_a_sample_application_2

_verify_like snip_deploy_a_sample_application_3 "$snip_deploy_a_sample_application_3_out"

_verify_contains snip_deploy_a_sample_application_4 "Hello version: v1"

# Install ingress with istioctl
echo y | snip_enable_gateways_1

# And egress with helm
_rewrite_helm_repo snip_enable_gateways_4

_verify_same kubectl_get_egress_gateway_for_remote_cluster "Running"

if [ "$GATEWAY_API" == "true" ]; then
  snip_configure_and_test_an_ingress_gateway_4
  snip_configure_and_test_an_ingress_gateway_6
else
  _verify_like snip_configure_and_test_an_ingress_gateway_1 "$snip_configure_and_test_an_ingress_gateway_1_out"

  snip_configure_and_test_an_ingress_gateway_3

  #snip_configure_and_test_an_ingress_gateway_5
  export GATEWAY_URL=$(kubectl \
      --context="${CTX_REMOTE_CLUSTER}" \
      -n external-istiod get svc istio-ingressgateway \
      -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

_verify_contains snip_configure_and_test_an_ingress_gateway_7 "Hello version: v1"

# Adding clusters to the mesh.

export CTX_SECOND_CLUSTER="${KUBE_CONTEXTS[1]}"
export SECOND_CLUSTER_NAME="${CTX_SECOND_CLUSTER}"

snip_get_second_remote_cluster_iop
snip_register_the_new_cluster_2

snip_register_the_new_cluster_3
echo y | snip_register_the_new_cluster_4

# Confirm remote cluster’s webhook configuration has been installed
_verify_contains snip_register_the_new_cluster_5 "istio-sidecar-injector-external-istiod"

# Create a secret with credentials to allow the control plane to access the endpoints on the second remote cluster and install it
snip_register_the_new_cluster_6

# Setup east-west gateways
snip_setup_eastwest_gateways_1
snip_setup_eastwest_gateways_2

_verify_like snip_setup_eastwest_gateways_3 "$snip_setup_eastwest_gateways_3_out"
_verify_like snip_setup_eastwest_gateways_4 "$snip_setup_eastwest_gateways_4_out"

snip_setup_eastwest_gateways_5

# Validate the installation.
snip_validate_the_installation_1
snip_validate_the_installation_2
_verify_like snip_validate_the_installation_3 "$snip_validate_the_installation_3_out"
_verify_contains snip_validate_the_installation_4 "Hello version:"
_verify_lines snip_validate_the_installation_5 "
+ Hello version: v1
+ Hello version: v2
"

# @cleanup
if [ "$GATEWAY_API" != "true" ]; then
  _set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
  export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
  export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
  export CTX_SECOND_CLUSTER="${KUBE_CONTEXTS[1]}"

  snip_cleanup_1
  snip_cleanup_2
  snip_cleanup_3
fi
