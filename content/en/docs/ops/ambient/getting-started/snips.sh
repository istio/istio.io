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
#          docs/ops/ambient/getting-started/index.md
####################################################################################################

snip_download_and_install_download_2() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --skip-confirmation
}

snip_download_and_install_download_4() {
kubectl get pods -n istio-system
}

! read -r -d '' snip_download_and_install_download_4_out <<\ENDSNIP
NAME                                    READY   STATUS    RESTARTS   AGE
istio-cni-node-n9tcd                    1/1     Running   0          57s
istio-ingressgateway-5b79b5bb88-897lp   1/1     Running   0          57s
istiod-69d4d646cd-26cth                 1/1     Running   0          67s
ztunnel-lr7lz                           1/1     Running   0          69s
ENDSNIP

snip_download_and_install_download_5() {
kubectl get daemonset -n istio-system
}

! read -r -d '' snip_download_and_install_download_5_out <<\ENDSNIP
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   70s
ztunnel          1         1         1       1            1           <none>                   82s
ENDSNIP

snip_deploy_the_sample_application_bookinfo_2() {
kubectl apply -f samples/sleep/sleep.yaml
kubectl apply -f samples/sleep/notsleep.yaml
}

snip_deploy_the_sample_application_bookinfo_3() {
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

snip_verify_traffic_sleep_to_ingress() {
kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | grep -o "<title>.*</title>"
}

! read -r -d '' snip_verify_traffic_sleep_to_ingress_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_verify_traffic_sleep_to_productpage() {
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! read -r -d '' snip_verify_traffic_sleep_to_productpage_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_verify_traffic_notsleep_to_productpage() {
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! read -r -d '' snip_verify_traffic_notsleep_to_productpage_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_ambient_addtoambient_1() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

snip_l4_authorization_policy_1() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
EOF
}

snip_l7_authorization_policy_1() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.6.1" | kubectl apply -f -; }
}

snip_l7_authorization_policy_2() {
istioctl x waypoint apply --service-account bookinfo-productpage
}

! read -r -d '' snip_l7_authorization_policy_2_out <<\ENDSNIP
waypoint default/bookinfo-productpage applied
ENDSNIP

snip_l7_authorization_policy_3() {
kubectl get gtw bookinfo-productpage -o yaml
}

! read -r -d '' snip_l7_authorization_policy_4 <<\ENDSNIP
...
status:
  conditions:
  - lastTransitionTime: "2023-02-24T03:22:43Z"
    message: Deployed waypoint proxy to "default" namespace for "bookinfo-productpage" service account
    observedGeneration: 1
    reason: Ready
    status: "True"
    type: Ready
ENDSNIP

snip_l7_authorization_policy_5() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     istio.io/gateway-name: bookinfo-productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
   to:
   - operation:
       methods: ["GET"]
EOF
}

snip_l7_authorization_policy_6() {
# this should fail with an RBAC error because it is not a GET operation
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ -X DELETE
}

! read -r -d '' snip_l7_authorization_policy_6_out <<\ENDSNIP
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>405 Method Not Allowed</title>
<h1>Method Not Allowed</h1>
<p>The method is not allowed for the requested URL.</p>
ENDSNIP

snip_l7_authorization_policy_7() {
# this should fail with an RBAC error because the identity is not allowed
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/
}

! read -r -d '' snip_l7_authorization_policy_7_out <<\ENDSNIP
RBAC: access denied
ENDSNIP

snip_l7_authorization_policy_8() {
# this should continue to work
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! read -r -d '' snip_l7_authorization_policy_8_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_control_traffic_control_1() {
istioctl x waypoint apply --service-account bookinfo-reviews
}

! read -r -d '' snip_control_traffic_control_1_out <<\ENDSNIP
waypoint default/bookinfo-reviews applied
ENDSNIP

snip_control_traffic_control_2() {
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
kubectl apply -f samples/bookinfo/networking/destination-rule-reviews.yaml
}

snip_control_traffic_control_3() {
kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://istio-ingressgateway.istio-system/productpage | grep reviews-v.-; done"
}

snip_uninstall_uninstall_1() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/sleep/notsleep.yaml
}

snip_uninstall_uninstall_2() {
kubectl delete authorizationpolicy productpage-viewer
istioctl x waypoint delete --service-account bookinfo-reviews
istioctl x waypoint delete --service-account bookinfo-productpage
istioctl uninstall -y --purge
kubectl delete namespace istio-system
}

snip_uninstall_uninstall_3() {
kubectl label namespace default istio.io/dataplane-mode-
}
