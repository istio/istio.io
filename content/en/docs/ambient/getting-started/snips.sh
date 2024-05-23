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
#          docs/ambient/getting-started/index.md
####################################################################################################

snip_download_and_install_2() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }
}

snip_download_and_install_3() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --skip-confirmation
}

snip_download_and_install_5() {
kubectl get pods,daemonset -n istio-system
}

! IFS=$'\n' read -r -d '' snip_download_and_install_5_out <<\ENDSNIP
NAME                                        READY   STATUS    RESTARTS   AGE
pod/istio-cni-node-btbjf                    1/1     Running   0          2m18s
pod/istiod-55b74b77bd-xggqf                 1/1     Running   0          2m27s
pod/ztunnel-5m27h                           1/1     Running   0          2m10s

NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m18s
daemonset.apps/ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
ENDSNIP

snip_deploy_the_sample_application_1() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
}

snip_deploy_the_sample_application_2() {
kubectl apply -f samples/sleep/sleep.yaml
kubectl apply -f samples/sleep/notsleep.yaml
}

snip_deploy_the_sample_application_3() {
kubectl apply -f samples/bookinfo/gateway-api/bookinfo-gateway.yaml
}

snip_deploy_the_sample_application_4() {
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
}

snip_deploy_the_sample_application_5() {
kubectl wait --for=condition=programmed gtw/bookinfo-gateway
export GATEWAY_HOST=bookinfo-gateway-istio.default
export GATEWAY_SERVICE_ACCOUNT=ns/default/sa/bookinfo-gateway-istio
}

snip_verify_traffic_sleep_to_ingress() {
kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_sleep_to_ingress_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_verify_traffic_sleep_to_productpage() {
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_sleep_to_productpage_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_verify_traffic_notsleep_to_productpage() {
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_verify_traffic_notsleep_to_productpage_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_1() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_1_out <<\ENDSNIP
namespace/default labeled
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_2() {
kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_2_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_3() {
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_3_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_4() {
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_4_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_layer_4_authorization_policy_1() {
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
        principals:
        - cluster.local/ns/default/sa/sleep
        - cluster.local/$GATEWAY_SERVICE_ACCOUNT
EOF
}

snip_layer_4_authorization_policy_2() {
# this should succeed
kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_layer_4_authorization_policy_2_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_layer_4_authorization_policy_3() {
# this should succeed
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_layer_4_authorization_policy_3_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_layer_4_authorization_policy_4() {
# this should fail with a connection reset error code 56
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_layer_4_authorization_policy_4_out <<\ENDSNIP
command terminated with exit code 56
ENDSNIP

snip_layer_7_authorization_policy_1() {
istioctl x waypoint apply --enroll-namespace --wait
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_1_out <<\ENDSNIP
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
ENDSNIP

snip_layer_7_authorization_policy_2() {
kubectl get gtw waypoint
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_2_out <<\ENDSNIP
NAME       CLASS            ADDRESS       PROGRAMMED   AGE
waypoint   istio-waypoint   10.96.58.95   True         61s
ENDSNIP

snip_layer_7_authorization_policy_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/sleep
    to:
    - operation:
        methods: ["GET"]
EOF
}

snip_layer_7_authorization_policy_4() {
# this should fail with an RBAC error because it is not a GET operation
kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage" -X DELETE
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_4_out <<\ENDSNIP
RBAC: access denied
ENDSNIP

snip_layer_7_authorization_policy_5() {
# this should fail with an RBAC error because the identity is not allowed
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_5_out <<\ENDSNIP
RBAC: access denied
ENDSNIP

snip_layer_7_authorization_policy_6() {
# this should continue to work
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_6_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_control_traffic_1() {
kubectl apply -f samples/bookinfo/gateway-api/route-reviews-90-10.yaml
}

snip_control_traffic_2() {
kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
}

snip_uninstall_1() {
kubectl label namespace default istio.io/dataplane-mode-
kubectl label namespace default istio.io/use-waypoint-
}

snip_uninstall_2() {
istioctl x waypoint delete --all
istioctl uninstall -y --purge
kubectl delete namespace istio-system
}

snip_uninstall_3() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/sleep/notsleep.yaml
}

snip_uninstall_4() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl delete -f -
}
