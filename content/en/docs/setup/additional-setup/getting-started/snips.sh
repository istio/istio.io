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
#          docs/setup/additional-setup/getting-started/index.md
####################################################################################################
source "content/en/boilerplates/snips/trace-generation.sh"

snip__1() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=6b9b7346ca5b54a50c3afb0a0573b16b1c84336a" | kubectl apply -f -; }
}

snip_download_istio_1() {
curl -L https://istio.io/downloadIstio | sh -
}

snip_download_istio_2() {
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.19.0 TARGET_ARCH=x86_64 sh -
}

snip_download_istio_4() {
export PATH=$PWD/bin:$PATH
}

snip_install_istio_1() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true -f samples/bookinfo/demo-profile-no-gateways.yaml -y
}

! read -r -d '' snip_install_istio_1_out <<\ENDSNIP
✔ Istio core installed
✔ Istiod installed
✔ Installation complete
ENDSNIP

snip_install_istio_2() {
kubectl label namespace default istio-injection=enabled
}

! read -r -d '' snip_install_istio_2_out <<\ENDSNIP
namespace/default labeled
ENDSNIP

snip_deploy_the_sample_application_1() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

! read -r -d '' snip_deploy_the_sample_application_1_out <<\ENDSNIP
service/details created
serviceaccount/bookinfo-details created
deployment.apps/details-v1 created
service/ratings created
serviceaccount/bookinfo-ratings created
deployment.apps/ratings-v1 created
service/reviews created
serviceaccount/bookinfo-reviews created
deployment.apps/reviews-v1 created
deployment.apps/reviews-v2 created
deployment.apps/reviews-v3 created
service/productpage created
serviceaccount/bookinfo-productpage created
deployment.apps/productpage-v1 created
ENDSNIP

snip_deploy_the_sample_application_2() {
kubectl get services
}

! read -r -d '' snip_deploy_the_sample_application_2_out <<\ENDSNIP
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
ENDSNIP

snip_deploy_the_sample_application_3() {
kubectl get pods
}

! read -r -d '' snip_deploy_the_sample_application_3_out <<\ENDSNIP
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
ENDSNIP

snip_deploy_the_sample_application_4() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_deploy_the_sample_application_4_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_open_the_application_to_outside_traffic_1() {
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
}

! read -r -d '' snip_open_the_application_to_outside_traffic_1_out <<\ENDSNIP
gateway.gateway.networking.k8s.io/bookinfo-gateway created
httproute.gateway.networking.k8s.io/bookinfo created
ENDSNIP

snip_open_the_application_to_outside_traffic_2() {
kubectl wait --for=condition=programmed gtw bookinfo-gateway
}

snip_open_the_application_to_outside_traffic_3() {
istioctl analyze
}

! read -r -d '' snip_open_the_application_to_outside_traffic_3_out <<\ENDSNIP
✔ No validation issues found when analyzing namespace: default.
ENDSNIP

snip_determining_the_ingress_ip_and_ports_1() {
export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
}

snip_determining_the_ingress_ip_and_ports_2() {
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
}

snip_determining_the_ingress_ip_and_ports_3() {
echo "$GATEWAY_URL"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_3_out <<\ENDSNIP
169.48.8.37:80
ENDSNIP

snip_verify_external_access_1() {
echo "http://$GATEWAY_URL/productpage"
}

snip_view_the_dashboard_1() {
kubectl apply -f samples/addons
kubectl rollout status deployment/kiali -n istio-system
}

! read -r -d '' snip_view_the_dashboard_1_out <<\ENDSNIP
Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
deployment "kiali" successfully rolled out
ENDSNIP

snip_view_the_dashboard_2() {
istioctl dashboard kiali
}

snip_uninstall_1() {
kubectl delete -f samples/addons
istioctl uninstall -y --purge
}

snip_uninstall_2() {
kubectl delete namespace istio-system
}

snip_uninstall_3() {
kubectl label namespace default istio-injection-
}
