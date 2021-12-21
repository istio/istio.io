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
#          docs/setup/install/external-controlplane/index.md
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

snip_get_remote_config_cluster_iop() {
cat <<EOF > remote-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: external-istiod
spec:
  profile: external
  components:
    base:
      enabled: true
  values:
    global:
      istioNamespace: external-istiod
    pilot:
      configMap: true
    istiodRemote:
      injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/:ENV:cluster=${REMOTE_CLUSTER_NAME}:ENV:net=network1
    base:
      validationURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/validate
EOF
}

snip_set_up_the_remote_config_cluster_2() {
kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"
istioctl manifest generate -f remote-config-cluster.yaml | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
}

snip_set_up_the_remote_config_cluster_3() {
kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

! read -r -d '' snip_set_up_the_remote_config_cluster_3_out <<\ENDSNIP
NAME                                     WEBHOOKS   AGE
istio-sidecar-injector-external-istiod   4          6m24s
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
  profile: empty
  meshConfig:
    rootNamespace: external-istiod
    defaultConfig:
      discoveryAddress: $EXTERNAL_ISTIOD_ADDR:15012
      proxyMetadata:
        XDS_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
        CA_ROOT_CA: /etc/ssl/certs/ca-certificates.crt
  components:
    pilot:
      enabled: true
      k8s:
        overlays:
        - kind: Deployment
          name: istiod
          patches:
          - path: spec.template.spec.volumes[100]
            value: |-
              name: config-volume
              configMap:
                name: istio
          - path: spec.template.spec.volumes[100]
            value: |-
              name: inject-volume
              configMap:
                name: istio-sidecar-injector
          - path: spec.template.spec.containers[0].volumeMounts[100]
            value: |-
              name: config-volume
              mountPath: /etc/istio/config
          - path: spec.template.spec.containers[0].volumeMounts[100]
            value: |-
              name: inject-volume
              mountPath: /var/lib/istio/inject
        env:
        - name: INJECTION_WEBHOOK_CONFIG_NAME
          value: ""
        - name: VALIDATION_WEBHOOK_CONFIG_NAME
          value: ""
        - name: EXTERNAL_ISTIOD
          value: "true"
        - name: CLUSTER_ID
          value: ${REMOTE_CLUSTER_NAME}
        - name: SHARED_MESH_CONFIG
          value: istio
  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      operatorManageWebhooks: true
      meshID: mesh1
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
helloworld-v1-776f57d5f6-s7zfc   2/2     Running   0          10s
sleep-64d7d56698-wqjnm           2/2     Running   0          9s
ENDSNIP

snip_deploy_a_sample_application_4() {
kubectl exec --context="${CTX_REMOTE_CLUSTER}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_REMOTE_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! read -r -d '' snip_deploy_a_sample_application_4_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
ENDSNIP

snip_enable_gateways_1() {
cat <<EOF > istio-ingressgateway.yaml
apiVersion: install.istio.io/v1alpha1
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
apiVersion: install.istio.io/v1alpha1
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
Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
ENDSNIP

snip_register_the_new_cluster_1() {
istioctl x create-remote-secret \
  --context="${CTX_SECOND_CLUSTER}" \
  --name="${SECOND_CLUSTER_NAME}" \
  --type=remote \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_REMOTE_CLUSTER}" #TODO use --context="{CTX_EXTERNAL_CLUSTER}" when #31946 is fixed.
}

snip_get_second_config_cluster_iop() {
cat <<EOF > second-config-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: external-istiod
spec:
  profile: external
  values:
    global:
      istioNamespace: external-istiod
    istiodRemote:
      injectionURL: https://${EXTERNAL_ISTIOD_ADDR}:15017/inject/:ENV:cluster=${SECOND_CLUSTER_NAME}:ENV:net=network2
EOF
}

snip_register_the_new_cluster_3() {
istioctl manifest generate -f second-config-cluster.yaml | kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
}

snip_register_the_new_cluster_4() {
kubectl get mutatingwebhookconfiguration -n external-istiod --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_register_the_new_cluster_4_out <<\ENDSNIP
NAME                                     WEBHOOKS   AGE
istio-sidecar-injector-external-istiod   4          4m13s
ENDSNIP

snip_setup_eastwest_gateways_1() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster "${REMOTE_CLUSTER_NAME}" --network network1 > eastwest-gateway-1.yaml
istioctl manifest generate -f eastwest-gateway-1.yaml \
    --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
    --set values.global.istioNamespace=external-istiod | \
    kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
}

snip_setup_eastwest_gateways_2() {
samples/multicluster/gen-eastwest-gateway.sh \
    --mesh mesh1 --cluster "${SECOND_CLUSTER_NAME}" --network network2 > eastwest-gateway-2.yaml
istioctl manifest generate -f eastwest-gateway-2.yaml \
    --set values.gateways.istio-ingressgateway.injectionTemplate=gateway \
    --set values.global.istioNamespace=external-istiod | \
    kubectl apply --context="${CTX_SECOND_CLUSTER}" -f -
}

snip_setup_eastwest_gateways_3() {
kubectl --context="${CTX_REMOTE_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
}

! read -r -d '' snip_setup_eastwest_gateways_3_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.98   ...       51s
ENDSNIP

snip_setup_eastwest_gateways_4() {
kubectl --context="${CTX_SECOND_CLUSTER}" get svc istio-eastwestgateway -n external-istiod
}

! read -r -d '' snip_setup_eastwest_gateways_4_out <<\ENDSNIP
NAME                    TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)   AGE
istio-eastwestgateway   LoadBalancer   10.0.12.121   34.122.91.99   ...       51s
ENDSNIP

snip_setup_eastwest_gateways_5() {
kubectl --context="${CTX_REMOTE_CLUSTER}" apply -n external-istiod -f \
    samples/multicluster/expose-services.yaml
}

snip_setup_eastwest_gateways_6() {
kubectl --context="${CTX_SECOND_CLUSTER}" apply -n external-istiod -f \
    samples/multicluster/expose-services.yaml
}

snip_validate_the_installation_1() {
kubectl create --context="${CTX_SECOND_CLUSTER}" namespace sample
kubectl label --context="${CTX_SECOND_CLUSTER}" namespace sample istio-injection=enabled
}

snip_validate_the_installation_2() {
kubectl apply -f samples/helloworld/helloworld.yaml -l service=helloworld -n sample --context="${CTX_SECOND_CLUSTER}"
kubectl apply -f samples/helloworld/helloworld.yaml -l version=v2 -n sample --context="${CTX_SECOND_CLUSTER}"
kubectl apply -f samples/sleep/sleep.yaml -n sample --context="${CTX_SECOND_CLUSTER}"
}

snip_validate_the_installation_3() {
kubectl get pod -n sample --context="${CTX_SECOND_CLUSTER}"
}

! read -r -d '' snip_validate_the_installation_3_out <<\ENDSNIP
NAME                            READY   STATUS    RESTARTS   AGE
helloworld-v2-54df5f84b-9hxgw   2/2     Running   0          10s
sleep-557747455f-wtdbr          2/2     Running   0          9s
ENDSNIP

snip_validate_the_installation_4() {
kubectl exec --context="${CTX_SECOND_CLUSTER}" -n sample -c sleep \
    "$(kubectl get pod --context="${CTX_SECOND_CLUSTER}" -n sample -l app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS helloworld.sample:5000/hello
}

! read -r -d '' snip_validate_the_installation_4_out <<\ENDSNIP
Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
ENDSNIP

snip_validate_the_installation_5() {
for i in {1..10}; do curl -s "http://${GATEWAY_URL}/hello"; done
}

! read -r -d '' snip_validate_the_installation_5_out <<\ENDSNIP
Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
Hello version: v1, instance: helloworld-v1-776f57d5f6-s7zfc
Hello version: v2, instance: helloworld-v2-54df5f84b-9hxgw
...
ENDSNIP
