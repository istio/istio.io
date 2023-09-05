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
#          docs/tasks/traffic-management/locality-load-balancing/before-you-begin/index.md
####################################################################################################

snip_create_the_sample_namespace_1() {
cat <<EOF > sample.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sample
  labels:
    istio-injection: enabled
EOF
}

snip_create_the_sample_namespace_2() {
for CTX in "$CTX_PRIMARY" "$CTX_R1_Z1" "$CTX_R1_Z2" "$CTX_R2_Z3" "$CTX_R3_Z4"; \
  do \
    kubectl --context="$CTX" apply -f sample.yaml; \
  done
}

snip_deploy_helloworld_1() {
for LOC in "region1.zone1" "region1.zone2" "region2.zone3" "region3.zone4"; \
  do \
    ./samples/helloworld/gen-helloworld.sh \
      --version "$LOC" > "helloworld-${LOC}.yaml"; \
  done
}

snip_deploy_helloworld_2() {
kubectl apply --context="${CTX_R1_Z1}" -n sample \
  -f helloworld-region1.zone1.yaml
}

snip_deploy_helloworld_3() {
kubectl apply --context="${CTX_R1_Z2}" -n sample \
  -f helloworld-region1.zone2.yaml
}

snip_deploy_helloworld_4() {
kubectl apply --context="${CTX_R2_Z3}" -n sample \
  -f helloworld-region2.zone3.yaml
}

snip_deploy_helloworld_5() {
kubectl apply --context="${CTX_R3_Z4}" -n sample \
  -f helloworld-region3.zone4.yaml
}

snip_deploy_sleep_1() {
kubectl apply --context="${CTX_R1_Z1}" \
  -f samples/sleep/sleep.yaml -n sample
}

snip_wait_for_helloworld_pods_1() {
kubectl get pod --context="${CTX_R1_Z1}" -n sample -l app="helloworld" \
  -l version="region1.zone1"
}

! read -r -d '' snip_wait_for_helloworld_pods_1_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone1-86f77cd7b-cpxhv   2/2     Running   0          30s
ENDSNIP

snip_wait_for_helloworld_pods_2() {
kubectl get pod --context="${CTX_R1_Z2}" -n sample -l app="helloworld" \
  -l version="region1.zone2"
}

! read -r -d '' snip_wait_for_helloworld_pods_2_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region1.zone2-86f77cd7b-cpxhv   2/2     Running   0          30s
ENDSNIP

snip_wait_for_helloworld_pods_3() {
kubectl get pod --context="${CTX_R2_Z3}" -n sample -l app="helloworld" \
  -l version="region2.zone3"
}

! read -r -d '' snip_wait_for_helloworld_pods_3_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region2.zone3-86f77cd7b-cpxhv   2/2     Running   0          30s
ENDSNIP

snip_wait_for_helloworld_pods_4() {
kubectl get pod --context="${CTX_R3_Z4}" -n sample -l app="helloworld" \
  -l version="region3.zone4"
}

! read -r -d '' snip_wait_for_helloworld_pods_4_out <<\ENDSNIP
NAME                                       READY   STATUS    RESTARTS   AGE
helloworld-region3.zone4-86f77cd7b-cpxhv   2/2     Running   0          30s
ENDSNIP
