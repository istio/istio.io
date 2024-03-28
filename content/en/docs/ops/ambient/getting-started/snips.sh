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

snip_download_and_install_2() {
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=f6102784e48833220d538e5a78309b71476529c4" | kubectl apply -f -; }
}

snip_download_and_install_3() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --set "components.ingressGateways[0].enabled=true" --set "components.ingressGateways[0].name=istio-ingressgateway" --skip-confirmation
}

snip_download_and_install_5() {
istioctl install --set values.pilot.env.PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING=true --set profile=ambient --skip-confirmation
}

snip_download_and_install_7() {
kubectl get pods -n istio-system
}

! IFS=$'\n' read -r -d '' snip_download_and_install_7_out <<\ENDSNIP
NAME                                    READY   STATUS    RESTARTS   AGE
istio-cni-node-zq94l                    1/1     Running   0          2m7s
istio-ingressgateway-56b9cb5485-ksnvc   1/1     Running   0          2m7s
istiod-56d848857c-mhr5w                 1/1     Running   0          2m9s
ztunnel-srrnm                           1/1     Running   0          2m5s
ENDSNIP

snip_download_and_install_8() {
kubectl get daemonset -n istio-system
}

! IFS=$'\n' read -r -d '' snip_download_and_install_8_out <<\ENDSNIP
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
ENDSNIP

snip_download_and_install_9() {
kubectl get pods -n istio-system
}

! IFS=$'\n' read -r -d '' snip_download_and_install_9_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
istio-cni-node-d9rdt      1/1     Running   0          2m15s
istiod-56d848857c-pwsd6   1/1     Running   0          2m23s
ztunnel-wp7hk             1/1     Running   0          2m9s
ENDSNIP

snip_download_and_install_10() {
kubectl get daemonset -n istio-system
}

! IFS=$'\n' read -r -d '' snip_download_and_install_10_out <<\ENDSNIP
NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m16s
ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
ENDSNIP

snip_deploy_the_sample_application_1() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
}

snip_deploy_the_sample_application_2() {
kubectl apply -f samples/sleep/sleep.yaml
kubectl apply -f samples/sleep/notsleep.yaml
}

snip_deploy_the_sample_application_3() {
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
}

snip_deploy_the_sample_application_4() {
export GATEWAY_HOST=istio-ingressgateway.istio-system
export GATEWAY_SERVICE_ACCOUNT=ns/istio-system/sa/istio-ingressgateway-service-account
}

snip_deploy_the_sample_application_5() {
sed -e 's/from: Same/from: All/'\
      -e '/^  name: bookinfo-gateway/a\
  namespace: istio-system\
'     -e '/^  - name: bookinfo-gateway/a\
    namespace: istio-system\
' samples/bookinfo/gateway-api/bookinfo-gateway.yaml | kubectl apply -f -
}

snip_deploy_the_sample_application_6() {
kubectl wait --for=condition=programmed gtw/bookinfo-gateway -n istio-system
export GATEWAY_HOST=bookinfo-gateway-istio.istio-system
export GATEWAY_SERVICE_ACCOUNT=ns/istio-system/sa/bookinfo-gateway-istio
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
kubectl logs ds/ztunnel -n istio-system  | grep inpod_enabled
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_1_out <<\ENDSNIP
inpod_enabled: true
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_2() {
kubectl label namespace default istio.io/dataplane-mode=ambient
}

snip_adding_your_application_to_the_ambient_mesh_3() {
kubectl logs ds/ztunnel -n istio-system | grep -o ".*starting proxy"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_3_out <<\ENDSNIP
... received netns, starting proxy
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_4() {
kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_4_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_5() {
kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_5_out <<\ENDSNIP
<title>Simple Bookstore App</title>
ENDSNIP

snip_adding_your_application_to_the_ambient_mesh_6() {
kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
}

! IFS=$'\n' read -r -d '' snip_adding_your_application_to_the_ambient_mesh_6_out <<\ENDSNIP
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
istioctl x waypoint apply --service-account bookinfo-productpage --wait
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_1_out <<\ENDSNIP
waypoint default/bookinfo-productpage applied
ENDSNIP

snip_layer_7_authorization_policy_2() {
kubectl get gtw bookinfo-productpage -o yaml
}

! IFS=$'\n' read -r -d '' snip_layer_7_authorization_policy_2_out <<\ENDSNIP
...
status:
  conditions:
  - lastTransitionTime: "2023-02-24T03:22:43Z"
    message: Resource programmed, assigned to service(s) bookinfo-productpage-istio-waypoint.default.svc.cluster.local:15008
    observedGeneration: 1
    reason: Programmed
    status: "True"
    type: Programmed
ENDSNIP

snip_layer_7_authorization_policy_3() {
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: productpage-viewer
  namespace: default
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: bookinfo-productpage
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/default/sa/sleep
        - cluster.local/$GATEWAY_SERVICE_ACCOUNT
    to:
    - operation:
        methods: ["GET"]
EOF
}

snip_layer_7_authorization_policy_4() {
# this should fail with an RBAC error because it is not a GET operation
kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" -X DELETE
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
istioctl x waypoint apply --service-account bookinfo-reviews --wait
}

! IFS=$'\n' read -r -d '' snip_control_traffic_1_out <<\ENDSNIP
waypoint default/bookinfo-reviews applied
ENDSNIP

snip_control_traffic_2() {
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-90-10.yaml
kubectl apply -f samples/bookinfo/networking/destination-rule-reviews.yaml
}

snip_control_traffic_3() {
kubectl apply -f samples/bookinfo/platform/kube/bookinfo-versions.yaml
kubectl apply -f samples/bookinfo/gateway-api/route-reviews-90-10.yaml
}

snip_control_traffic_4() {
kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://$GATEWAY_HOST/productpage | grep reviews-v.-; done"
}

snip_uninstall_1() {
kubectl label namespace default istio.io/dataplane-mode-
}

snip_uninstall_2() {
kubectl logs ds/ztunnel -n istio-system  | grep inpod
}

! IFS=$'\n' read -r -d '' snip_uninstall_2_out <<\ENDSNIP
Found 3 pods, using pod/ztunnel-jrxln
inpod_enabled: true
inpod_uds: /var/run/ztunnel/ztunnel.sock
inpod_port_reuse: true
inpod_mark: 1337
2024-03-26T00:02:06.161802Z  INFO ztunnel::inpod::workloadmanager: handling new stream
2024-03-26T00:02:06.162099Z  INFO ztunnel::inpod::statemanager: pod received snapshot sent
2024-03-26T00:41:05.518194Z  INFO ztunnel::inpod::statemanager: pod WorkloadUid("7ef61e18-725a-4726-84fa-05fc2a440879") received netns, starting proxy
2024-03-26T00:50:14.856284Z  INFO ztunnel::inpod::statemanager: pod delete request, draining proxy
ENDSNIP

snip_uninstall_3() {
istioctl x waypoint delete --all
istioctl uninstall -y --purge
kubectl delete namespace istio-system
}

snip_uninstall_4() {
kubectl delete -f samples/sleep/sleep.yaml
kubectl delete -f samples/sleep/notsleep.yaml
}

snip_uninstall_5() {
kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=f6102784e48833220d538e5a78309b71476529c4" | kubectl delete -f -
}
