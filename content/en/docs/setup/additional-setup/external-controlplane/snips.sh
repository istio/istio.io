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
#          docs/setup/additional-setup/external-controlplane/index.md
####################################################################################################

snip_set_up_a_gateway_in_the_external_cluster_1() {
cat <<EOF > controlplane-gateway.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  components:
    ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            ports:
              - port: 15021
                targetPort: 15021
                name: status-port
              - port: 15012
                targetPort: 15012
                name: tls-xds
              - port: 15017
                targetPort: 15017
                name: tls-webhook
EOF
}

snip_set_up_a_gateway_in_the_external_cluster_2() {
istioctl install -f controlplane-gateway.yaml --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_set_up_a_gateway_in_the_external_cluster_3() {
kubectl get po -n istio-system --context="${CTX_EXTERNAL_CLUSTER}"
}

! read -r -d '' snip_set_up_a_gateway_in_the_external_cluster_3_out <<\ENDSNIP
NAME                                   READY   STATUS    RESTARTS   AGE
istio-ingressgateway-9d4c7f5c7-7qpzz   1/1     Running   0          29s
istiod-68488cd797-mq8dn                1/1     Running   0          38s
ENDSNIP

snip_set_up_the_control_plane_in_the_external_cluster_1() {
kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_set_up_the_control_plane_in_the_external_cluster_2() {
kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
istioctl x create-remote-secret \
  --context="${CTX_REMOTE_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_get_external_istiod_iop() {
cat <<EOF > external-istiod.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: external-istiod
spec:
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    base:
      enabled: false
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      operatorManageWebhooks: true
      meshID: mesh1
      multiCluster:
        clusterName: $REMOTE_CLUSTER_NAME
    pilot:
      env:
        INJECTION_WEBHOOK_CONFIG_NAME: ""
        VALIDATION_WEBHOOK_CONFIG_NAME: ""
EOF
}

snip_set_up_the_control_plane_in_the_external_cluster_4() {
istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_set_up_the_control_plane_in_the_external_cluster_5() {
kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
}

! read -r -d '' snip_set_up_the_control_plane_in_the_external_cluster_5_out <<\ENDSNIP
NAME                      READY   STATUS    RESTARTS   AGE
istiod-779bd6fdcf-bd6rg   1/1     Running   0          70s
ENDSNIP

snip_get_external_istiod_gateway_config() {
cat <<EOF > external-istiod-gw.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: external-istiod-gw
  namespace: external-istiod
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 15012
        protocol: https
        name: https-XDS
      tls:
        mode: SIMPLE
        credentialName: $SSL_SECRET_NAME
      hosts:
      - $EXTERNAL_ISTIOD_ADDR
    - port:
        number: 15017
        protocol: https
        name: https-WEBHOOK
      tls:
        mode: SIMPLE
        credentialName: $SSL_SECRET_NAME
      hosts:
      - $EXTERNAL_ISTIOD_ADDR
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
   name: external-istiod-vs
   namespace: external-istiod
spec:
    hosts:
    - $EXTERNAL_ISTIOD_ADDR
    gateways:
    - external-istiod-gw
    http:
    - match:
      - port: 15012
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 15012
    - match:
      - port: 15017
      route:
      - destination:
          host: istiod.external-istiod.svc.cluster.local
          port:
            number: 443
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: external-istiod-dr
  namespace: external-istiod
spec:
  host: istiod.external-istiod.svc.cluster.local
  trafficPolicy:
    portLevelSettings:
    - port:
        number: 15012
      tls:
        mode: SIMPLE
      connectionPool:
        http:
          h2UpgradePolicy: UPGRADE
    - port:
        number: 443
      tls:
        mode: SIMPLE
EOF
}

snip_set_up_the_control_plane_in_the_external_cluster_7() {
kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_get_remote_config_cluster_iop() {
cat <<EOF > remote-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
  profile: remote
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    pilot:
      enabled: false
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
    istiodRemote:
      enabled: true
  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      meshID: mesh1
      multiCluster:
        clusterName: $REMOTE_CLUSTER_NAME
      network: network1
    istiodRemote:
      injectionURL: https://$EXTERNAL_ISTIOD_ADDR:15017/inject
    base:
      validationURL: https://$EXTERNAL_ISTIOD_ADDR:15017/validate
EOF
}

snip_set_up_the_remote_cluster_2() {
istioctl manifest generate -f remote-config-cluster.yaml | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
}

snip_set_up_the_remote_cluster_3() {
kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_set_up_the_remote_cluster_3_out <<\ENDSNIP
NAME                                     WEBHOOKS   AGE
istio-sidecar-injector-external-istiod   4          6m24s
ENDSNIP

snip_set_up_the_remote_cluster_4() {
kubectl get validatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_set_up_the_remote_cluster_4_out <<\ENDSNIP
NAME                     WEBHOOKS   AGE
istiod-external-istiod   1          6m32s
ENDSNIP

snip_set_up_the_remote_cluster_5() {
kubectl get configmaps -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_set_up_the_remote_cluster_5_out <<\ENDSNIP
NAME                                   DATA   AGE
istio                                  2      2m1s
istio-ca-root-cert                     1      2m9s
istio-leader                           0      2m9s
istio-namespace-controller-election    0      2m11s
istio-sidecar-injector                 2      2m1s
istio-validation-controller-election   0      2m9s
ENDSNIP

snip_set_up_the_remote_cluster_6() {
kubectl get secrets -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_set_up_the_remote_cluster_6_out <<\ENDSNIP
NAME                                               TYPE                                  DATA   AGE
default-token-m9nnj                                kubernetes.io/service-account-token   3      2m37s
istio-ca-secret                                    istio.io/ca-root                      5      18s
istio-reader-service-account-token-prnvv           kubernetes.io/service-account-token   3      2m31s
istiod-service-account-token-z2cvz                 kubernetes.io/service-account-token   3      2m30s
ENDSNIP

snip_deploy_a_sample_application_1() {
kubectl create --context="${CTX_REMOTE_CLUSTER}" namespace sample
kubectl label --context="${CTX_REMOTE_CLUSTER}" namespace sample istio-injection=enabled
}

snip_deploy_a_sample_application_2() {
kubectl apply -f samples/helloworld/helloworld.yaml -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f samples/helloworld/helloworld.yaml -l version=v1 -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f samples/sleep/sleep.yaml -n sample --context="${CTX_REMOTE_CLUSTER}"
}

snip_deploy_a_sample_application_3() {
kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_deploy_a_sample_application_3_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-5b75657f75-ncpc5   2/2     Running   0          10s
sleep-64d7d56698-wqjnm           2/2     Running   0          9s
ENDSNIP

snip_deploy_a_sample_application_4() {
kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! read -r -d '' snip_deploy_a_sample_application_4_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
ENDSNIP

snip_enable_gateways_1() {
cat <<EOF > istio-ingressgateway.yaml
apiVersion: operator.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    ingressGateways:
    - namespace: external-istiod
      name: istio-ingressgateway
      enabled: true
  values:
    gateways:
      istio-ingressgateway:
        injectionTemplate: gateway
EOF
istioctl install -f istio-ingressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
}

snip_enable_gateways_2() {
cat <<EOF > istio-egressgateway.yaml
apiVersion: operator.istio.io/v1alpha1
kind: IstioOperator
spec:
  profile: empty
  components:
    egressGateways:
    - namespace: external-istiod
      name: istio-egressgateway
      enabled: true
  values:
    gateways:
      istio-egressgateway:
        injectionTemplate: gateway
EOF
istioctl install -f istio-egressgateway.yaml --context="${CTX_REMOTE_CLUSTER}"
}

snip_enable_gateways_3() {
kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_enable_gateways_3_out <<\ENDSNIP
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-7bcd5c6bbd-kmtl4   1/1     Running   0          8m4s
ENDSNIP

snip_enable_gateways_4() {
kubectl apply -f samples/helloworld/helloworld-gateway.yaml -n sample --context="${CTX_REMOTE_CLUSTER}"
}

snip_enable_gateways_5() {
export INGRESS_HOST=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n external-istiod --context="${CTX_REMOTE_CLUSTER}" get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
}

snip_enable_gateways_6() {
curl -s "http://${GATEWAY_URL}/hello"
}

! read -r -d '' snip_enable_gateways_6_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
ENDSNIP

snip_mesh_operator_steps_multiclusteroperatorsteps_1() {
kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
istioctl x create-remote-secret \
  --context="${CTX_SECOND_CLUSTER}" \
  --type=remote \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_get_second_config_cluster_iop() {
cat <<EOF > second-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
 namespace: external-istiod
spec:
  profile: remote
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    pilot:
      enabled: false
    ingressGateways:
    - name: istio-ingressgateway
      enabled: false
    istiodRemote:
      enabled: true
  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      meshID: mesh1
      multiCluster:
        clusterName: $SECOND_CLUSTER_NAME
      network: network2
    istiodRemote:
      injectionURL: https://$EXTERNAL_ISTIOD_ADDR:15017/inject
    base:
      validationURL: https://$EXTERNAL_ISTIOD_ADDR:15017/validate
EOF
}

snip_mesh_operator_steps_multiclusteroperatorsteps_3() {
istioctl manifest generate -f second-config-cluster.yaml | kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
}

snip_mesh_operator_steps_multiclusteroperatorsteps_4() {
kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_mesh_operator_steps_multiclusteroperatorsteps_4_out <<\ENDSNIP
NAME                                     WEBHOOKS   AGE
istio-sidecar-injector-external-istiod   4          4m13s
ENDSNIP

snip_mesh_operator_steps_multiclusteroperatorsteps_5() {
kubectl get validatingwebhookconfiguration -n external-istiod --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_mesh_operator_steps_multiclusteroperatorsteps_5_out <<\ENDSNIP
NAME                     WEBHOOKS   AGE
istiod-external-istiod   1          4m25s
ENDSNIP

snip_mesh_operator_steps_multiclusteroperatorsteps_6() {
kubectl get configmaps -n external-istiod --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_mesh_operator_steps_multiclusteroperatorsteps_6_out <<\ENDSNIP
NAME                     DATA   AGE
istio                    2      4m30s
istio-sidecar-injector   2      4m30s
ENDSNIP

snip_mesh_operator_steps_multiclusteroperatorsteps_7() {
kubectl get secrets -n external-istiod --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_mesh_operator_steps_multiclusteroperatorsteps_7_out <<\ENDSNIP
NAME                                       TYPE                                  DATA   AGE
default-token-6pmf7                        kubernetes.io/service-account-token   3      15m
istio-reader-service-account-token-lkmwj   kubernetes.io/service-account-token   3      15m
istiod-service-account-token-6x7p9         kubernetes.io/service-account-token   3      15m
ENDSNIP

snip_setup_easywest_gateways_1() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster "${REMOTE_CLUSTER_NAME}" --network network1 > eastwest-gateway-1.yaml
istioctl manifest generate -f eastwest-gateway-1.yaml \
    --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
    --set values.global.istioNamespace=external-istiod | \
    kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
}

snip_setup_easywest_gateways_2() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster "${SECOND_CLUSTER_NAME}" --network network2 > eastwest-gateway-2.yaml
istioctl manifest generate -f eastwest-gateway-2.yaml \
    --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
    --set values.global.istioNamespace=external-istiod | \
    kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
}

snip_setup_easywest_gateways_3() {
kubectl --context="${REMOTE_CLUSTER_NAME}" get svc istio-eastwestgateway -n istio-system
}

! read -r -d '' snip_setup_easywest_gateways_3_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
ENDSNIP

snip_setup_easywest_gateways_4() {
kubectl --context="${CTX_SECOND_CLUSTER}" get svc istio-eastwestgateway -n istio-system
}

! read -r -d '' snip_setup_easywest_gateways_4_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.99   ...       51s
ENDSNIP

snip_setup_easywest_gateways_5() {
kubectl --context="${REMOTE_CLUSTER_NAME}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_setup_easywest_gateways_6() {
kubectl --context="${CTX_SECOND_CLUSTER}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml
}

snip_validate_the_installation_1() {
kubectl create --context="${CTX_SECOND_CLUSTER}" namespace sample
kubectl label --context="${CTX_SECOND_CLUSTER}" namespace sample istio-injection=enabled
}

snip_validate_the_installation_2() {
kubectl apply -f samples/helloworld/helloworld.yaml -l service=helloworld -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f samples/helloworld/helloworld.yaml -l version=v2 -n sample --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f samples/sleep/sleep.yaml -n sample --context="${CTX_SECOND_CLUSTER}"
}

snip_validate_the_installation_3() {
kubectl get pod -n sample --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_validate_the_installation_3_out <<\ENDSNIP
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v2-5b75657f75-2dpzp   2/2     Running   0          10s
sleep-64d7d56698-clhxb           2/2     Running   0          9s
ENDSNIP

snip_validate_the_installation_4() {
kubectl exec --context="${CTX_SECOND_CLUSTER}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_SECOND_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! read -r -d '' snip_validate_the_installation_4_out <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-5b75657f75-2dpzp
ENDSNIP

snip_validate_the_installation_5() {
for i in {1..10}; do curl -s "http://${GATEWAY_URL}/hello"; done
}

! read -r -d '' snip_validate_the_installation_5_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
Hello version: v2, instance: helloworld-v2-5b75657f75-2dpzp
Hello version: v1, instance: helloworld-v1-5b75657f75-ncpc5
Hello version: v2, instance: helloworld-v2-5b75657f75-2dpzp
...
ENDSNIP
