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
#          docs/setup/getting-started/index.md
####################################################################################################

snip_download_istio_download_1() {
curl -L https://istio.io/downloadIstio | sh -
}

snip_download_istio_download_3() {
export PATH=$PWD/bin:$PATH
}

snip_install_istio_install_1() {
istioctl install --set profile=demo
}

! read -r -d '' snip_install_istio_install_1_out <<\ENDSNIP
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete
ENDSNIP

snip_install_istio_install_2() {
kubectl label namespace default istio-injection=enabled
}

! read -r -d '' snip_install_istio_install_2_out <<\ENDSNIP
namespace/default labeled
ENDSNIP

snip_deploy_the_sample_application_bookinfo_1() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

! read -r -d '' snip_deploy_the_sample_application_bookinfo_1_out <<\ENDSNIP
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

snip_deploy_the_sample_application_bookinfo_2() {
kubectl get services
}

! read -r -d '' snip_deploy_the_sample_application_bookinfo_2_out <<\ENDSNIP
NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
ENDSNIP

snip_deploy_the_sample_application_bookinfo_3() {
kubectl get pods
}

! read -r -d '' snip_deploy_the_sample_application_bookinfo_3_out <<\ENDSNIP
NAME                              READY   STATUS    RESTARTS   AGE
details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
ENDSNIP

snip_deploy_the_sample_application_bookinfo_4() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_deploy_the_sample_application_bookinfo_4_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_open_the_application_to_outside_traffic_ip_1() {
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

! read -r -d '' snip_open_the_application_to_outside_traffic_ip_1_out <<\ENDSNIP
gateway.networking.istio.io/bookinfo-gateway created
virtualservice.networking.istio.io/bookinfo created
ENDSNIP

snip_open_the_application_to_outside_traffic_ip_2() {
istioctl analyze
}

! read -r -d '' snip_open_the_application_to_outside_traffic_ip_2_out <<\ENDSNIP
✔ No validation issues found when analyzing namespace: default.
ENDSNIP

snip_determining_the_ingress_ip_and_ports_1() {
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
}

snip_determining_the_ingress_ip_and_ports_2() {
echo "$INGRESS_PORT"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_2_out <<\ENDSNIP
32194
ENDSNIP

snip_determining_the_ingress_ip_and_ports_3() {
echo "$SECURE_INGRESS_PORT"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_3_out <<\ENDSNIP
31632
ENDSNIP

snip_determining_the_ingress_ip_and_ports_4() {
export INGRESS_HOST=$(minikube ip)
}

snip_determining_the_ingress_ip_and_ports_5() {
echo "$INGRESS_HOST"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_5_out <<\ENDSNIP
192.168.4.102
ENDSNIP

snip_determining_the_ingress_ip_and_ports_6() {
minikube tunnel
}

snip_determining_the_ingress_ip_and_ports_7() {
kubectl get svc istio-ingressgateway -n istio-system
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_7_out <<\ENDSNIP
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
ENDSNIP

snip_determining_the_ingress_ip_and_ports_8() {
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
}

snip_determining_the_ingress_ip_and_ports_9() {
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
}

snip_determining_the_ingress_ip_and_ports_10() {
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
}

snip_determining_the_ingress_ip_and_ports_11() {
export INGRESS_HOST=workerNodeAddress
}

snip_determining_the_ingress_ip_and_ports_12() {
gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
}

snip_determining_the_ingress_ip_and_ports_13() {
ibmcloud ks workers --cluster cluster-name-or-id
export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
}

snip_determining_the_ingress_ip_and_ports_14() {
export INGRESS_HOST=127.0.0.1
}

snip_determining_the_ingress_ip_and_ports_15() {
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
}

snip_determining_the_ingress_ip_and_ports_16() {
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
}

snip_determining_the_ingress_ip_and_ports_17() {
echo "$GATEWAY_URL"
}

! read -r -d '' snip_determining_the_ingress_ip_and_ports_17_out <<\ENDSNIP
192.168.99.100:32194
ENDSNIP

snip_verify_external_access_confirm_1() {
echo http://"$GATEWAY_URL/productpage"
}

snip_view_the_dashboard_dashboard_1() {
kubectl apply -f samples/addons
while ! kubectl wait --for=condition=available --timeout=600s deployment/kiali -n istio-system; do sleep 1; done
}

snip_view_the_dashboard_dashboard_2() {
istioctl dashboard kiali
}

snip_uninstall_1() {
istioctl manifest generate --set profile=demo | kubectl delete --ignore-not-found=true -f -
}

snip_uninstall_2() {
kubectl delete namespace istio-system
}
