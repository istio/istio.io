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
#          docs/tasks/traffic-management/ingress/ingress-sidecar-tls-termination/index.md
####################################################################################################

snip_before_you_begin_1() {
istioctl install --set profile=default --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
}

snip_before_you_begin_2() {
kubectl create ns test
kubectl label namespace test istio-injection=enabled
}

snip_enable_global_mtls_1() {
kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
}

snip_disable_peerauthentication_for_the_externally_exposed_httpbin_port_1() {
kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: disable-peer-auth-for-external-mtls-port
  namespace: test
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    9080:
      mode: DISABLE
EOF
}

snip_generate_ca_cert_server_certkey_and_client_certkey_1() {
#CA is example.com
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
#Server is httpbin.test.svc.cluster.local
openssl req -out httpbin.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout httpbin.test.svc.cluster.local.key -subj "/CN=httpbin.test.svc.cluster.local/O=httpbin organization"
openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in httpbin.test.svc.cluster.local.csr -out httpbin.test.svc.cluster.local.crt
#client is client.test.svc.cluster.local
openssl req -out client.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout client.test.svc.cluster.local.key -subj "/CN=client.test.svc.cluster.local/O=client organization"
openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.test.svc.cluster.local.csr -out client.test.svc.cluster.local.crt
}

snip_create_k8s_secrets_for_the_certificates_and_keys_1() {
kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
}

! read -r -d '' snip_deploy_the_httpbin_test_service_1 <<\ENDSNIP
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
ENDSNIP

snip_deploy_the_httpbin_test_service_2() {
kubectl -n test apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - port: 8443
    name: https
    targetPort: 9080
  - port: 8080
    name: http
    targetPort: 9081
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
      annotations:
        sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
        sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
}

snip_configure_httpbin_to_enable_external_mtls_1() {
kubectl -n test apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: ingress-sidecar
  namespace: test
spec:
  workloadSelector:
    labels:
      app: httpbin
      version: v1
  ingress:
  - port:
      number: 9080
      protocol: HTTPS
      name: external
    defaultEndpoint: 0.0.0.0:80
    tls:
      mode: MUTUAL
      privateKey: "/etc/istio/tls-certs/tls.key"
      serverCertificate: "/etc/istio/tls-certs/tls.crt"
      caCertificates: "/etc/istio/tls-ca-certs/ca.crt"
  - port:
      number: 9081
      protocol: HTTP
      name: internal
    defaultEndpoint: 0.0.0.0:80
EOF
}

snip_verification_1() {
kubectl apply -f samples/sleep/sleep.yaml
kubectl -n test apply -f samples/sleep/sleep.yaml
}

snip_verification_2() {
kubectl get pods
}

! read -r -d '' snip_verification_2_out <<\ENDSNIP
NAME                     READY   STATUS    RESTARTS   AGE
sleep-557747455f-xx88g   1/1     Running   0          4m14s
ENDSNIP

snip_verification_3() {
kubectl get pods -n test
}

! read -r -d '' snip_verification_3_out <<\ENDSNIP
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
sleep-557747455f-brzf6     2/2     Running   0          6m57s
ENDSNIP

snip_verification_4() {
kubectl get svc -n test
}

! read -r -d '' snip_verification_4_out <<\ENDSNIP
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
sleep     ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
ENDSNIP

snip_verification_5() {
istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
}

! read -r -d '' snip_verification_5_out <<\ENDSNIP
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
ENDSNIP

snip_verify_internal_mesh_connectivity_on_port_8080_1() {
export INTERNAL_CLIENT=$(kubectl -n test get pod -l app=sleep -o jsonpath={.items..metadata.name})
kubectl -n test exec "${INTERNAL_CLIENT}" -c sleep -- curl -IsS "http://httpbin:8080/status/200"
}

! read -r -d '' snip_verify_internal_mesh_connectivity_on_port_8080_1_out <<\ENDSNIP
HTTP/1.1 200 OK
server: envoy
date: Mon, 24 Oct 2022 09:04:52 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 5
ENDSNIP

snip_verify_external_to_internal_mesh_connectivity_on_port_8443_1() {
export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
}

snip_verify_external_to_internal_mesh_connectivity_on_port_8443_2() {
kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
}

! read -r -d '' snip_verify_external_to_internal_mesh_connectivity_on_port_8443_2_out <<\ENDSNIP
server: istio-envoy
date: Mon, 24 Oct 2022 09:05:31 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 4
x-envoy-decorator-operation: ingress-sidecar.test:9080/*
ENDSNIP

snip_verify_external_to_internal_mesh_connectivity_on_port_8443_3() {
kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
}

! read -r -d '' snip_verify_external_to_internal_mesh_connectivity_on_port_8443_3_out <<\ENDSNIP
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
ENDSNIP

snip_cleanup_the_mutual_tls_termination_example_1() {
kubectl delete secret httpbin-mtls-termination httpbin-mtls-termination-cacert -n test
kubectl delete service httpbin sleep -n test
kubectl delete deployment httpbin sleep -n test
kubectl delete namespace test
kubectl delete service sleep
kubectl delete deployment sleep
}

snip_cleanup_the_mutual_tls_termination_example_2() {
rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr \
    client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
}

snip_cleanup_the_mutual_tls_termination_example_3() {
istioctl uninstall --purge -y
}
