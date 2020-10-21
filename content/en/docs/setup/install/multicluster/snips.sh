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
#          docs/setup/install/multicluster/index.md
####################################################################################################

snip_environment_variables_1() {
export CTX_CLUSTER1=cluster1
export CTX_CLUSTER2=cluster2
}

snip_install_istio_1() {
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

snip_install_istio_2() {
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_install_istio_3() {
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

snip_install_istio_4() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_install_istio_5() {
istioctl x create-remote-secret \
    --context="${CTX_CLUSTER1}" \
    --name=cluster1 | \
    kubectl apply -f - --context="${CTX_CLUSTER2}"
}

snip_install_istio_6() {
istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
}

snip_install_istio_7() {
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

snip_install_istio_8() {
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_install_istio_9() {
MESH=mesh1 CLUSTER=cluster1 NETWORK=network1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER1}" -f -
}

snip_install_istio_10() {
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_install_istio_11() {
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
EOF
}

snip_install_istio_12() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_install_istio_13() {
MESH=mesh1 CLUSTER=cluster2 NETWORK=network2 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
}

snip_install_istio_14() {
kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_install_istio_15() {
istioctl x create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=cluster1 | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"
}

snip_install_istio_16() {
istioctl x create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=cluster2 | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"
}

snip_install_istio_17() {
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

snip_install_istio_18() {
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_install_istio_19() {
MESH=mesh1 CLUSTER=cluster1 NETWORK=network1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER1}" -f -
}

snip_install_istio_20() {
kubectl apply --context="${CTX_CLUSTER1}" -f \
    samples/multicluster/expose-istiod.yaml
}

snip_install_istio_21() {
istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
}

snip_install_istio_22() {
export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

snip_install_istio_23() {
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network1
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
}

snip_install_istio_24() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_install_istio_25() {
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

snip_install_istio_26() {
istioctl install --context="${CTX_CLUSTER1}" -f cluster1.yaml
}

snip_install_istio_27() {
MESH=mesh1 CLUSTER=cluster1 NETWORK=network1 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER1}" -f -
}

snip_install_istio_28() {
kubectl apply --context="${CTX_CLUSTER1}" -f \
    samples/multicluster/expose-istiod.yaml
}

snip_install_istio_29() {
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_install_istio_30() {
istioctl x create-remote-secret \
    --context="${CTX_CLUSTER2}" \
    --name=cluster2 | \
    kubectl apply -f - --context="${CTX_CLUSTER1}"
}

snip_install_istio_31() {
export DISCOVERY_ADDRESS=$(kubectl \
    --context="${CTX_CLUSTER1}" \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

snip_install_istio_32() {
cat <<EOF > cluster2.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: remote
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: cluster2
      network: network2
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
}

snip_install_istio_33() {
istioctl install --context="${CTX_CLUSTER2}" -f cluster2.yaml
}

snip_install_istio_34() {
MESH=mesh1 CLUSTER=cluster2 NETWORK=network2 \
    samples/multicluster/gen-eastwest-gateway.sh | \
    istioctl manifest generate -f - | \
    kubectl apply --context="${CTX_CLUSTER2}" -f -
}

snip_install_istio_35() {
kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_deploy_the_helloworld_service_1() {
kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample
}

snip_deploy_the_helloworld_service_2() {
kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled
}

snip_deploy_the_helloworld_service_3() {
kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
}

snip_deploy_helloworld_v1_1() {
kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n sample
}

snip_deploy_helloworld_v1_2() {
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld
}

! read -r -d '' snip_deploy_helloworld_v1_2_out <<\ENDSNIP
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
ENDSNIP

snip_deploy_helloworld_v2_1() {
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample
}

snip_deploy_helloworld_v2_2() {
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld
}

! read -r -d '' snip_deploy_helloworld_v2_2_out <<\ENDSNIP
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
ENDSNIP

snip_deploy_sleep_1() {
kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/sleep/sleep.yaml -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/sleep/sleep.yaml -n sample
}

snip_deploy_sleep_2() {
kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep
}

! read -r -d '' snip_deploy_sleep_2_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-n6bzf           2/2     Running   0          5s
ENDSNIP

snip_deploy_sleep_3() {
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep
}

! read -r -d '' snip_deploy_sleep_3_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
sleep-754684654f-dzl9j           2/2     Running   0          5s
ENDSNIP

snip_verifying_crosscluster_traffic_1() {
kubectl exec --context="${CTX_CLUSTER1}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
}

! read -r -d '' snip_verifying_crosscluster_traffic_2 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
ENDSNIP

snip_verifying_crosscluster_traffic_3() {
kubectl exec --context="${CTX_CLUSTER2}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
}

! read -r -d '' snip_verifying_crosscluster_traffic_4 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
ENDSNIP
