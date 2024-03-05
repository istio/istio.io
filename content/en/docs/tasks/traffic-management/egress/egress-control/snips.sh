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
#          docs/tasks/traffic-management/egress/egress-control/index.md
####################################################################################################
source "content/en/boilerplates/snips/gateway-api-gamma-support.sh"

snip_before_you_begin_1() {
kubectl apply -f samples/sleep/sleep.yaml
}

snip_before_you_begin_2() {
kubectl apply -f <(istioctl kube-inject -f samples/sleep/sleep.yaml)
}

snip_before_you_begin_3() {
export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
}

snip_envoy_passthrough_to_external_services_1() {
kubectl get configmap istio -n istio-system -o yaml
}

snip_envoy_passthrough_to_external_services_3() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://edition.cnn.com | grep "HTTP/"
}

! read -r -d '' snip_envoy_passthrough_to_external_services_3_out <<\ENDSNIP
HTTP/2 200
HTTP/2 200
ENDSNIP

! read -r -d '' snip_change_to_the_blockingbydefault_policy_1 <<\ENDSNIP
spec:
  meshConfig:
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
ENDSNIP

snip_change_to_the_blockingbydefault_policy_3() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://edition.cnn.com | grep "HTTP/"
}

! read -r -d '' snip_change_to_the_blockingbydefault_policy_3_out <<\ENDSNIP
command terminated with exit code 35
command terminated with exit code 35
ENDSNIP

snip_access_an_external_http_service_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
EOF
}

snip_access_an_external_http_service_2() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS http://httpbin.org/headers
}

! read -r -d '' snip_access_an_external_http_service_2_out <<\ENDSNIP
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
    "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
    ...
  }
}
ENDSNIP

snip_access_an_external_http_service_3() {
kubectl logs "$SOURCE_POD" -c istio-proxy | tail
}

! read -r -d '' snip_access_an_external_http_service_3_out <<\ENDSNIP
[2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
ENDSNIP

snip_access_an_external_https_service_1() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: google
spec:
  hosts:
  - www.google.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
  location: MESH_EXTERNAL
EOF
}

snip_access_an_external_https_service_2() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI https://www.google.com | grep  "HTTP/"
}

! read -r -d '' snip_access_an_external_https_service_2_out <<\ENDSNIP
HTTP/2 200
ENDSNIP

snip_access_an_external_https_service_3() {
kubectl logs "$SOURCE_POD" -c istio-proxy | tail
}

! read -r -d '' snip_access_an_external_https_service_3_out <<\ENDSNIP
[2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
ENDSNIP

snip_manage_traffic_to_external_services_1() {
kubectl exec "$SOURCE_POD" -c sleep -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
}

! read -r -d '' snip_manage_traffic_to_external_services_1_out <<\ENDSNIP
200
real    0m5.024s
user    0m0.003s
sys     0m0.003s
ENDSNIP

snip_manage_traffic_to_external_services_2() {
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-ext
spec:
  hosts:
  - httpbin.org
  http:
  - timeout: 3s
    route:
    - destination:
        host: httpbin.org
      weight: 100
EOF
}

snip_manage_traffic_to_external_services_3() {
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin-ext
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-ext
  hostnames:
  - httpbin.org
  rules:
  - timeouts:
      request: 3s
    backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: httpbin.org
      port: 80
EOF
}

snip_manage_traffic_to_external_services_4() {
kubectl exec "$SOURCE_POD" -c sleep -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
}

! read -r -d '' snip_manage_traffic_to_external_services_4_out <<\ENDSNIP
504
real    0m3.149s
user    0m0.004s
sys     0m0.004s
ENDSNIP

snip_cleanup_the_controlled_access_to_external_services_1() {
kubectl delete serviceentry httpbin-ext google
kubectl delete virtualservice httpbin-ext --ignore-not-found=true
}

snip_cleanup_the_controlled_access_to_external_services_2() {
kubectl delete serviceentry httpbin-ext
kubectl delete httproute httpbin-ext --ignore-not-found=true
}

snip_ibm_cloud_private_1() {
grep service_cluster_ip_range cluster/config.yaml
}

! read -r -d '' snip_ibm_cloud_private_2 <<\ENDSNIP
service_cluster_ip_range: 10.0.0.1/24
ENDSNIP

snip_ibm_cloud_kubernetes_service_1() {
ibmcloud ks cluster get -c my-cluster | grep "Service Subnet"
}

! read -r -d '' snip_ibm_cloud_kubernetes_service_1_out <<\ENDSNIP
Service Subnet:                 172.21.0.0/16
ENDSNIP

snip_google_kubernetes_engine_gke_1() {
gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
}

! read -r -d '' snip_google_kubernetes_engine_gke_1_out <<\ENDSNIP
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
ENDSNIP

snip_kubenet_1() {
az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep Cidr
}

! read -r -d '' snip_kubenet_1_out <<\ENDSNIP
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
ENDSNIP

snip_azure_cni_1() {
az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep serviceCidr
}

! read -r -d '' snip_azure_cni_1_out <<\ENDSNIP
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
ENDSNIP

snip_azure_cni_2() {
az aks show --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER}" | grep nodeResourceGroup
}

! read -r -d '' snip_azure_cni_2_out <<\ENDSNIP
  "nodeResourceGroup": "MC_user-rg_user-cluster_region",
  "nodeResourceGroupProfile": null,
az network vnet list -g MC_user-rg_user-cluster_region | grep name
    "name": "aks-vnet-74242220",
        "name": "aks-subnet",
az network vnet show -g MC_user-rg_user-cluster_region -n aks-vnet-74242220 | grep addressPrefix
    "addressPrefixes": [
      "addressPrefix": "10.224.0.0/16",
ENDSNIP

snip_minikube_docker_for_desktop_bare_metal_1() {
kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
}

! read -r -d '' snip_minikube_docker_for_desktop_bare_metal_1_out <<\ENDSNIP
      --service-cluster-ip-range=10.96.0.0/12
ENDSNIP

snip_access_the_external_services_1() {
kubectl exec "$SOURCE_POD" -c sleep -- curl -sS http://httpbin.org/headers
}

! read -r -d '' snip_access_the_external_services_1_out <<\ENDSNIP
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
  }
}
ENDSNIP

snip_cleanup_1() {
kubectl delete -f samples/sleep/sleep.yaml
}
