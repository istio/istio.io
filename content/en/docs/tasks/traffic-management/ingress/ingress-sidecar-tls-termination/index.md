---
title: Ingress Sidecar TLS Termination
description: Describes how to terminate TLS traffic at a sidecar without using an Ingress Gateway.
weight: 30
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

In a regular Istio mesh deployment, the TLS termination for downstream requests is performed at the Ingress Gateway.
Although this satisfies most use cases, for some (like an API Gateway in the mesh) the Ingress Gateway is not necessarily needed. This task shows how to eliminate the additional hop introduced by the Istio Ingress Gateway and let the Envoy sidecar, running alongside the application, perform TLS termination for requests coming from outside of the service mesh.

The example HTTPS service used for this task is a simple [httpbin](https://httpbin.org) service.
In the following steps you will deploy the httpbin service inside your service mesh and configure it.

{{< boilerplate experimental-feature-warning >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/), enabling the experimental
    feature `ENABLE_TLS_ON_SIDECAR_INGRESS`.

    {{< text bash >}}
    $ istioctl install --set profile=default --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
    {{< /text >}}

*   Create the test namespace where the target `httpbin` service will be deployed. Make sure to enable sidecar injection
    for the namespace.

    {{< text bash >}}
    $ kubectl create ns test
    $ kubectl label namespace test istio-injection=enabled
    {{< /text >}}

## Enable global mTLS

Apply the following `PeerAuthentication` policy to require mTLS traffic for all workloads in the mesh.

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

## Disable PeerAuthentication for the externally exposed httpbin port

Disable `PeerAuthentication` for the port of the httpbin service which will perform ingress TLS termination at the sidecar. Note that this is the `targetPort` of the httpbin service which should be used exclusively for external communication.

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

## Create k8s secrets for the certificates and keys

{{< text bash >}}
$ kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
$ kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
{{< /text >}}

## Deploy the httpbin test service

When the httpbin deployment is created, we need to use `userVolumeMount` annotations in the deployment to mount the certificates for the istio-proxy sidecar.
Note that this step is only needed because Istio does not currently support `credentialName` in a sidecar configuration.

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

Use the following command to deploy the `httpbin` service with the required `userVolumeMount` configuration:

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

## Configure httpbin to enable external mTLS

This is the core step for this feature. Using the `Sidecar` API, configure the ingress TLS settings.
The TLS mode can be `SIMPLE` or `MUTUAL`. This example uses `MUTUAL`.

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

Now that the httpbin server is deployed and configured, bring up two clients to  test the end to end connectivity from both inside and outside of the mesh:
1. An internal client (sleep) in the same namespace (test) as the httpbin service, with sidecar injected.
1. An external client (sleep) in the default namespace (i.e., outside of the service mesh).

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl -n test apply -f samples/sleep/sleep.yaml
{{< /text >}}

Run the following commands to verify that everything is up and running, and configured correctly.

{{< text bash >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-557747455f-xx88g   1/1     Running   0          4m14s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n test
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
sleep-557747455f-brzf6     2/2     Running   0          6m57s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n test
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
sleep     ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
{{< /text >}}

In the following command, replace `httpbin-5bbdbd6588-z9vbs` with the name of your httpbin pod.

{{< text bash >}}
$ istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
{{< /text >}}

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

To verify mTLS traffic from an external client, first copy the CA certificate and client certificate/key to the sleep client running in the default namespace.

{{< text bash >}}
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

Now that the certificates are available for the external sleep client, you can verify connectivity from it to the internal httpbin service using the following command.

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

In addition to verifying external mTLS connectivity via the ingress port 8443, it is also important to verify that port 8080 does not accept any external mTLS traffic.

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
    $ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr \
        client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
    {{< /text >}}

1.  Uninstall Istio from your cluster:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
