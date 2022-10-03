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
#          docs/examples/microservices-istio/production-testing/index.md
####################################################################################################

snip_testing_individual_microservices_1() {
kubectl exec -n "$NAMESPACE" "$(kubectl get pod -n "$NAMESPACE" -l app=sleep -o jsonpath='{.items[0].metadata.name}')" -- curl -s http://ratings:9080/ratings/7
}

snip_chaos_testing_1() {
kubectl exec -n "$NAMESPACE" "$(kubectl get pods -n "$NAMESPACE" -l app=details -o jsonpath='{.items[0].metadata.name}')" -- pkill ruby
}

snip_chaos_testing_2() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip_chaos_testing_2_out <<\ENDSNIP
NAME                            READY   STATUS    RESTARTS   AGE
details-v1-6d86fd9949-fr59p     1/1     Running   1          47m
details-v1-6d86fd9949-mksv7     1/1     Running   0          47m
details-v1-6d86fd9949-q8rrf     1/1     Running   0          48m
productpage-v1-c9965499-hwhcn   1/1     Running   0          47m
productpage-v1-c9965499-nccwq   1/1     Running   0          47m
productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          47m
ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          47m
ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          48m
reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          47m
reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          48m
reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          47m
sleep-88ddbcfdd-l9zq4           1/1     Running   0          47m
ENDSNIP

snip_chaos_testing_3() {
for pod in $(kubectl get pods -n "$NAMESPACE" -l app=details -o jsonpath='{.items[*].metadata.name}'); do echo terminating "$pod"; kubectl exec -n "$NAMESPACE" "$pod" -- pkill ruby; done
}

snip_chaos_testing_4() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip_chaos_testing_4_out <<\ENDSNIP
NAME                            READY   STATUS    RESTARTS   AGE
details-v1-6d86fd9949-fr59p     1/1     Running   2          48m
details-v1-6d86fd9949-mksv7     1/1     Running   1          48m
details-v1-6d86fd9949-q8rrf     1/1     Running   1          49m
productpage-v1-c9965499-hwhcn   1/1     Running   0          48m
productpage-v1-c9965499-nccwq   1/1     Running   0          48m
productpage-v1-c9965499-tjdjx   1/1     Running   0          48m
ratings-v1-7bf577cb77-cbdsg     1/1     Running   0          48m
ratings-v1-7bf577cb77-cz6jm     1/1     Running   0          48m
ratings-v1-7bf577cb77-pq9kg     1/1     Running   0          49m
reviews-v1-77c65dc5c6-5wt8g     1/1     Running   0          48m
reviews-v1-77c65dc5c6-kjvxs     1/1     Running   0          49m
reviews-v1-77c65dc5c6-r55tl     1/1     Running   0          48m
sleep-88ddbcfdd-l9zq4           1/1     Running   0          48m
ENDSNIP
