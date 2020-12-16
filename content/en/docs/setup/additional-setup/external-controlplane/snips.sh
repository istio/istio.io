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

snip_set_up_a_gateway_in_the_external_cluster_4() {
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

snip_set_up_a_gateway_in_the_external_cluster_5() {
kubectl create namespace external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
kubectl apply -f external-istiod-gw.yaml --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_set_up_the_remote_cluster_1() {
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
    istiodRemote:
      enabled: true

  values:
    global:
      caAddress: $EXTERNAL_ISTIOD_ADDR:15012
      istioNamespace: external-istiod
      meshID: mesh1
      multiCluster:
        clusterName: $REMOTE_CLUSTER_NAME
    istiodRemote:
      injectionURL: https://$EXTERNAL_ISTIOD_ADDR:15017/inject
    base:
      validationURL: https://$EXTERNAL_ISTIOD_ADDR:15017/validate
EOF
}

snip_set_up_the_remote_cluster_2() {
kubectl create namespace external-istiod --context="${CTX_REMOTE_CLUSTER}"
istioctl manifest generate -f remote-config-cluster.yaml  | kubectl apply --context="${CTX_REMOTE_CLUSTER}" -f -
}

snip_set_up_the_control_plane_in_the_external_cluster_1() {
kubectl create sa istiod-service-account -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
istioctl x create-remote-secret \
  --context="${CTX_REMOTE_CLUSTER}" \
  --type=config \
  --namespace=external-istiod | \
  kubectl apply -f - --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_set_up_the_control_plane_in_the_external_cluster_2() {
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

snip_set_up_the_control_plane_in_the_external_cluster_3() {
istioctl install -f external-istiod.yaml --context="${CTX_EXTERNAL_CLUSTER}"
}

snip_validate_the_installation_1() {
kubectl get pod -l app=istio-ingressgateway -n external-istiod --context="${CTX_REMOTE_CLUSTER}"
}

snip_validate_the_installation_2() {
kubectl label namespace default istio-injection=enabled --context="${CTX_REMOTE_CLUSTER}"
kubectl apply -f samples/helloworld/helloworld.yaml --context="${CTX_REMOTE_CLUSTER}"
kubectl get pod -l app=helloworld --context="${CTX_REMOTE_CLUSTER}"
}

snip_validate_the_installation_3() {
kubectl apply -f samples/helloworld/helloworld-gateway.yaml --context="${CTX_REMOTE_CLUSTER}"
}

snip_validate_the_installation_4() {
curl -s "http://${GATEWAY_URL}/hello" | grep -o "Hello"
}
