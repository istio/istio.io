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

# Override some snip functions to configure the istiod gateway using TLS passthrough in the test environemnt.

snip_get_external_istiod_iop_modified() {
    snip_get_external_istiod_iop

    # Update config file: delete CA certificates and meshID, and update pilot vars
    # TODO(https://github.com/istio/istio/issues/31690) remove 'env' replace
    sed -i \
        -e '/proxyMetadata:/,+2d' \
        -e '/INJECTION_WEBHOOK_CONFIG_NAME/,+1d' \
        -e "/VALIDATION_WEBHOOK_CONFIG_NAME/,+1d" \
        external-istiod.yaml
}

snip_get_external_istiod_gateway_config_modified() {
    TMP="$EXTERNAL_ISTIOD_ADDR"
    EXTERNAL_ISTIOD_ADDR='"*"'
    snip_get_external_istiod_gateway_config

    # Update config file: delete the DestinationRule, don't terminate TLS in the Gateway, and use TLS routing in the VirtualService
    sed -i \
        -e '55,$d' \
        -e 's/mode: SIMPLE/mode: PASSTHROUGH/' -e '/credentialName:/d' \
        -e 's/http:/tls:/' -e 's/https/tls/' -e "/route:/i\        sniHosts:\n        - ${EXTERNAL_ISTIOD_ADDR}" \
        external-istiod-gw.yaml
    EXTERNAL_ISTIOD_ADDR="$TMP"
}

# Set the CTX_EXTERNAL_CLUSTER, CTX_REMOTE_CLUSTER, and REMOTE_CLUSTER_NAME env variables.

_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
export REMOTE_CLUSTER_NAME="${CTX_REMOTE_CLUSTER}"

# Set up the istiod gateway in the external cluster.

snip_set_up_a_gateway_in_the_external_cluster_1
echo y | snip_set_up_a_gateway_in_the_external_cluster_2

_verify_like snip_set_up_a_gateway_in_the_external_cluster_3 "$snip_set_up_a_gateway_in_the_external_cluster_3_out"

export SSL_SECRET_NAME="UNUSED"
export EXTERNAL_ISTIOD_ADDR=$(kubectl \
    --context="${CTX_EXTERNAL_CLUSTER}" \
    -n istio-system get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Set up the remote cluster.

snip_get_remote_config_cluster_iop

#set +e #ignore failures here
echo y | snip_set_up_the_remote_config_cluster_2
#set -e

_verify_like snip_set_up_the_remote_config_cluster_3 "$snip_set_up_the_remote_config_cluster_3_out"

# Install istiod on the external cluster.

snip_set_up_the_control_plane_in_the_external_cluster_1
snip_set_up_the_control_plane_in_the_external_cluster_2

snip_get_external_istiod_iop_modified
echo y | istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}" --set values.pilot.env.ISTIOD_CUSTOM_HOST="${EXTERNAL_ISTIOD_ADDR}"

_verify_like snip_set_up_the_control_plane_in_the_external_cluster_5 "$snip_set_up_the_control_plane_in_the_external_cluster_5_out"

snip_get_external_istiod_gateway_config_modified
snip_set_up_the_control_plane_in_the_external_cluster_7

# Validate the installation.

snip_deploy_a_sample_application_1
snip_deploy_a_sample_application_2

_verify_like snip_deploy_a_sample_application_3 "$snip_deploy_a_sample_application_3_out"

_verify_contains snip_deploy_a_sample_application_4 "Hello version: v1"

echo y | snip_enable_gateways_1
#echo y | snip_enable_gateways_2

_verify_like snip_enable_gateways_3 "$snip_enable_gateways_3_out"

snip_enable_gateways_4

export GATEWAY_URL=$(kubectl \
    --context="${CTX_REMOTE_CLUSTER}" \
    -n external-istiod get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

_verify_contains snip_enable_gateways_6 "Hello version: v1"

# Adding clusters to the mesh.

export CTX_SECOND_CLUSTER="${KUBE_CONTEXTS[1]}"
export SECOND_CLUSTER_NAME="${CTX_SECOND_CLUSTER}"

snip_get_second_config_cluster_iop
echo y | snip_register_the_new_cluster_2

# Confirm remote cluster’s webhook configuration has been installed
_verify_like snip_register_the_new_cluster_3 "$snip_register_the_new_cluster_3_out"

# Create a secret with credentials to allow the control plane to access the endpoints on the second remote cluster and install it
snip_register_the_new_cluster_4

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
_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
export CTX_SECOND_CLUSTER="${KUBE_CONTEXTS[1]}"

# TODO put the cleanup instructions in the doc and then call the snips.
kubectl delete ns sample --context="${CTX_REMOTE_CLUSTER}"
kubectl delete ns sample --context="${CTX_SECOND_CLUSTER}"

kubectl delete -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"

istioctl manifest generate -f remote-config-cluster.yaml | kubectl delete --context="${CTX_REMOTE_CLUSTER}" -f -
istioctl manifest generate -f second-config-cluster.yaml | kubectl delete --context="${CTX_SECOND_CLUSTER}" -f -
istioctl manifest generate -f external-istiod.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f -
istioctl manifest generate -f controlplane-gateway.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f -
istioctl manifest generate -f eastwest-gateway-1.yaml | kubectl delete --context="${CTX_REMOTE_CLUSTER}" -f - 
istioctl manifest generate -f eastwest-gateway-2.yaml | kubectl delete --context="${CTX_SECOND_CLUSTER}" -f - 

kubectl delete ns istio-system external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
kubectl delete ns external-istiod --context="${CTX_REMOTE_CLUSTER}"
kubectl delete ns external-istiod --context="${CTX_SECOND_CLUSTER}"
kubectl delete ns istio-system --context="${CTX_REMOTE_CLUSTER}" # TODO: remove when https://github.com/istio/istio/issues/31495 fixed

rm external-istiod-gw.yaml remote-config-cluster.yaml external-istiod.yaml controlplane-gateway.yaml eastwest-gateway-1.yaml eastwest-gateway-2.yaml second-config-cluster.yaml
