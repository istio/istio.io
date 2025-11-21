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
#          docs/ambient/install/multicluster/failover/index.md
####################################################################################################

snip_deploy_waypoint_proxy_1() {
istioctl --context "${CTX_CLUSTER1}" waypoint apply --name waypoint --for service -n sample --wait
istioctl --context "${CTX_CLUSTER2}" waypoint apply --name waypoint --for service -n sample --wait
}

snip_deploy_waypoint_proxy_2() {
kubectl --context "${CTX_CLUSTER1}" get deployment waypoint --namespace sample
}

! IFS=$'\n' read -r -d '' snip_deploy_waypoint_proxy_2_out <<\ENDSNIP
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           137m
ENDSNIP

snip_deploy_waypoint_proxy_3() {
kubectl --context "${CTX_CLUSTER2}" get deployment waypoint --namespace sample
}

! IFS=$'\n' read -r -d '' snip_deploy_waypoint_proxy_3_out <<\ENDSNIP
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
waypoint   1/1     1            1           138m
ENDSNIP

snip_deploy_waypoint_proxy_4() {
kubectl --context "${CTX_CLUSTER1}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
kubectl --context "${CTX_CLUSTER2}" label svc helloworld -n sample istio.io/use-waypoint=waypoint
}

snip_deploy_waypoint_proxy_5() {
kubectl --context "${CTX_CLUSTER1}" label svc waypoint -n sample istio.io/global=true
kubectl --context "${CTX_CLUSTER2}" label svc waypoint -n sample istio.io/global=true
}

snip_configure_locality_failover_1() {
kubectl --context "${CTX_CLUSTER1}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
}

snip_configure_locality_failover_2() {
kubectl --context "${CTX_CLUSTER2}" apply -n sample -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: helloworld
spec:
  host: helloworld.sample.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
          - topology.istio.io/cluster
EOF
}

snip_verify_traffic_stays_in_local_cluster_1() {
kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_stays_in_local_cluster_2 <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
Hello version: v1, instance: helloworld-v1-954745fd-z6qcn
...
ENDSNIP

snip_verify_traffic_stays_in_local_cluster_3() {
kubectl exec --context "${CTX_CLUSTER2}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER2}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_stays_in_local_cluster_4 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
ENDSNIP

snip_verify_failover_to_another_cluster_1() {
kubectl --context "${CTX_CLUSTER1}" scale --replicas=0 deployment/helloworld-v1 -n sample
}

snip_verify_failover_to_another_cluster_2() {
kubectl exec --context "${CTX_CLUSTER1}" -n sample -c curl \
    "$(kubectl get pod --context "${CTX_CLUSTER1}" -n sample -l \
    app=curl -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! IFS=$'\n' read -r -d '' snip_verify_failover_to_another_cluster_3 <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
Hello version: v2, instance: helloworld-v2-7b768b9bbd-7zftm
...
ENDSNIP
