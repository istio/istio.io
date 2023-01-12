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
#          docs/setup/install/multiple-controlplanes/index.md
####################################################################################################

snip_deploying_multiple_control_planes_1() {
kubectl create ns usergroup-1
kubectl label ns usergroup-1 usergroup=usergroup-1
istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: usergroup-1
spec:
  profile: minimal
  revision: usergroup-1
  meshConfig:
    discoverySelectors:
      - matchLabels:
          usergroup: usergroup-1
  values:
    global:
      istioNamespace: usergroup-1
    pilot:
      env:
        ENABLE_ENHANCED_RESOURCE_SCOPING: true
EOF
}

snip_deploying_multiple_control_planes_2() {
kubectl create ns usergroup-2
kubectl label ns usergroup-2 usergroup=usergroup-2
istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: usergroup-2
spec:
  profile: minimal
  revision: usergroup-2
  meshConfig:
    discoverySelectors:
      - matchLabels:
          usergroup: usergroup-2
  values:
    global:
      istioNamespace: usergroup-2
    pilot:
      env:
        ENABLE_ENHANCED_RESOURCE_SCOPING: true
EOF
}

snip_deploying_multiple_control_planes_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "usergroup-1-peerauth"
  namespace: "usergroup-1"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_deploying_multiple_control_planes_4() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "usergroup-2-peerauth"
  namespace: "usergroup-2"
spec:
  mtls:
    mode: STRICT
EOF
}

snip_verify_the_multiple_control_plane_creation_1() {
kubectl get ns usergroup-1 usergroup2 --show-labels
}

! read -r -d '' snip_verify_the_multiple_control_plane_creation_1_out <<\ENDSNIP
NAME              STATUS   AGE     LABELS
usergroup-1       Active   13m     kubernetes.io/metadata.name=usergroup-1,usergroup=usergroup-1
usergroup-2       Active   12m     kubernetes.io/metadata.name=usergroup-2,usergroup=usergroup-2
ENDSNIP

snip_verify_the_multiple_control_plane_creation_2() {
kubectl get pods -n usergroup-1
}

! read -r -d '' snip_verify_the_multiple_control_plane_creation_2_out <<\ENDSNIP
NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
usergroup-1   istiod-usergroup-1-5ccc849b5f-wnqd6      1/1     Running   0                12m
ENDSNIP

snip_verify_the_multiple_control_plane_creation_3() {
kubectl get pods -n usergroup-2
}

! read -r -d '' snip_verify_the_multiple_control_plane_creation_3_out <<\ENDSNIP
NAMESPACE     NAME                                     READY   STATUS    RESTARTS         AGE
usergroup-2   istiod-usergroup-2-658d6458f7-slpd9      1/1     Running   0                12m
ENDSNIP

snip_verify_the_multiple_control_plane_creation_4() {
kubectl get validatingwebhookconfiguration
}

! read -r -d '' snip_verify_the_multiple_control_plane_creation_4_out <<\ENDSNIP
NAME                                      WEBHOOKS   AGE
istio-validator-usergroup-1-usergroup-1   1          18m
istio-validator-usergroup-2-usergroup-2   1          18m
istiod-default-validator                  1          18m
ENDSNIP

snip_verify_the_multiple_control_plane_creation_5() {
kubectl get mutatingwebhookconfiguration
}

! read -r -d '' snip_verify_the_multiple_control_plane_creation_5_out <<\ENDSNIP
NAME                                             WEBHOOKS   AGE
istio-revision-tag-default-usergroup-1           4          18m
istio-sidecar-injector-usergroup-1-usergroup-1   2          19m
istio-sidecar-injector-usergroup-2-usergroup-2   2          18m
ENDSNIP

snip_deploy_application_workloads_per_usergroup_1() {
kubectl create ns app-ns-1
kubectl create ns app-ns-2
kubectl create ns app-ns-3
}

snip_deploy_application_workloads_per_usergroup_2() {
kubectl label ns app-ns-1 usergroup=usergroup-1 istio.io/rev=usergroup-1
kubectl label ns app-ns-2 usergroup=usergroup-2 istio.io/rev=usergroup-2
kubectl label ns app-ns-3 usergroup=usergroup-2 istio.io/rev=usergroup-2
}

snip_deploy_application_workloads_per_usergroup_3() {
kubectl -n app-ns-1 apply -f samples/sleep/sleep.yaml
kubectl -n app-ns-1 apply -f samples/httpbin/httpbin.yaml
kubectl -n app-ns-2 apply -f samples/sleep/sleep.yaml
kubectl -n app-ns-2 apply -f samples/httpbin/httpbin.yaml
kubectl -n app-ns-3 apply -f samples/sleep/sleep.yaml
kubectl -n app-ns-3 apply -f samples/httpbin/httpbin.yaml
}

snip_deploy_application_workloads_per_usergroup_4() {
kubectl get pods -n app-ns-1
}

! read -r -d '' snip_deploy_application_workloads_per_usergroup_4_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-9dbd644c7-zc2v4   2/2     Running   0          115m
sleep-78ff5975c6-fml7c    2/2     Running   0          115m
ENDSNIP

snip_deploy_application_workloads_per_usergroup_5() {
kubectl get pods -n app-ns-2
}

! read -r -d '' snip_deploy_application_workloads_per_usergroup_5_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-9dbd644c7-sd9ln   2/2     Running   0          115m
sleep-78ff5975c6-sz728    2/2     Running   0          115m
ENDSNIP

snip_deploy_application_workloads_per_usergroup_6() {
kubectl get pods -n app-ns-3
}

! read -r -d '' snip_deploy_application_workloads_per_usergroup_6_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-9dbd644c7-8ll27   2/2     Running   0          115m
sleep-78ff5975c6-sg4tq    2/2     Running   0          115m
ENDSNIP

snip_verify_the_application_to_control_plane_mapping_1() {
istioctl ps -i usergroup-1
}

! read -r -d '' snip_verify_the_application_to_control_plane_mapping_1_out <<\ENDSNIP
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-hccpf.app-ns-1     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-9zb77.app-ns-1      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-1-5ccc849b5f-wnqd6     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
ENDSNIP

snip_verify_the_application_to_control_plane_mapping_2() {
istioctl ps -i usergroup-2
}

! read -r -d '' snip_verify_the_application_to_control_plane_mapping_2_out <<\ENDSNIP
NAME                                 CLUSTER        CDS        LDS        EDS        RDS          ECDS         ISTIOD                                  VERSION
httpbin-9dbd644c7-vvcqj.app-ns-3     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
httpbin-9dbd644c7-xzgfm.app-ns-2     Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-fthmt.app-ns-2      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
sleep-78ff5975c6-nxtth.app-ns-3      Kubernetes     SYNCED     SYNCED     SYNCED     SYNCED       NOT SENT     istiod-usergroup-2-658d6458f7-slpd9     1.17-alpha.f5212a6f7df61fd8156f3585154bed2f003c4117
ENDSNIP

snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_1() {
kubectl -n app-ns-1 exec "$(kubectl -n app-ns-1 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-2.svc.cluster.local:8000
}

! read -r -d '' snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_1_out <<\ENDSNIP
HTTP/1.1 503 Service Unavailable
content-length: 95
content-type: text/plain
date: Sat, 24 Dec 2022 06:54:54 GMT
server: envoy
ENDSNIP

snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_2() {
kubectl -n app-ns-2 exec "$(kubectl -n app-ns-2 get pod -l app=sleep -o jsonpath={.items..metadata.name})" -c sleep -- curl -sIL http://httpbin.app-ns-3.svc.cluster.local:8000
}

! read -r -d '' snip_verify_the_application_connectivity_is_only_within_the_respective_usergroup_2_out <<\ENDSNIP
HTTP/1.1 200 OK
server: envoy
date: Thu, 22 Dec 2022 15:01:36 GMT
content-type: text/html; charset=utf-8
content-length: 9593
access-control-allow-origin: *
access-control-allow-credentials: true
x-envoy-upstream-service-time: 3
ENDSNIP

snip_cleanup_1() {
istioctl uninstall --revision usergroup-1
kubectl delete ns app-ns-1 usergroup-1
}

snip_cleanup_2() {
istioctl uninstall --revision usergroup-2
kubectl delete ns app-ns-2 app-ns-3 usergroup-2
}
