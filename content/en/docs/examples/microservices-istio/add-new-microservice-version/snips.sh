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
#          docs/examples/microservices-istio/add-new-microservice-version/index.md
####################################################################################################

snip__1() {
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml | sed 's/app: reviews/app: reviews_test/' | kubectl apply -n "$NAMESPACE" -l app=reviews_test,version=v2 -f -
}

! read -r -d '' snip__1_out <<\ENDSNIP
deployment.apps/reviews-v2 created
ENDSNIP

snip__2() {
REVIEWS_V2_POD_IP=$(kubectl get pod -n "$NAMESPACE" -l app=reviews_test,version=v2 -o jsonpath='{.items[0].status.podIP}')
echo "$REVIEWS_V2_POD_IP"
}

snip__3() {
kubectl exec -n "$NAMESPACE" "$(kubectl get pod -n "$NAMESPACE" -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- curl -sS "$REVIEWS_V2_POD_IP:9080/reviews/7"
}

! read -r -d '' snip__3_out <<\ENDSNIP
{"id": "7","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is refreshing!", "rating": {"stars": 5, "color": "black"}},{  "reviewer": "Reviewer2",  "text": "Absolutely fun and entertaining. The play lacks thematic depth when compared to other plays by Shakespeare.", "rating": {"stars": 4, "color": "black"}}]}
ENDSNIP

snip__4() {
kubectl exec -n "$NAMESPACE" "$(kubectl get pod -n "$NAMESPACE" -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- sh -c "for i in 1 2 3 4 5 6 7 8 9 10; do curl -o /dev/null -s -w '%{http_code}\n' '$REVIEWS_V2_POD_IP':9080/reviews/7; done"
}

! read -r -d '' snip__4_out <<\ENDSNIP
200
200
...
ENDSNIP

snip__5() {
kubectl label pods -n "$NAMESPACE" -l version=v2 app=reviews --overwrite
}

! read -r -d '' snip__5_out <<\ENDSNIP
pod "reviews-v2-79c8c8c7c5-4p4mn" labeled
ENDSNIP

snip__6() {
kubectl delete deployment reviews-v2 -n "$NAMESPACE"
kubectl delete pod -l app=reviews,version=v2 -n "$NAMESPACE"
}

! read -r -d '' snip__6_out <<\ENDSNIP
deployment.apps "reviews-v2" deleted
pod "reviews-v2-79c8c8c7c5-4p4mn" deleted
ENDSNIP

snip__7() {
kubectl apply -n "$NAMESPACE" -l app=reviews,version=v2 -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml
}

! read -r -d '' snip__7_out <<\ENDSNIP
deployment.apps/reviews-v2 created
ENDSNIP

snip__8() {
kubectl scale deployment -n "$NAMESPACE" reviews-v2 --replicas=3
}

! read -r -d '' snip__8_out <<\ENDSNIP
deployment.apps/reviews-v2 scaled
ENDSNIP

snip__9() {
kubectl delete deployment reviews-v1 -n "$NAMESPACE"
}

! read -r -d '' snip__9_out <<\ENDSNIP
deployment.apps "reviews-v1" deleted
ENDSNIP
