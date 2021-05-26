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

snip_set_up_a_gateway_in_the_external_cluster_4_modified() {
    snip_set_up_a_gateway_in_the_external_cluster_4

    # Update config file: delete the DestinationRule, don't terminate TLS in the Gateway, and use TLS routing in the VirtualService
    sed -i \
        -e '55,$d' \
        -e 's/mode: SIMPLE/mode: PASSTHROUGH/' -e '/credentialName:/d' \
        -e 's/http:/tls:/' -e 's/https/tls/' -e "/route:/i\        sniHosts:\n        - ${EXTERNAL_ISTIOD_ADDR}" \
        external-istiod-gw.yaml
}

snip_set_up_the_remote_cluster_1_modified() {
    snip_set_up_the_remote_cluster_1

    # Update config file: delete CA certificates and meshID
    sed -i \
        -e '/proxyMetadata:/,+2d' \
        remote-config-cluster.yaml
}

snip_set_up_the_control_plane_in_the_external_cluster_2_modified() {
    snip_set_up_the_control_plane_in_the_external_cluster_2

    # Update config file: delete CA certificates and meshID, and update pilot vars
    sed -i \
        -e '/proxyMetadata:/,+2d' \
        -e '/INJECTION_WEBHOOK_CONFIG_NAME: ""/d' \
        -e "s/VALIDATION_WEBHOOK_CONFIG_NAME: \"\"/ISTIOD_CUSTOM_HOST: ${EXTERNAL_ISTIOD_ADDR}/" \
        external-istiod.yaml
}

# Set the CTX_EXTERNAL_CLUSTER, CTX_REMOTE_CLUSTER, and REMOTE_CLUSTER_NAME env variables.

_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
export REMOTE_CLUSTER_NAME="${CTX_REMOTE_CLUSTER}"

# Set up the istiod gateway in the external cluster.

snip_set_up_a_gateway_in_the_external_cluster_1
echo y | snip_set_up_a_gateway_in_the_external_cluster_2

export SSL_SECRET_NAME="UNUSED"
export EXTERNAL_ISTIOD_ADDR="\"*\""
snip_set_up_a_gateway_in_the_external_cluster_4_modified
snip_set_up_a_gateway_in_the_external_cluster_5

# Set up the remote cluster.

export EXTERNAL_ISTIOD_ADDR=$(kubectl \
    --context="${CTX_EXTERNAL_CLUSTER}" \
    -n istio-system get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
snip_set_up_the_remote_cluster_1_modified

set +e #ignore failures here
echo y | snip_set_up_the_remote_cluster_2
set -e

# Install istiod on the external cluster.

snip_set_up_the_control_plane_in_the_external_cluster_1
snip_set_up_the_control_plane_in_the_external_cluster_2_modified
echo y | snip_set_up_the_control_plane_in_the_external_cluster_3

# Validate the installation.

_verify_contains snip_validate_the_installation_1 "Running"

snip_validate_the_installation_2
snip_validate_the_installation_3

export GATEWAY_URL=$(kubectl \
    --context="${CTX_REMOTE_CLUSTER}" \
    -n external-istiod get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

_verify_contains snip_validate_the_installation_4 "Hello"

# @cleanup
_set_kube_vars # helper function to initialize KUBECONFIG_FILES and KUBE_CONTEXTS
export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"

# TODO put the cleanup instructions in the doc and then call the snips.
kubectl delete -f samples/helloworld/helloworld.yaml --context="${CTX_REMOTE_CLUSTER}"
kubectl delete -f samples/helloworld/helloworld-gateway.yaml --context="${CTX_REMOTE_CLUSTER}"

kubectl delete -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"

istioctl manifest generate -f remote-config-cluster.yaml | kubectl delete --context="${CTX_REMOTE_CLUSTER}" -f -
istioctl manifest generate -f external-istiod.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f -
istioctl manifest generate -f controlplane-gateway.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f -

kubectl delete ns istio-system external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
kubectl delete ns external-istiod --context="${CTX_REMOTE_CLUSTER}"

rm external-istiod-gw.yaml remote-config-cluster.yaml external-istiod.yaml controlplane-gateway.yaml
