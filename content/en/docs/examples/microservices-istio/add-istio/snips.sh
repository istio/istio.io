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
#          docs/examples/microservices-istio/add-istio/index.md
####################################################################################################

snip__1() {
kubectl apply -n "$NAMESPACE" -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/networking/destination-rule-all.yaml
}

snip__2() {
curl -s https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml | istioctl kube-inject -f - | sed 's/replicas: 1/replicas: 3/g' | kubectl apply -l app=productpage,version=v1 -n "$NAMESPACE" -f -
}

! read -r -d '' snip__2_out <<\ENDSNIP
deployment.apps/productpage-v1 configured
ENDSNIP

snip__3() {
kubectl get pods -n "$NAMESPACE"
}

! read -r -d '' snip__3_out <<\ENDSNIP
details-v1-68868454f5-8nbjv       1/1       Running   0          7h
details-v1-68868454f5-nmngq       1/1       Running   0          7h
details-v1-68868454f5-zmj7j       1/1       Running   0          7h
productpage-v1-6dcdf77948-6tcbf   2/2       Running   0          7h
productpage-v1-6dcdf77948-t9t97   2/2       Running   0          7h
productpage-v1-6dcdf77948-tjq5d   2/2       Running   0          7h
ratings-v1-76f4c9765f-khlvv       1/1       Running   0          7h
ratings-v1-76f4c9765f-ntvkx       1/1       Running   0          7h
ratings-v1-76f4c9765f-zd5mp       1/1       Running   0          7h
reviews-v2-56f6855586-cnrjp       1/1       Running   0          7h
reviews-v2-56f6855586-lxc49       1/1       Running   0          7h
reviews-v2-56f6855586-qh84k       1/1       Running   0          7h
sleep-88ddbcfdd-cc85s             1/1       Running   0          7h
ENDSNIP

snip__4() {
kubectl logs -n "$NAMESPACE" -l app=productpage -c istio-proxy | grep GET
}

! read -r -d '' snip__4_out <<\ENDSNIP
...
[2019-02-15T09:06:04.079Z] "GET /details/0 HTTP/1.1" 200 - 0 178 5 3 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "details:9080" "172.30.230.51:9080" outbound|9080||details.tutorial.svc.cluster.local - 172.21.109.216:9080 172.30.146.104:58698 -
[2019-02-15T09:06:04.088Z] "GET /reviews/0 HTTP/1.1" 200 - 0 379 22 22 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "reviews:9080" "172.30.230.27:9080" outbound|9080||reviews.tutorial.svc.cluster.local - 172.21.185.48:9080 172.30.146.104:41442 -
[2019-02-15T09:06:04.053Z] "GET /productpage HTTP/1.1" 200 - 0 5723 90 83 "10.127.220.66" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15" "18710783-58a1-9e5f-992c-9ceff05b74c5" "tutorial.bookinfo.com" "127.0.0.1:9080" inbound|9080|http|productpage.tutorial.svc.cluster.local - 172.30.146.104:9080 10.127.220.66:0 -
ENDSNIP

snip__5() {
kubectl config view -o jsonpath="{.contexts[?(@.name == \"$(kubectl config current-context)\")].context.namespace}"
}

! read -r -d '' snip__5_out <<\ENDSNIP
tutorial
ENDSNIP

! read -r -d '' snip__6 <<\ENDSNIP
http://my-istio-dashboard.io/dashboard/db/istio-mesh-dashboard
ENDSNIP
