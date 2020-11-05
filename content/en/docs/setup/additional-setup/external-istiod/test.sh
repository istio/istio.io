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

# @setup external-istiod

set -e
set -u
set -o pipefail

# Initialize KUBECONFIG_FILES and KUBE_CONTEXTS
_set_kube_vars

# set_clusters_env_vars initializes all variables.
function set_clusters_env_vars
{
  export KUBECONFIG_EXTERNAL_CLUSTER="${KUBECONFIG_FILES[0]}"
  export KUBECONFIG_REMOTE_CLUSTER="${KUBECONFIG_FILES[2]}"
  export CTX_EXTERNAL_CLUSTER="${KUBE_CONTEXTS[0]}"
  export CTX_REMOTE_CLUSTER="${KUBE_CONTEXTS[2]}"
}

function  set_remote_istiod_addr
{
  REMOTE_ADDR=$(kubectl \
    --context="${CTX_EXTERNAL_CLUSTER}" \
    -n istio-system get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  export REMOTE_ISTIOD_ADDR=$REMOTE_ADDR
}

snip_setup_the_external_control_plane_cluster_3_modified() {
cat <<EOF > external-istiod-gw.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
 name: external-istiod-gw
 namespace: external-istiod
spec:
 selector:
   istio: ingressgateway
 servers:
   - port:
       number: 15012
       protocol: tls
       name: tls-XDS
     tls:
       mode: PASSTHROUGH
     hosts:
     - "*"
   - port:
       number: 15017
       protocol: tls
       name: tls-WEBHOOK
     tls:
       mode: PASSTHROUGH
     hosts:
     - "*"
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
   name: external-istiod-vs
   namespace: external-istiod
spec:
   hosts:
   - "*"
   gateways:
   - external-istiod-gw
   tls:
   - match:
     - port: 15012
       sniHosts:
       - "*"     
     route:
     - destination:
         host: istiod.external-istiod.svc.cluster.local
         port:
           number: 15012
   - match:
     - port: 15017
       sniHosts:
       - "*"     
     route:
     - destination:
         host: istiod.external-istiod.svc.cluster.local
         port:
           number: 443
EOF
}

function install_istio_on_external_cp_cluster {
    echo "Installing Istio default profile on External control plane cluster: ${CTX_EXTERNAL_CLUSTER}"

    snip_setup_the_external_control_plane_cluster_1
    echo y | snip_setup_the_external_control_plane_cluster_2


    # echo "Waiting for the east-west gateway to have an external IP"
    # _verify_like snip_install_the_eastwest_gateway_in_cluster1_2 "$snip_install_the_eastwest_gateway_in_cluster1_2_out"

    echo "Exposing the to be installed istiod on the ingress gateway"
    snip_setup_the_external_control_plane_cluster_3_modified
    snip_setup_the_external_control_plane_cluster_4
}

snip_setup_remote_cluster_1_modified() {
cat <<EOF > remote-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
 meshConfig:
   rootNamespace: external-istiod
   defaultConfig:
     discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
     # proxyMetadata:
       # XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
       # CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
 components:
   pilot:
     enabled: false
   istiodRemote:
     enabled: true

 values:
   global:
     caAddress: $REMOTE_ISTIOD_ADDR:15012
     istioNamespace: external-istiod
   istiodRemote:
     injectionURL: https://$REMOTE_ISTIOD_ADDR:15017/inject
   base:
     validationURL: https://REMOTE_ISTIOD_ADDR:15017/validate
EOF
}

function install_istio_lite_on_remote_cluster {
    echo "Installing Istio on remote config cluster: ${CTX_REMOTE_CLUSTER}"

    snip_setup_remote_cluster_1_modified
    echo y | snip_setup_remote_cluster_2
}

snip_setup_external_istiod_in_the_control_plane_cluster_2_modified() {
cat <<EOF > external-istiod.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
 meshConfig:
   defaultConfig:
     discoveryAddress: $REMOTE_ISTIOD_ADDR:15012
     rootNamespace: external-istiod
     # proxyMetadata:
       # XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
       # CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
 components:
   base:
     enabled: false
   ingressGateways:
   - name: istio-ingressgateway
     enabled: false
 values:
   global:
     caAddress: $REMOTE_ISTIOD_ADDR:15012
     istioNamespace: external-istiod
     operatorManageWebhooks: true
   pilot:
     env:
       ISTIOD_CUSTOM_HOST: $REMOTE_ISTIOD_ADDR
EOF
}

function install_external_istiod_on_external_cp_cluster {
  echo "Installing external Istiod on external control plane cluster: ${CTX_EXTERNAL_CLUSTER}"

  snip_setup_external_istiod_in_the_control_plane_cluster_1
  snip_setup_external_istiod_in_the_control_plane_cluster_2_modified
  echo y | snip_setup_the_external_control_plane_cluster_2
}

function validate {
  snip_validate_the_installation_1
  snip_validate_the_installation_2
  snip_validate_the_installation_3

  # set GATEWAY_URL
  URL=$(kubectl \
    --context="${CTX_REMOTE_CLUSTER}" \
    -n external-istiod get svc istio-ingressgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  export GATEWAY_URL=$URL
  # validate Hello at the response
  snip_validate_the_installation_4
}

function cleanup {
  kubectl delete -f samples/helloworld/helloworld.yaml --context="${CTX_REMOTE_CLUSTER}"
  kubectl delete -f samples/helloworld/helloworld-gateway.yaml --context="${CTX_REMOTE_CLUSTER}"
  
  istioctl manifest generate -f remote-config-cluster.yaml | kubectl delete --context="${CTX_REMOTE_CLUSTER}" -f - 
  istioctl manifest generate -f external-istiod.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f - 
  istioctl manifest generate -f external-istiod-gw.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f - 
  istioctl manifest generate -f external-cp.yaml | kubectl delete --context="${CTX_EXTERNAL_CLUSTER}" -f - 
}

set_clusters_env_vars

# install
time install_istio_on_external_cp_cluster
time set_remote_istiod_addr
time install_istio_lite_on_remote_cluster
time install_external_istiod_on_external_cp_cluster

#validate
time validate

# @cleanup
set +e # ignore cleanup errors
time cleanup

# Everything should be removed once cleanup completes. Use a small
# timeout for comparing cluster snapshots before/after the test.
export VERIFY_TIMEOUT=20
