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

snip_start_the_application_services_1() {
kubectl label namespace default istio-injection=enabled
}

snip_start_the_application_services_2() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

snip_start_the_application_services_3() {
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo.yaml)
}

snip_start_the_application_services_4() {
kubectl get services
}

! read -r -d '' snip_start_the_application_services_4_out <<\ENDSNIP
NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.0.0.31    <none>        9080/TCP   6m
kubernetes    ClusterIP   10.0.0.1     <none>        443/TCP    7d
productpage   ClusterIP   10.0.0.120   <none>        9080/TCP   6m
ratings       ClusterIP   10.0.0.15    <none>        9080/TCP   6m
reviews       ClusterIP   10.0.0.170   <none>        9080/TCP   6m
ENDSNIP

snip_start_the_application_services_5() {
kubectl get pods
}

! read -r -d '' snip_start_the_application_services_5_out <<\ENDSNIP
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-1520924117-48z17      2/2       Running   0          6m
productpage-v1-560495357-jk1lz   2/2       Running   0          6m
ratings-v1-734492171-rnr5l       2/2       Running   0          6m
reviews-v1-874083890-f0qf0       2/2       Running   0          6m
reviews-v2-1343845940-b34q5      2/2       Running   0          6m
reviews-v3-1813607990-8ch52      2/2       Running   0          6m
ENDSNIP

snip_start_the_application_services_6() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_start_the_application_services_6_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_determine_the_ingress_ip_and_port_1() {
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

snip_determine_the_ingress_ip_and_port_2() {
kubectl get gateway
}

! read -r -d '' snip_determine_the_ingress_ip_and_port_2_out <<\ENDSNIP
NAME               AGE
bookinfo-gateway   32s
ENDSNIP

snip_determine_the_ingress_ip_and_port_3() {
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
}

snip_confirm_the_app_is_accessible_from_outside_the_cluster_1() {
curl -s "http://${GATEWAY_URL}/productpage" | grep -o "<title>.*</title>"
}

! read -r -d '' snip_confirm_the_app_is_accessible_from_outside_the_cluster_1_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_apply_default_destination_rules_1() {
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
}

snip_apply_default_destination_rules_2() {
kubectl get destinationrules -o yaml
}

snip_cleanup_1() {
samples/bookinfo/platform/kube/cleanup.sh
}

snip_cleanup_2() {
kubectl get virtualservices   #-- there should be no virtual services
kubectl get destinationrules  #-- there should be no destination rules
kubectl get gateway           #-- there should be no gateway
kubectl get pods              #-- the Bookinfo pods should be deleted
}
