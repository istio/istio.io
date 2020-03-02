---
title: Secure Gateways (SDS)
description: Expose a service outside of the service mesh over TLS or mTLS using the secret discovery service (SDS).
weight: 21
aliases:
    - /docs/tasks/traffic-management/ingress/secure-ingress-sds/
keywords: [traffic-management,ingress,sds-credentials]
---

The [Control Ingress Traffic task](/docs/tasks/traffic-management/ingress)
describes how to configure an ingress gateway to expose an HTTP
service to external traffic. This task shows how to expose a secure HTTPS
service using either simple or mutual TLS.

The TLS required private key, server certificate, and root certificate, are configured
using the Secret Discovery Service (SDS).

## Before you begin

1.  Perform the steps in the [Before you begin](/docs/tasks/traffic-management/ingress/ingress-control#before-you-begin)
and [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
sections of the [Control Ingress Traffic](/docs/tasks/traffic-management/ingress/ingress-control) task. After performing
those steps you should have Istio and the [httpbin]({{< github_tree >}}/samples/httpbin) service deployed,
and the environment variables `INGRESS_HOST` and `SECURE_INGRESS_PORT` set.

1.  For macOS users, verify that you use `curl` compiled with the [LibreSSL](http://www.libressl.org) library:

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    If the previous command outputs a version of LibreSSL  as shown, your `curl` command
    should work correctly with the instructions in this task. Otherwise, try
    a different implementation of `curl`, for example on a Linux machine.

{{< tip >}}
If you configured an ingress gateway using the [file mount-based approach](/docs/tasks/traffic-management/ingress/secure-ingress-mount),
and you want to migrate your ingress gateway to use the SDS approach, there are no
extra steps required.
{{< /tip >}}

## Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. The commands below use
[openssl](https://man.openbsd.org/openssl.1)

1.  Create a root certificate and private key to sign the certificates for your services:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Create a certificate and a private key for `httpbin.example.com`:

    {{< text bash >}}
    $ openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
    {{< /text >}}

## Configure a TLS ingress gateway using SDS

You can configure a TLS ingress gateway to fetch credentials
 from the ingress gateway agent via secret discovery service (SDS). The ingress
 gateway agent runs in the same pod as the ingress gateway and watches the
 credentials created in the same namespace as the ingress gateway. Enabling SDS
 at ingress gateway brings the following benefits.

* The ingress gateway can dynamically add, delete, or update its
key/certificate pairs and its root certificate. You do not have to restart the ingress
gateway.

* No secret volume mount is needed. Once you create a `kubernetes`
secret, that secret is captured by the gateway agent and sent to ingress gateway
 as key/certificate or root certificate.

* The gateway agent can watch multiple key/certificate pairs. You only
need to create secrets for multiple hosts and update the gateway definitions.

1.  Enable SDS at ingress gateway and deploy the ingress gateway agent.
    Since this feature is disabled by default, you need to enable the
    `istio-ingressgateway.sds.enabled` installation option and generate the `istio-ingressgateway.yaml` file:

    {{< text bash >}}
    $ istioctl manifest generate \
    --set values.gateways.istio-egressgateway.enabled=false \
    --set values.gateways.istio-ingressgateway.sds.enabled=true > \
    $HOME/istio-ingressgateway.yaml
    $ kubectl apply -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1.  Set the environment variables `INGRESS_HOST` and `SECURE_INGRESS_PORT`:

    {{< text bash >}}
    $ export SECURE_INGRESS_PORT=$(kubectl -n istio-system \
    get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    $ export INGRESS_HOST=$(kubectl -n istio-system \
    get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    {{< /text >}}

### Configure a TLS ingress gateway for a single host

1.  Start the `httpbin` sample:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: httpbin
      labels:
        app: httpbin
    spec:
      ports:
      - name: http
        port: 8000
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
        spec:
          containers:
          - image: docker.io/citizenstig/httpbin
            imagePullPolicy: IfNotPresent
            name: httpbin
            ports:
            - containerPort: 8000
    EOF
    {{< /text >}}

1.  Create a secret for the ingress gateway:

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic httpbin-credential --from-file=key=httpbin.example.com.key \
    --from-file=cert=httpbin.example.com.crt
    {{< /text >}}

    {{< warning >}}
    The secret name **should not** begin with `istio` or `prometheus`, and
    the secret **should not** contain a `token` field.
    {{< /warning >}}

1.  Define a gateway with a `servers:` section for port 443, and specify values for
    `credentialName` to be `httpbin-credential`. The values are the same as the
    secret's name. The TLS mode should have the value of `SIMPLE`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: httpbin-credential # must be the same as secret
        hosts:
        - httpbin.example.com
    EOF
    {{< /text >}}

1.  Configure the gateway's ingress traffic routes. Define the corresponding
    virtual service.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "httpbin.example.com"
      gateways:
      - mygateway
      http:
      - match:
        - uri:
            prefix: /status
        - uri:
            prefix: /delay
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

1.  Send an HTTPS request to access the `httpbin` service through HTTPS:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    {{< /text >}}

    The `httpbin` service will return the
    [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

1.  Delete the gateway's secret and create a new one to change the ingress
    gateway's credentials.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    {{< /text >}}

    {{< text bash >}}
    $ mkdir new_certificates
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout new_certificates/example.com.key -out new_certificates/example.com.crt
    $ openssl req -out new_certificates/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout new_certificates/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -days 365 -CA new_certificates/example.com.crt -CAkey new_certificates/example.com.key -set_serial 0 -in new_certificates/httpbin.example.com.csr -out new_certificates/httpbin.example.com.crt
    $ kubectl create -n istio-system secret generic httpbin-credential \
    --from-file=key=new_certificates/httpbin.example.com.key \
    --from-file=cert=new_certificates/httpbin.example.com.crt
    {{< /text >}}

1.  Access the `httpbin` service using `curl` using the new certificate chain:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert new_certificates/example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    HTTP/2 418
    ...
    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1. If you try to access `httpbin` with the previous certificate chain, the attempt now fails.

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### Configure a TLS ingress gateway for multiple hosts

You can configure an ingress gateway for multiple hosts,
`httpbin.example.com` and `helloworld-v1.example.com`, for example. The ingress gateway
retrieves unique credentials corresponding to a specific `credentialName`.

1.  To restore the credentials for `httpbin`, delete its secret and create it again.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential \
    --from-file=key=httpbin.example.com.key \
    --from-file=cert=httpbin.example.com.crt
    {{< /text >}}

1.  Start the `helloworld-v1` sample

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: helloworld-v1
      labels:
        app: helloworld-v1
    spec:
      ports:
      - name: http
        port: 5000
      selector:
        app: helloworld-v1
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: helloworld-v1
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: helloworld-v1
          version: v1
      template:
        metadata:
          labels:
            app: helloworld-v1
            version: v1
        spec:
          containers:
          - name: helloworld
            image: istio/examples-helloworld-v1
            resources:
              requests:
                cpu: "100m"
            imagePullPolicy: IfNotPresent #Always
            ports:
            - containerPort: 5000
    EOF
    {{< /text >}}

1.  Generate a certificate and a private key for `helloworld-v1.example.com`:

    {{< text bash >}}
    $ openssl req -out helloworld-v1.example.com.csr -newkey rsa:2048 -nodes -keyout helloworld-v1.example.com.key -subj "/CN=helloworld-v1.example.com/O=helloworld organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in helloworld-v1.example.com.csr -out helloworld-v1.example.com.crt
    {{< /text >}}

1.  Create the `helloworld-credential` secret:

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic helloworld-credential --from-file=key=helloworld-v1.example.com.key \
    --from-file=cert=helloworld-v1.example.com.crt
    {{< /text >}}

1.  Define a gateway with two server sections for port 443. Set the value of
    `credentialName` on each port to `httpbin-credential` and `helloworld-credential`
    respectively. Set TLS mode to `SIMPLE`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: mygateway
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 443
          name: https-httpbin
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: httpbin-credential
        hosts:
        - httpbin.example.com
      - port:
          number: 443
          name: https-helloworld
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: helloworld-credential
        hosts:
        - helloworld-v1.example.com
    EOF
    {{< /text >}}

1.  Configure the gateway's traffic routes. Define the corresponding
    virtual service.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: helloworld-v1
    spec:
      hosts:
      - helloworld-v1.example.com
      gateways:
      - mygateway
      http:
      - match:
        - uri:
            exact: /hello
        route:
        - destination:
            host: helloworld-v1
            port:
              number: 5000
    EOF
    {{< /text >}}

1. Send an HTTPS request to `helloworld-v1.example.com`:

    {{< text bash >}}
    $ curl -v -HHost:helloworld-v1.example.com --resolve helloworld-v1.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt https://helloworld-v1.example.com:$SECURE_INGRESS_PORT/hello
    HTTP/2 200
    {{< /text >}}

1. Send an HTTPS request to `httpbin.example.com` and still get a teapot in return:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/
            `"""`
    {{< /text >}}

### Configure a mutual TLS ingress gateway

You can extend your gateway's definition to support
[mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication). Change
the credentials of the ingress gateway by deleting its secret and creating a new one.
The server uses the CA certificate to verify
its clients, and we must use the name `cacert` to hold the CA certificate.

{{< text bash >}}
$ kubectl -n istio-system delete secret httpbin-credential
$ kubectl create -n istio-system secret generic httpbin-credential --from-file=key=httpbin.example.com.key \
--from-file=cert=httpbin.example.com.crt --from-file=cacert=example.com.crt
{{< /text >}}

1. Change the gateway's definition to set the TLS mode to `MUTUAL`.

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
     name: mygateway
    spec:
     selector:
       istio: ingressgateway # use istio default ingress gateway
     servers:
     - port:
         number: 443
         name: https
         protocol: HTTPS
       tls:
         mode: MUTUAL
         credentialName: httpbin-credential # must be the same as secret
       hosts:
       - httpbin.example.com
    EOF
    {{< /text >}}

1. Attempt to send an HTTPS request using the prior approach and see how it fails:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * TLSv1.3 (IN), TLS alert, unknown (628):
    * OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
    {{< /text >}}

1.  Generate client certificate and private key:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

1. Pass a client certificate and private key to `curl` and resend the request.
   Pass your client's certificate with the `--cert` flag and your private key
   with the `--key` flag to `curl`.

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST \
    --cacert example.com.crt --cert client.example.com.crt --key client.example.com.key \
    https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

        -=[ teapot ]=-

           _...._
         .'  _ _ `.
        | ."` ^ `". _,
        \_;`"---"`|//
          |       ;/
          \_     _/

    {{< /text >}}

1. Instead of creating a `httpbin-credential` secret to hold all the credentials, you can
   create two separate secrets:

    * `httpbin-credential` holds the server's key and certificate
    * `httpbin-credential-cacert` holds the client's CA certificate and must have the `-cacert` suffix

    Create the two separate secrets with the following commands:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential  \
    --from-file=key=httpbin.example.com.key --from-file=cert=httpbin.example.com.crt
    $ kubectl create -n istio-system secret generic httpbin-credential-cacert  \
    --from-file=cacert=example.com.crt
    {{< /text >}}

## Troubleshooting

*   Inspect the values of the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment
    variables. Make sure they have valid values, according to the output of the
    following commands:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

*   Check the log of the `istio-ingressgateway` controller for error messages:

    {{< text bash >}}
    $ kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}')
    {{< /text >}}

*   If using macOS, verify you are using `curl` compiled with the [LibreSSL](http://www.libressl.org)
    library, as described in the [Before you begin](#before-you-begin) section.

*   Verify that the secrets are successfully created in the `istio-system`
    namespace:

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    `httpbin-credential` and `helloworld-credential` should show in the secrets
    list.

*   Check the logs to verify that the ingress gateway agent has pushed the
    key/certificate pair to the ingress gateway.

    {{< text bash >}}
    $ kubectl logs -n istio-system $(kubectl get pod -l istio=ingressgateway \
    -n istio-system -o jsonpath='{.items[0].metadata.name}')
    {{< /text >}}

    The log should show that the `httpbin-credential` secret was added. If using mutual
    TLS, then the `httpbin-credential-cacert` secret should also appear.
    Verify the log shows that the gateway agent receives SDS requests from the
    ingress gateway, that the resource's name is `httpbin-credential`, and that the ingress gateway
    obtained the key/certificate pair. If using mutual TLS, the log should show
    key/certificate was sent to the ingress gateway,
    that the gateway agent received the SDS request with the `httpbin-credential-cacert`
    resource name,   and that the ingress gateway obtained the root certificate.

## Cleanup

1.  Delete the gateway configuration, the virtual service definition, and the secrets:

    {{< text bash >}}
    $ kubectl delete gateway mygateway
    $ kubectl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret httpbin-credential \
    helloworld-credential
    $ kubectl delete --ignore-not-found=true virtualservice helloworld-v1
    {{< /text >}}

1.  Delete the certificates and keys:

    {{< text bash >}}
    $ rm -rf example.com.crt example.com.key httpbin.example.com.crt httpbin.example.com.key httpbin.example.com.csr helloworld-v1.example.com.crt helloworld-v1.example.com.key helloworld-v1.example.com.csr client.example.com.crt client.example.com.csr client.example.com.key ./new_certificates
    {{< /text >}}

1.  Remove the file you used for redeployment of the ingress gateway.

    {{< text bash >}}
    $ rm -f $HOME/istio-ingressgateway.yaml
    {{< /text >}}

1. Shutdown the `httpbin` and `helloworld-v1` services:

    {{< text bash >}}
    $ kubectl delete deployment --ignore-not-found=true httpbin helloworld-v1
    $ kubectl delete service --ignore-not-found=true httpbin helloworld-v1
    {{< /text >}}
