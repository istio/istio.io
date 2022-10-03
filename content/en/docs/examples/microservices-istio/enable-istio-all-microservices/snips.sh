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
#          docs/examples/microservices-istio/enable-istio-all-microservices/index.md
####################################################################################################

snip__1() {
kubectl scale deployments -n "$NAMESPACE" --all --replicas 1
}

snip__2() {
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -n "$NAMESPACE" -f - | kubectl apply -n "$NAMESPACE" -l app!=reviews -f -
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -n "$NAMESPACE" -f - | kubectl apply -n "$NAMESPACE" -l app=reviews,version=v2 -f -
}

! read -r -d '' snip__2_out <<\ENDSNIP
service/details unchanged
serviceaccount/bookinfo-details unchanged
deployment.apps/details-v1 configured
service/ratings unchanged
serviceaccount/bookinfo-ratings unchanged
deployment.apps/ratings-v1 configured
serviceaccount/bookinfo-reviews unchanged
service/productpage unchanged
serviceaccount/bookinfo-productpage unchanged
deployment.apps/productpage-v1 configured
deployment.apps/reviews-v2 configured
ENDSNIP

snip__3() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip__3_out <<\ENDSNIP
details-v1-58c68b9ff-kz9lf        2/2       Running   0          2m
productpage-v1-59b4f9f8d5-d4prx   2/2       Running   0          2m
ratings-v1-b7b7fbbc9-sggxf        2/2       Running   0          2m
reviews-v2-dfbcf859c-27dvk        2/2       Running   0          2m
sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
ENDSNIP

! read -r -d '' snip__4 <<\ENDSNIP
http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
ENDSNIP

! read -r -d '' snip__5 <<\ENDSNIP
http://my-kiali.io/kiali/console
ENDSNIP
