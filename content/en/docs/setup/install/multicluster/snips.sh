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
export CTX_FRED=cluster-fred
export CTX_BARNEY=cluster-barney
}

snip_configure_fred_as_a_primary_1() {
cat <<EOF > ./fred.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: EAST
      meshNetworks:
        EAST:
          endpoints:
          - fromRegistry: FRED
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_FRED} -f fred.yaml
}

snip_configure_barney_as_a_primary_1() {
cat <<EOF > ./barney.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      meshNetworks:
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_BARNEY} -f barney.yaml
}

snip_enable_endpoint_discovery_1() {
istioctl x create-remote-secret \
    --context=${CTX_FRED} \
    --name=FRED | \
    kubectl apply -f - --context=${CTX_BARNEY}
}

snip_enable_endpoint_discovery_2() {
istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
}

snip_configure_fred_as_a_primary_with_services_exposed_1() {
cat <<EOF > ./fred.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: WEST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_FRED} -f fred.yaml
}

snip_configure_fred_as_a_primary_with_services_exposed_2() {
CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
}

snip_configure_fred_as_a_primary_with_services_exposed_3() {
kubectl --context=${CTX_FRED} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_configure_barney_as_a_primary_with_services_exposed_1() {
cat <<EOF > ./barney.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_BARNEY} -f barney.yaml
}

snip_configure_barney_as_a_primary_with_services_exposed_2() {
CLUSTER=BARNEY NETWORK=EAST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_BARNEY} -f -
}

snip_configure_barney_as_a_primary_with_services_exposed_3() {
kubectl --context=${CTX_BARNEY} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_enable_endpoint_discovery_for_fred_and_barney_1() {
istioctl x create-remote-secret \
  --context=${CTX_FRED} \
  --name=FRED | \
  kubectl apply -f - --context=${CTX_BARNEY}
}

snip_enable_endpoint_discovery_for_fred_and_barney_2() {
istioctl x create-remote-secret \
  --context=${CTX_BARNEY} \
  --name=BARNEY | \
  kubectl apply -f - --context=${CTX_FRED}
}

snip_configure_fred_as_a_primary_with_control_plane_exposed_1() {
cat <<EOF > ./fred.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: EAST
      meshNetworks:
        ${NETWORK1}:
          endpoints:
          - fromRegistry: FRED
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_FRED} -f fred.yaml
}

snip_configure_fred_as_a_primary_with_control_plane_exposed_2() {
CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
}

snip_configure_fred_as_a_primary_with_control_plane_exposed_3() {
kubectl apply --context=${CTX_FRED} -f \
    samples/multicluster/expose-istiod.yaml
}

snip_configure_barney_as_a_remote_1() {
export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_FRED} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

snip_configure_barney_as_a_remote_2() {
cat <<EOF > ./barney.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
istioctl install --context=${CTX_BARNEY} -f barney.yaml
}

snip_enable_endpoint_discovery_for_barney_1() {
istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
}

snip_configure_fred_as_a_primary_with_control_plane_and_services_exposed_1() {
cat <<EOF > ./fred.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: FRED
      network: WEST
      meshNetworks:
        WEST:
          endpoints:
          - fromRegistry: FRED
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
        EAST:
          endpoints:
          - fromRegistry: BARNEY
          gateways:
          - registryServiceName: istio-eastwestgateway.istio-system.svc.cluster.local
            port: 15443
EOF
istioctl install --context=${CTX_FRED} -f fred.yaml
}

snip_configure_fred_as_a_primary_with_control_plane_and_services_exposed_2() {
CLUSTER=FRED NETWORK=WEST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_FRED} -f -
}

snip_configure_fred_as_a_primary_with_control_plane_and_services_exposed_3() {
kubectl apply --context=${CTX_FRED} -f \
    samples/multicluster/expose-istiod.yaml
}

snip_configure_fred_as_a_primary_with_control_plane_and_services_exposed_4() {
kubectl --context=${CTX_FRED} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_configure_barney_as_a_remote_with_services_exposed_1() {
export DISCOVERY_ADDRESS=$(kubectl \
    --context=${CTX_FRED} \
    -n istio-system get svc istio-eastwestgateway \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

snip_configure_barney_as_a_remote_with_services_exposed_2() {
cat <<EOF > ./barney.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: BEDROCK
      multiCluster:
        clusterName: BARNEY
      network: EAST
      remotePilotAddress: ${DISCOVERY_ADDRESS}
EOF
istioctl install --context=${CTX_BARNEY} -f - barney.yaml
}

snip_configure_barney_as_a_remote_with_services_exposed_3() {
CLUSTER=BARNEY NETWORK=EAST \
    samples/multicluster/gen-eastwest-gateway.sh | \
    kubectl apply --context=${CTX_BARNEY} -f -
}

snip_configure_barney_as_a_remote_with_services_exposed_4() {
kubectl --context=${CTX_BARNEY} apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_enable_endpoint_discovery_for_barney_on_east_1() {
istioctl x create-remote-secret \
    --context=${CTX_BARNEY} \
    --name=BARNEY | \
    kubectl apply -f - --context=${CTX_FRED}
}

snip_deploy_the_helloworld_service_1() {
kubectl create --context=${CTX_FRED} namespace sample
kubectl create --context=${CTX_BARNEY} namespace sample
}

snip_deploy_the_helloworld_service_2() {
kubectl label --context=${CTX_FRED} namespace sample \
    istio-injection=enabled
kubectl label --context=${CTX_BARNEY} namespace sample \
    istio-injection=enabled
}

snip_deploy_the_helloworld_service_3() {
kubectl apply --context=${CTX_FRED} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
kubectl apply --context=${CTX_BARNEY} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -n sample
}

snip_deploy_helloworld_v1_1() {
kubectl apply --context=${CTX_FRED} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v1 -n sample
}

snip_deploy_helloworld_v1_2() {
kubectl get pod --context=${CTX_FRED} -n sample
}

! read -r -d '' snip_deploy_helloworld_v1_2_out <<\ENDSNIP
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v1-86f77cd7bd-cpxhv  2/2       Running   0          40s
ENDSNIP

snip_deploy_helloworld_v2_1() {
kubectl apply --context=${CTX_BARNEY} \
    -f samples/helloworld/helloworld.yaml \
    -l app=helloworld -l version=v2 -n sample
}

snip_deploy_helloworld_v2_2() {
kubectl get pod --context=${CTX_BARNEY} -n sample
}

! read -r -d '' snip_deploy_helloworld_v2_2_out <<\ENDSNIP
NAME                            READY     STATUS    RESTARTS   AGE
helloworld-v2-758dd55874-6x4t8  2/2       Running   0          40s
ENDSNIP

snip_deploy_sleep_1() {
kubectl apply --context=${CTX_FRED} \
    -f samples/sleep/sleep.yaml -n sample
kubectl apply --context=${CTX_BARNEY} \
    -f samples/sleep/sleep.yaml -n sample
}

snip_deploy_sleep_2() {
kubectl get pod --context=${CTX_FRED} -n sample -l app=sleep
}

! read -r -d '' snip_deploy_sleep_2_out <<\ENDSNIP
sleep-754684654f-n6bzf           2/2     Running   0          5s
ENDSNIP

snip_deploy_sleep_3() {
kubectl get pod --context=${CTX_BARNEY} -n sample -l app=sleep
}

! read -r -d '' snip_deploy_sleep_3_out <<\ENDSNIP
sleep-754684654f-dzl9j           2/2     Running   0          5s
ENDSNIP

snip_verifying_crosscluster_traffic_1() {
kubectl exec --context=${CTX_FRED} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_FRED} -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
}

! read -r -d '' snip_verifying_crosscluster_traffic_2 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
ENDSNIP

snip_verifying_crosscluster_traffic_3() {
kubectl exec --context=${CTX_BARNEY} -n sample -c sleep \
    "$(kubectl get pod --context=${CTX_BARNEY} -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
}

! read -r -d '' snip_verifying_crosscluster_traffic_4 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
...
ENDSNIP
