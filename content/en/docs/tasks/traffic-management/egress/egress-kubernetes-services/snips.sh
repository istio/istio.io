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
#          docs/tasks/traffic-management/egress/egress-kubernetes-services/index.md
####################################################################################################
source "content/en/boilerplates/snips/before-you-begin-egress.sh"

snip__1() {
kubectl create namespace without-istio
}

snip__2() {
kubectl apply -f samples/sleep/sleep.yaml -n without-istio
}

snip__3() {
export SOURCE_POD_WITHOUT_ISTIO="$(kubectl get pod -n without-istio -l app=sleep -o jsonpath={.items..metadata.name})"
}

snip__4() {
kubectl get pod "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio
}

! read -r -d '' snip__4_out <<\ENDSNIP
NAME                     READY   STATUS    RESTARTS   AGE
sleep-66c8d79ff5-8tqrl   1/1     Running   0          32s
ENDSNIP

snip_kubernetes_externalname_service_to_access_an_external_service_1() {
kubectl apply -f - <<EOF
kind: Service
apiVersion: v1
metadata:
  name: my-httpbin
spec:
  type: ExternalName
  externalName: httpbin.org
  ports:
  - name: http
    protocol: TCP
    port: 80
EOF
}

snip_kubernetes_externalname_service_to_access_an_external_service_2() {
kubectl get svc my-httpbin
}

! read -r -d '' snip_kubernetes_externalname_service_to_access_an_external_service_2_out <<\ENDSNIP
NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
my-httpbin   ExternalName   <none>       httpbin.org   80/TCP    4s
ENDSNIP

snip_kubernetes_externalname_service_to_access_an_external_service_3() {
kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
}

! read -r -d '' snip_kubernetes_externalname_service_to_access_an_external_service_3_out <<\ENDSNIP
{
  "headers": {
    "Accept": "*/*",
    "Host": "my-httpbin.default.svc.cluster.local",
    "User-Agent": "curl/7.55.0"
  }
}
ENDSNIP

snip_kubernetes_externalname_service_to_access_an_external_service_4() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-httpbin
spec:
  host: my-httpbin.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
}

snip_kubernetes_externalname_service_to_access_an_external_service_5() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
}

! read -r -d '' snip_kubernetes_externalname_service_to_access_an_external_service_5_out <<\ENDSNIP
{
  "headers": {
    "Accept": "*/*",
    "Content-Length": "0",
    "Host": "my-httpbin.default.svc.cluster.local",
    "User-Agent": "curl/7.64.0",
    "X-B3-Sampled": "0",
    "X-B3-Spanid": "5795fab599dca0b8",
    "X-B3-Traceid": "5079ad3a4af418915795fab599dca0b8",
    "X-Envoy-Decorator-Operation": "my-httpbin.default.svc.cluster.local:80/*",
    "X-Envoy-Peer-Metadata": "...",
    "X-Envoy-Peer-Metadata-Id": "sidecar~10.28.1.74~sleep-6bdb595bcb-drr45.default~default.svc.cluster.local"
  }
}
ENDSNIP

snip_cleanup_of_kubernetes_externalname_service_1() {
kubectl delete destinationrule my-httpbin
kubectl delete service my-httpbin
}

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_1() {
kubectl apply -f - <<EOF
kind: Service
apiVersion: v1
metadata:
  name: my-wikipedia
spec:
  ports:
  - protocol: TCP
    port: 443
    name: tls
EOF
}

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_2() {
kubectl apply -f - <<EOF
kind: Endpoints
apiVersion: v1
metadata:
  name: my-wikipedia
subsets:
  - addresses:
      - ip: 198.35.26.96
      - ip: 208.80.153.224
    ports:
      - port: 443
        name: tls
EOF
}

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_3() {
kubectl get svc my-wikipedia
}

! read -r -d '' snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_3_out <<\ENDSNIP
NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
my-wikipedia   ClusterIP   172.21.156.230   <none>        443/TCP   21h
ENDSNIP

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_4() {
kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
}

! read -r -d '' snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_4_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
ENDSNIP

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_5() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-wikipedia
spec:
  host: my-wikipedia.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE
EOF
}

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_6() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
}

! read -r -d '' snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_6_out <<\ENDSNIP
<title>Wikipedia, the free encyclopedia</title>
ENDSNIP

snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_7() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page -o /dev/null
}

! read -r -d '' snip_use_a_kubernetes_service_with_endpoints_to_access_an_external_service_7_out <<\ENDSNIP
* Added en.wikipedia.org:443:172.21.156.230 to DNS cache
* Hostname en.wikipedia.org was found in DNS cache
*   Trying 172.21.156.230...
* TCP_NODELAY set
* Connected to en.wikipedia.org (172.21.156.230) port 443 (#0)
...
ENDSNIP

snip_cleanup_of_kubernetes_service_with_endpoints_1() {
kubectl delete destinationrule my-wikipedia
kubectl delete endpoints my-wikipedia
kubectl delete service my-wikipedia
}

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}

snip_cleanup_2() {
kubectl delete -f samples/sleep/sleep.yaml -n without-istio
}

snip_cleanup_3() {
kubectl delete namespace without-istio
}

snip_cleanup_4() {
unset SOURCE_POD SOURCE_POD_WITHOUT_ISTIO
}
