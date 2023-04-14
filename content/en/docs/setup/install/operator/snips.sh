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
#          docs/setup/install/operator/index.md
####################################################################################################

snip_deploy_istio_operator() {
istioctl operator init
}

snip_deploy_istio_operator_watch_ns() {
istioctl operator init --watchedNamespaces=istio-namespace1,istio-namespace2
}

snip_create_ns_istio_operator() {
kubectl create namespace istio-operator
}

snip_deploy_istio_operator_helm() {
helm install istio-operator manifests/charts/istio-operator \
    --set watchedNamespaces="istio-namespace1\,istio-namespace2" \
    -n istio-operator
}

snip_install_istio_demo_profile() {
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: demo
EOF
}

snip_kubectl_get_svc() {
kubectl get services -n istio-system
}

! read -r -d '' snip_kubectl_get_svc_out <<\ENDSNIP
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)   AGE
istio-egressgateway    ClusterIP      10.96.65.145    <none>           ...       30s
istio-ingressgateway   LoadBalancer   10.96.189.244   192.168.11.156   ...       30s
istiod                 ClusterIP      10.96.189.20    <none>           ...       37s
ENDSNIP

snip_kubectl_get_pods() {
kubectl get pods -n istio-system
}

! read -r -d '' snip_kubectl_get_pods_out <<\ENDSNIP
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-696cccb5-m8ndk      1/1     Running   0          68s
istio-ingressgateway-86cb4b6795-9jlrk   1/1     Running   0          68s
istiod-b47586647-sf6sw                  1/1     Running   0          74s
ENDSNIP

snip_update_to_default_profile() {
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
EOF
}

snip_update_to_default_profile_egress() {
kubectl apply -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: example-istiocontrolplane
spec:
  profile: default
  components:
    pilot:
      k8s:
        resources:
          requests:
            memory: 3072Mi
    egressGateways:
    - name: istio-egressgateway
      enabled: true
EOF
}

snip_verify_operator_cr() {
kubectl get iop --all-namespaces
}

! read -r -d '' snip_verify_operator_cr_out <<\ENDSNIP
NAMESPACE      NAME                        REVISION   STATUS    AGE
istio-system   example-istiocontrolplane              HEALTHY   11m
ENDSNIP

snip_cleanup() {
istioctl uninstall -y --purge
kubectl delete ns istio-system istio-operator
}
