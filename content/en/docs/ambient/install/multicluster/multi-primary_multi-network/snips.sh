#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

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
#          docs/ambient/install/multicluster/multi-primary_multi-network/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-install-crds.sh"

snip_set_the_default_network_for_cluster1_1() {
kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=network1
}

snip_configure_cluster1_as_a_primary_1() {
cat <<EOF > cluster1.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster1
      network: network1
EOF
}

snip_configure_cluster1_as_a_primary_2() {
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_configure_cluster1_as_a_primary_3() {
helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER1}"
}

snip_configure_cluster1_as_a_primary_4() {
helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
}

snip_install_cni_cluster1() {
helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER1}" --set profile=ambient
}

snip_install_ztunnel_cluster1() {
helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}" --set multiCluster.clusterName=cluster1 --set global.network=network1
}

snip_install_an_ambient_eastwest_gateway_in_cluster1_1() {
samples/multicluster/gen-eastwest-gateway.sh \
    --network network1 \
    --ambient | \
    kubectl --context="${CTX_CLUSTER1}" apply -f -
}

snip_install_an_ambient_eastwest_gateway_in_cluster1_2() {
cat <<EOF > cluster1-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network1"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
}

snip_install_an_ambient_eastwest_gateway_in_cluster1_3() {
kubectl apply --context="${CTX_CLUSTER1}" -f cluster1-ewgateway.yaml
}

snip_install_an_ambient_eastwest_gateway_in_cluster1_4() {
kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
}

! IFS=$'\n' read -r -d '' snip_install_an_ambient_eastwest_gateway_in_cluster1_4_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
ENDSNIP

snip_set_the_default_network_for_cluster2_1() {
kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=network2
}

snip_configure_cluster2_as_a_primary_1() {
cat <<EOF > cluster2.yaml
apiVersion: insall.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: ambient
  components:
    pilot:
      k8s:
        env:
          - name: AMBIENT_ENABLE_MULTI_NETWORK
            value: "true"
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF
}

snip_configure_cluster2_as_a_primary_2() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_configure_cluster2_as_a_primary_3() {
helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
}

snip_configure_cluster2_as_a_primary_4() {
helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network2 --set profile=ambient --set env.AMBIENT_ENABLE_MULTI_NETWORK="true"
}

snip_install_cni_cluster2() {
helm install istio-cni istio/cni -n istio-system --kube-context "${CTX_CLUSTER2}" --set profile=ambient
}

snip_install_ztunnel_cluster2() {
helm install ztunnel istio/ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"  --set multiCluster.clusterName=cluster2 --set global.network=network2
}

snip_install_an_ambient_eastwest_gateway_in_cluster2_1() {
samples/multicluster/gen-eastwest-gateway.sh \
    --network network2 \
    --ambient | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
}

snip_install_an_ambient_eastwest_gateway_in_cluster2_2() {
cat <<EOF > cluster2-ewgateway.yaml
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: istio-eastwestgateway
  namespace: istio-system
  labels:
    topology.istio.io/network: "network2"
spec:
  gatewayClassName: istio-east-west
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
    tls:
      mode: Terminate # represents double-HBONE
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
EOF
}

snip_install_an_ambient_eastwest_gateway_in_cluster2_3() {
kubectl apply --context="${CTX_CLUSTER2}" -f cluster2-ewgateway.yaml
}

snip_install_an_ambient_eastwest_gateway_in_cluster2_4() {
kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system
}

! IFS=$'\n' read -r -d '' snip_install_an_ambient_eastwest_gateway_in_cluster2_4_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
ENDSNIP

snip_enable_endpoint_discovery_1() {
istioctl create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
}

snip_enable_endpoint_discovery_2() {
istioctl create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
}

snip_cleanup_3() {
helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER1}"
helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER1}"
helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
}

snip_cleanup_4() {
kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
}

snip_cleanup_5() {
helm delete ztunnel -n istio-system --kube-context "${CTX_CLUSTER2}"
helm delete istio-cni -n istio-system --kube-context "${CTX_CLUSTER2}"
helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER2}"
helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER2}"
}

snip_cleanup_6() {
kubectl delete ns istio-system --context="${CTX_CLUSTER2}"
}

snip_delete_crds() {
kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'istio.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
}

snip_delete_gateway_crds() {
kubectl get crd -oname --context "${CTX_CLUSTER1}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER1}"
kubectl get crd -oname --context "${CTX_CLUSTER2}" | grep --color=never 'gateway.networking.k8s.io' | xargs kubectl delete --context "${CTX_CLUSTER2}"
}
