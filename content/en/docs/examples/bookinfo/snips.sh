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
#          docs/examples/bookinfo/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-support.sh"

snip_start_the_application_services_1() {
kubectl label namespace default istio-injection=enabled
}

snip_start_the_application_services_2() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

snip_start_the_application_services_3() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

snip_start_the_application_services_4() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-waypoints.yaml
}

snip_start_the_application_services_5() {
kubectl get services
}

! IFS=$'\n' read -r -d '' snip_start_the_application_services_5_out <<\ENDSNIP
NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
ENDSNIP

snip_start_the_application_services_6() {
kubectl get pods
}

! IFS=$'\n' read -r -d '' snip_start_the_application_services_6_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-1520924117-48z17      2/2       Running   0          6m
productpage-v1-560495357-jk1lz   2/2       Running   0          6m
ratings-v1-734492171-rnr5l       2/2       Running   0          6m
reviews-v1-874083890-f0qf0       2/2       Running   0          6m
reviews-v2-1343845940-b34q5      2/2       Running   0          6m
reviews-v3-1813607990-8ch52      2/2       Running   0          6m
ENDSNIP

snip_start_the_application_services_7() {
kubectl get services
}

! IFS=$'\n' read -r -d '' snip_start_the_application_services_7_out <<\ENDSNIP
NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)               AGE
details                    ClusterIP   10.96.30.105    <none>        9080/TCP              61m
details-svc-waypoint       ClusterIP   10.96.250.18    <none>        15021/TCP,15008/TCP   43m
kubernetes                 ClusterIP   10.96.0.1       <none>        443/TCP               63m
productpage                ClusterIP   10.96.66.208    <none>        9080/TCP              61m
productpage-svc-waypoint   ClusterIP   10.96.249.175   <none>        15021/TCP,15008/TCP   43m
ratings                    ClusterIP   10.96.141.216   <none>        9080/TCP              61m
ratings-svc-waypoint       ClusterIP   10.96.233.85    <none>        15021/TCP,15008/TCP   43m
reviews                    ClusterIP   10.96.113.136   <none>        9080/TCP              61m
reviews-svc-waypoint       ClusterIP   10.96.50.232    <none>        15021/TCP,15008/TCP   43m
ENDSNIP

snip_start_the_application_services_8() {
kubectl get pods
}

! IFS=$'\n' read -r -d '' snip_start_the_application_services_8_out <<\ENDSNIP
NAME                                        READY   STATUS    RESTARTS   AGE
details-svc-waypoint-766c4b6b86-qlt7j       1/1     Running   0          44m
details-v1-766844796b-bwbzt                 1/1     Running   0          61m
productpage-svc-waypoint-84c9c55bb8-6pgbz   1/1     Running   0          44m
productpage-v1-54bb874995-54b2b             1/1     Running   0          61m
ratings-svc-waypoint-6f9559f994-x6w94       1/1     Running   0          44m
ratings-v1-5dc79b6bcd-qhdld                 1/1     Running   0          61m
reviews-svc-waypoint-788d467dcf-qhm7v       1/1     Running   0          44m
reviews-v1-598b896c9d-lrf6v                 1/1     Running   0          61m
reviews-v2-556d6457d-t2qtq                  1/1     Running   0          61m
reviews-v3-564544b4d6-6dn2m                 1/1     Running   0          61m
ENDSNIP

snip_start_the_application_services_9() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_start_the_application_services_9_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_determine_the_ingress_ip_and_port_1() {
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

! IFS=$'\n' read -r -d '' snip_determine_the_ingress_ip_and_port_1_out <<\ENDSNIP
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created
ENDSNIP

snip_determine_the_ingress_ip_and_port_2() {
kubectl get gateway
}

! IFS=$'\n' read -r -d '' snip_determine_the_ingress_ip_and_port_2_out <<\ENDSNIP
NAME               AGE
bookinfo-gateway   32s
ENDSNIP

snip_determine_the_ingress_ip_and_port_3() {
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
}

! IFS=$'\n' read -r -d '' snip_determine_the_ingress_ip_and_port_3_out <<\ENDSNIP
gateway.gateway.networking.k8s.io/bookinfo-gateway created
httproute.gateway.networking.k8s.io/bookinfo created
ENDSNIP

snip_determine_the_ingress_ip_and_port_4() {
kubectl wait --for=condition=programmed gtw bookinfo-gateway
}

snip_determine_the_ingress_ip_and_port_5() {
export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
}

snip_determine_the_ingress_ip_and_port_6() {
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
}

snip_confirm_the_app_is_accessible_from_outside_the_cluster_1() {
curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_confirm_the_app_is_accessible_from_outside_the_cluster_1_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_define_the_service_versions_1() {
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
}

snip_define_the_service_versions_2() {
kubectl get destinationrules -o yaml
}

snip_define_the_service_versions_3() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
}

snip_cleanup_1() {
samples/bookinfo/platform/kube/cleanup.sh
}
