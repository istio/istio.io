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
#          docs/tasks/observability/metrics/tcp-metrics/index.md
####################################################################################################

snip_collecting_new_telemetry_data_1() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml
}

! read -r -d '' snip_collecting_new_telemetry_data_1_out <<\ENDSNIP
serviceaccount/bookinfo-ratings-v2 created
deployment.apps/ratings-v2 created
ENDSNIP

snip_collecting_new_telemetry_data_2() {
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml)
}

! read -r -d '' snip_collecting_new_telemetry_data_2_out <<\ENDSNIP
deployment "ratings-v2" configured
ENDSNIP

snip_collecting_new_telemetry_data_3() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-db.yaml
}

! read -r -d '' snip_collecting_new_telemetry_data_3_out <<\ENDSNIP
service/mongodb created
deployment.apps/mongodb-v1 created
ENDSNIP

snip_collecting_new_telemetry_data_4() {
kubectl apply -f <(istioctl kube-inject -f samples/bookinfo/platform/kube/bookinfo-db.yaml)
}

! read -r -d '' snip_collecting_new_telemetry_data_4_out <<\ENDSNIP
service "mongodb" configured
deployment "mongodb-v1" configured
ENDSNIP

snip_collecting_new_telemetry_data_5() {
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
}

snip_collecting_new_telemetry_data_6() {
kubectl apply -f samples/bookinfo/networking/destination-rule-all-mtls.yaml
}

snip_collecting_new_telemetry_data_7() {
kubectl get destinationrules -o yaml
}

snip_collecting_new_telemetry_data_8() {
kubectl apply -f samples/bookinfo/networking/virtual-service-ratings-db.yaml
}

! read -r -d '' snip_collecting_new_telemetry_data_8_out <<\ENDSNIP
virtualservice.networking.istio.io/reviews created
virtualservice.networking.istio.io/ratings created
ENDSNIP

snip_collecting_new_telemetry_data_9() {
curl http://"$GATEWAY_URL/productpage"
}

snip_collecting_new_telemetry_data_10() {
istioctl dashboard prometheus
}

! read -r -d '' snip_collecting_new_telemetry_data_11 <<\ENDSNIP
istio_tcp_connections_opened_total{
destination_version="v1",
instance="172.17.0.18:42422",
job="istio-mesh",
canonical_service_name="ratings-v2",
canonical_service_revision="v2"}
ENDSNIP

! read -r -d '' snip_collecting_new_telemetry_data_12 <<\ENDSNIP
istio_tcp_connections_closed_total{
destination_version="v1",
instance="172.17.0.18:42422",
job="istio-mesh",
canonical_service_name="ratings-v2",
canonical_service_revision="v2"}
ENDSNIP

snip_cleanup_1() {
killall istioctl
}
