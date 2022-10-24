---
title: Ingress Sidecar TLS Termination
description: Describes how to terminate TLS traffic at a sidecar without using an Ingress Gateway.
weight: 30
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

In a regular Istio mesh deployment, the TLS termination for downstream requests is performed at the Ingress Gateway.
Though this satisfies most of the use cases, for some use cases (like an API Gateway on the mesh) the Ingress Gateway resource is not necessarily needed. This example describes how to eliminate the additional hop introduced by the Istio Ingress Gateway and let the Envoy sidecar running alongside the application perform TLS termination for incoming requests from outside the Istio service mesh.

The example HTTPS service used for this task is a simple [httpbin](https://httpbin.org) service.
In the following steps you first deploy an httpbin service inside your Istio service mesh with required configuration
to perform TLS termination for downstream requests coming from outside the service mesh.

{{< boilerplate experimental-feature-warning >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/), enabling the experimental
    feature `ENABLE_TLS_ON_SIDECAR_INGRESS`.

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
    {{< /text >}}

*   Create the test namespace where the target `httpbin` service will be deployed. Make sure to enable sidecar injection
    for the namespace.

    {{< text bash >}}
    $ kubectl create ns test
    $ kubectl label namespace test istio-injection=enabled
    {{< /text >}}

## Enable global mTLS

Peer Authentication Policy to allow mTLS traffic for all workloads has to be enabled.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

## Disable PeerAuthentication for external mTLS Port

The external mTLS Port that will be used at the sidecar for TLS Termination has to disable `PeerAuthentication`.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
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
{{< /text >}}

## Generate CA cert, Server cert/key and Client cert/key

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1):

{{< text bash >}}
$ #CA is example.com
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
$ #Server is httpbin.test.svc.cluster.local
$ openssl req -out httpbin.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout httpbin.test.svc.cluster.local.key -subj "/CN=httpbin.test.svc.cluster.local/O=httpbin organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in httpbin.test.svc.cluster.local.csr -out httpbin.test.svc.cluster.local.crt
$ #client is client.test.svc.cluster.local
$ openssl req -out client.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout client.test.svc.cluster.local.key -subj "/CN=client.test.svc.cluster.local/O=client organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.test.svc.cluster.local.csr -out client.test.svc.cluster.local.crt
{{< /text >}}

## Generate k8s secret for the certificates and keys

{{< text bash >}}
$ kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
$ kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
{{< /text >}}

## Create httpbin deployment and services

When the httpbin deployment is to be created, we need to use `userVolumeMount` annotations in the deployment to make sure the certificates are mounted to the istio-proxy sidecar.
Note: This step is needed until Istio supports `credentialName` for sidecar configuration.

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

The complete deployment yaml using `userVolumeMount` and service configuration for `httpbin` can be found below:

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
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
{{< /text >}}

## Create sidecar configuration for httpbin to enable external mTLS on ingress

This is the core step in this feature, where `sidecar` API is used to configure the ingress TLS settings.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
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
{{< /text >}}

## Verification

On top of the above server configuration, bring up two clients as mentioned below for performing end to end connectivity tests:
1. One client (sleep) in the same namespace (test) with sidecar injected
1. One client (sleep) in default namespace as an external client (outside service mesh)

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl -n test apply -f samples/sleep/sleep.yaml
{{< /text >}}

{{< text bash >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-557747455f-xx88g   1/1     Running   0          4m14s
$
$ kubectl get pods -n test
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
sleep-557747455f-brzf6     2/2     Running   0          6m57s
$
$ kubectl get svc -n test
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
sleep     ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
$
$ istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
$
{{< /text >}}

Once all the resources are created, and above verification steps are completed, go ahead and execute the different connectivity tests as below.

### Verify internal mesh connectivity on port 8080

{{< text bash >}}
$ export INTERNAL_CLIENT=$(kubectl -n test get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl -n test exec "${INTERNAL_CLIENT}" -c sleep -- curl -IsS "http://httpbin:8080/status/200"
HTTP/1.1 200 OK
server: envoy
date: Mon, 24 Oct 2022 09:04:52 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 5
{{< /text >}}

### Verify external to internal mesh connectivity on port 8443

To verify mTLS traffic from external client, first copy the CA certificate and client certificate/key to the sleep client in default namespace which is outside the mesh.

{{< text bash >}}
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

Once the certificates are available for the sleep client, you can verify the connectivity from this external sleep client to the internal httpbin service using the command below.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
server: istio-envoy
date: Mon, 24 Oct 2022 09:05:31 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 4
x-envoy-decorator-operation: ingress-sidecar.test:9080/*
{{< /text >}}

Apart from verifying the mTLS connectivity over external port 8443, it is also important to verify that port 8080 does not accept any external mTLS traffic.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
{{< /text >}}

## Cleanup the mutual TLS termination example

1.  Remove created Kubernetes resources:

{{< text bash >}}
$ kubectl delete secret httpbin-mtls-termination httpbin-mtls-termination-cacert -n test
$ kubectl delete service httpbin sleep -n test
$ kubectl delete deployment httpbin sleep -n test
$ kubectl delete namespace test
$ kubectl delete service sleep
$ kubectl delete deployment sleep
{{< /text >}}

1.  Delete the certificates and private keys:

{{< text bash >}}
$ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
{{< /text >}}

1.  Uninstall Istio from your cluster:

{{< text bash >}}
$ istioctl uninstall --purge -y
{{< /text >}}
