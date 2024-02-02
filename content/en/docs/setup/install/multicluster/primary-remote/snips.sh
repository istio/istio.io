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
#          docs/setup/install/multicluster/primary-remote/index.md
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
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set values.pilot.env.EXTERNAL_ISTIOD=true --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_install_the_eastwest_gateway_in_cluster1_1() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster cluster1 --network network1 | \
    istioctl --context="${CTX_CLUSTER1}" install -y -f -
}

snip_install_the_eastwest_gateway_in_cluster1_2() {
kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system
}

! read -r -d '' snip_install_the_eastwest_gateway_in_cluster1_2_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.80.6.124   34.75.71.237   ...       51s
ENDSNIP

snip_expose_the_control_plane_in_cluster1_1() {
kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f \
    samples/multicluster/expose-istiod.yaml
}

snip_expose_the_control_plane_in_cluster1_2() {
sed 's/{{.Revision}}/rev/g' samples/multicluster/expose-istiod-rev.yaml.tmpl | kubectl apply --context="${CTX_CLUSTER1}" -n istio-system -f -
}

snip_set_the_control_plane_cluster_for_cluster2_1() {
kubectl --context="${CTX_CLUSTER2}" create namespace istio-system
kubectl --context="${CTX_CLUSTER2}" annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1
}

snip_configure_cluster2_as_a_remote_1() {
export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

snip_configure_cluster2_as_a_remote_2() {
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    istiodRemote:
      injectionPath: /inject/cluster/cluster2/net/network1
    global:
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
}

snip_configure_cluster2_as_a_remote_3() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_attach_cluster2_as_a_remote_cluster_of_cluster1_1() {
istioctl create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
}
