---
title: Ingress Sidecar TLS Termination
description: Describes how to terminate TLS traffic at a sidecar without using an Ingress Gateway.
weight: 30
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

In a regular Istio mesh deployment, the TLS termination for downstream requests is performed at the Ingress Gateway. Though this satisfies most of the use cases, for some use cases (like an API Gateway on the mesh) the Ingress Gateway resource is not necessarily needed. This example describes how to eliminate the additional hop introduced by the Istio Ingress Gateway and let the Envoy sidecar running alongside the application perform TLS termination for requests ingressing from outside the Istio service mesh.  

The example HTTPS service used for this task is a simple [httpbin](https://httpbin.org) service.
In the following steps you first deploy an httpbin service inside your Istio service mesh with required configuration
to perform TLS termination for downstream requests coming from outside the service mesh.

{{< boilerplate experimental-feature-warning >}}

## Before you begin
*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/), enabling the experimental
    feature `ENABLE_TLS_ON_SIDECAR_INGRESS`.
    {{< text bash >}}
    $ kubectl -n istio-system set env deployment istiod ENABLE_TLS_ON_SIDECAR_INGRESS=true
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
When the httpbin deployment is to be created, we need to use userVolumeMount annotations in the deployment to make sure the certificates are mounted to the istio-proxy sidecar.
Note: This step is needed until istio supports credentialName for sidecar configuration.

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

The complete deployment yaml using userVolumeMount and service configuration for httpbin can be found below:

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
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl -n test exec "${EXTERNAL_CLIENT}" -c sleep -- curl -v "http://httpbin:8080/status/200"
* Connected to httpbin (10.96.159.202) port 8080 (#0)
> GET /status/200 HTTP/1.1
> Host: httpbin:8080
> User-Agent: curl/7.85.0-DEV
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< server: envoy
< date: Fri, 21 Oct 2022 12:21:20 GMT
< content-type: text/html; charset=utf-8
< access-control-allow-origin: *
< access-control-allow-credentials: true
< content-length: 0
< x-envoy-upstream-service-time: 3
{{< /text >}}

### Verify external to internal mesh connectivity on port 8443
Inorder to verify mTLS traffic from external client, firt copy the CA certificate and client certificate/key to the sleep client in default namespace which is outside the mesh.
{{< text bash >}}
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

Once the certificates are available for the sleep client, you can verify the connectivity from this external sleep client to the internal httpbin service using the command below. The logs will help you understand and properly verify the TLS handshake in detail.
{{< text bash >}}
$ kubectl exec $EXTERNAL_CLIENT -c sleep -- curl --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -v -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
*   Trying 10.100.78.113:8443...
* Connected to httpbin.test.svc.cluster.local (10.100.78.113) port 8443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /tmp/ca.crt
*  CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, CERT verify (15):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=httpbin.test.svc.cluster.local; O=httpbin organization
*  start date: Feb 14 09:51:56 2022 GMT
*  expire date: Feb 14 09:51:56 2023 GMT
*  common name: httpbin.test.svc.cluster.local (matched)
*  issuer: O=example Inc.; CN=example.com
*  SSL certificate verify ok.
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f9e4729cac0)
> GET /status/200 HTTP/2
> Host:httpbin.test.svc.cluster.local
> user-agent: curl/7.81.0-DEV
> accept: */*
>
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
< HTTP/2 200
< server: istio-envoy
< date: Mon, 14 Feb 2022 10:03:08 GMT
< content-type: text/html; charset=utf-8
< access-control-allow-origin: *
< access-control-allow-credentials: true
< content-length: 0
< x-envoy-upstream-service-time: 1
< x-envoy-decorator-operation: httpbin.test.svc.cluster.local:9080/*
<
* Connection #0 to host httpbin.test.svc.cluster.local left intact
{{< /text >}}

Apart from verifying the mTLS connectivity over external port 8443, it is also important to verify that port 8080 does not accept any external mTLS traffic.

{{< text bash >}}
$ kubectl exec $EXTERNAL_CLIENT -c sleep -- curl --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -v -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
*   Trying 10.100.78.113:8080...
* Connected to httpbin.test.svc.cluster.local (10.100.78.113) port 8080 (#0)
> GET /status/200 HTTP/1.1
> Host:httpbin.test.svc.cluster.local
> User-Agent: curl/7.81.0-DEV
> Accept: */*
>
* Recv failure: Connection reset by peer
* Closing connection 0
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
$ # disable the feature flag
$ kubectl -n istio-system set env deployment istiod ENABLE_TLS_ON_SIDECAR_INGRESS=false
{{< /text >}}

1.  Delete the certificates and private keys:

{{< text bash >}}
$ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
{{< /text >}}
