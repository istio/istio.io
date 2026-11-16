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
#          docs/setup/install/multicluster/multi-primary/index.md
####################################################################################################

snip_configure_cluster1_as_a_primary_1() {
cat <<EOF > cluster1.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
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
helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER1}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster1 --set global.network=network1
}

snip_configure_cluster2_as_a_primary_1() {
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
EOF
}

snip_configure_cluster2_as_a_primary_2() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_configure_cluster2_as_a_primary_3() {
helm install istio-base istio/base -n istio-system --kube-context "${CTX_CLUSTER2}"
}

snip_configure_cluster2_as_a_primary_4() {
helm install istiod istio/istiod -n istio-system --kube-context "${CTX_CLUSTER2}" --set global.meshID=mesh1 --set global.multiCluster.clusterName=cluster2 --set global.network=network1
}

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
helm delete istiod -n istio-system --kube-context "${CTX_CLUSTER1}"
helm delete istio-base -n istio-system --kube-context "${CTX_CLUSTER1}"
}

snip_cleanup_4() {
kubectl delete ns istio-system --context="${CTX_CLUSTER1}"
}

snip_cleanup_5() {
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
