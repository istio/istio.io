---
title: Secure Gateways
description: Expose a service outside of the service mesh over TLS or mTLS.
weight: 20
aliases:
    - /docs/tasks/traffic-management/ingress/secure-ingress-sds/
    - /docs/tasks/traffic-management/ingress/secure-ingress-mount/
keywords: [traffic-management,ingress,sds-credentials]
owner: istio/wg-networking-maintainers
test: yes
---

The [Control Ingress Traffic task](/docs/tasks/traffic-management/ingress/ingress-control)
describes how to configure an ingress gateway to expose an HTTP service to external traffic.
This task shows how to expose a secure HTTPS service using either simple or mutual TLS.

{{< boilerplate gateway-api-support >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Start the [httpbin]({{< github_tree >}}/samples/httpbin) sample:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

*   For macOS users, verify that you use `curl` compiled with the [LibreSSL](http://www.libressl.org) library:

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    If the previous command outputs a version of LibreSSL as shown, your `curl` command
    should work correctly with the instructions in this task. Otherwise, try
    a different implementation of `curl`, for example on a Linux machine.

## Generate client and server certificates and keys

This task requires several sets of certificates and keys which are used in the following examples.
You can use your favorite tool to create them or use the commands below to generate them using
[openssl](https://man.openbsd.org/openssl.1).

1.  Create a root certificate and private key to sign the certificates for your services:

    {{< text bash >}}
    $ mkdir example_certs1
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs1/example.com.key -out example_certs1/example.com.crt
    {{< /text >}}

1.  Generate a certificate and a private key for `httpbin.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 0 -in example_certs1/httpbin.example.com.csr -out example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Create a second set of the same kind of certificates and keys:

    {{< text bash >}}
    $ mkdir example_certs2
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs2/example.com.key -out example_certs2/example.com.crt
    $ openssl req -out example_certs2/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs2/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs2/example.com.crt -CAkey example_certs2/example.com.key -set_serial 0 -in example_certs2/httpbin.example.com.csr -out example_certs2/httpbin.example.com.crt
    {{< /text >}}

1.  Generate a certificate and a private key for `helloworld.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/helloworld.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/helloworld.example.com.key -subj "/CN=helloworld.example.com/O=helloworld organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/helloworld.example.com.csr -out example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  Generate a client certificate and private key:

    {{< text bash >}}
    $ openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
    {{< /text >}}

{{< tip >}}
You can confirm that you have all of the needed files by running the following command:

{{< text bash >}}
$ ls example_cert*
example_certs1:
client.example.com.crt          example.com.key                 httpbin.example.com.crt
client.example.com.csr          helloworld.example.com.crt      httpbin.example.com.csr
client.example.com.key          helloworld.example.com.csr      httpbin.example.com.key
example.com.crt                 helloworld.example.com.key

example_certs2:
example.com.crt         httpbin.example.com.crt httpbin.example.com.key
example.com.key         httpbin.example.com.csr
{{< /text >}}

{{< /tip >}}

### Configure a TLS ingress gateway for a single host

1.  Create a secret for the ingress gateway:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Configure the ingress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio classic" category-value="istio-classic" >}}

First, define a gateway with a `servers:` section for port 443, and specify values for
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

Next, configure the gateway's ingress traffic routes by defining a corresponding
virtual service:

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

Finally, follow [these instructions](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
to set the `INGRESS_HOST` and `SECURE_INGRESS_PORT` variables for accessing the gateway.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

First, create a [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway):

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Next, configure the gateway's ingress traffic routes by defining a corresponding `HTTPRoute`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Finally, get the gateway address and port from the `Gateway` resource:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway -n istio-system
$ export INGRESS_HOST=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Send an HTTPS request to access the `httpbin` service through HTTPS:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

    The `httpbin` service will return the [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

1)  Change the gateway's credentials by deleting the gateway's secret and then recreating it using
    different certificates and keys:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs2/httpbin.example.com.key \
      --cert=example_certs2/httpbin.example.com.crt
    {{< /text >}}

1)  Access the `httpbin` service with `curl` using the new certificate chain:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs2/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

1) If you try to access `httpbin` using the previous certificate chain, the attempt now fails:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### Configure a TLS ingress gateway for multiple hosts

You can configure an ingress gateway for multiple hosts,
`httpbin.example.com` and `helloworld.example.com`, for example. The ingress gateway
is configured with unique credentials corresponding to each host.

1.  Restore the `httpbin` credentials from the previous example by deleting and recreating the secret
    with the original certificates and keys:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Start the `helloworld-v1` sample:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1
    {{< /text >}}

1.  Create a `helloworld-credential` secret:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls helloworld-credential \
      --key=example_certs1/helloworld.example.com.key \
      --cert=example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  Configure the ingress gateway with hosts `httpbin.example.com` and `helloworld.example.com`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio classic" category-value="istio-classic" >}}

Define a gateway with two server sections for port 443. Set the value of
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
    - helloworld.example.com
EOF
{{< /text >}}

Configure the gateway's traffic routes by defining a corresponding virtual service.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.example.com
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Configure a `Gateway` with two listeners for port 443. Set the value of
`certificateRefs` on each listener to `httpbin-credential` and `helloworld-credential`
respectively.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https-httpbin
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
  - name: https-helloworld
    hostname: "helloworld.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: helloworld-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Configure the gateway's traffic routes for the `helloworld` service:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["helloworld.example.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) Send an HTTPS request to `helloworld.example.com`:

    {{< text bash >}}
    $ curl -v -HHost:helloworld.example.com --resolve "helloworld.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://helloworld.example.com:$SECURE_INGRESS_PORT/hello"
    ...
    HTTP/2 200
    ...
    {{< /text >}}

1) Send an HTTPS request to `httpbin.example.com` and still get a teapot in return:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

### Configure a mutual TLS ingress gateway

You can extend your gateway's definition to support [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication).

1. Change the credentials of the ingress gateway by deleting its secret and creating a new one.
   The server uses the CA certificate to verify its clients, and we must use the key `ca.crt` to hold the CA certificate.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential \
      --from-file=tls.key=example_certs1/httpbin.example.com.key \
      --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
      --from-file=ca.crt=example_certs1/example.com.crt
    {{< /text >}}

    {{< tip >}}
    {{< boilerplate crl-tip >}}

    The credential may also include an [OCSP Staple](https://datatracker.ietf.org/doc/html/rfc6961) using the key `tls.ocsp-staple` which can be specified by an additional argument: `--from-file=tls.ocsp-staple=/some/path/to/your-ocsp-staple.pem`.
    {{< /tip >}}

1. Configure the ingress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio classic" category-value="istio-classic" >}}

Change the gateway's definition to set the TLS mode to `MUTUAL`.

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Because the Kubernetes Gateway API does not currently support mutual TLS termination in a
[Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1beta1.Gateway),
we use an Istio-specific option, `gateway.istio.io/tls-terminate-mode: MUTUAL`,
to configure it:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
      options:
        gateway.istio.io/tls-terminate-mode: MUTUAL
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Attempt to send an HTTPS request using the prior approach and see how it fails:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

1) Pass a client certificate and private key to `curl` and resend the request.
   Pass your client's certificate with the `--cert` flag and your private key
   with the `--key` flag to `curl`:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
      "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
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

## More info

### Key formats

Istio supports reading a few different Secret formats, to support integration with various tools such as [cert-manager](/docs/ops/integrations/certmanager/):

* A TLS Secret with keys `tls.key` and `tls.crt`, as described above. For mutual TLS, a `ca.crt` key can be used.
* A generic Secret with keys `key` and `cert`. For mutual TLS, a `cacert` key can be used.
* A generic Secret with keys `key` and `cert`. For mutual TLS, a separate generic Secret named `<secret>-cacert`, with a `cacert` key. For example, `httpbin-credential` has `key` and `cert`, and `httpbin-credential-cacert` has `cacert`.
* The `cacert` key value can be a CA bundle consisting of concatenated individual CA certificates.

### SNI Routing

An HTTPS `Gateway` will perform [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) matching against its configured host(s)
before forwarding a request, which may cause some requests to fail.
See [configuring SNI routing](/docs/ops/common-problems/network-issues/#configuring-sni-routing-when-not-sending-sni) for details.

## Troubleshooting

*   Inspect the values of the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment
    variables. Make sure they have valid values, according to the output of the
    following commands:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
    {{< /text >}}

*   Make sure the value of `INGRESS_HOST` is an IP address. In some cloud platforms, e.g., AWS, you may
     get a domain name, instead. This task expects an IP address, so you will need to convert it with commands
     similar to the following:

    {{< text bash >}}
    $ nslookup ab52747ba608744d8afd530ffd975cbf-330887905.us-east-1.elb.amazonaws.com
    $ export INGRESS_HOST=3.225.207.109
    {{< /text >}}

*   Check the log of the gateway controller for error messages:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
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
    key/certificate pair to the ingress gateway:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
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

1.  Delete the gateway configuration and routes:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio classic" category-value="istio-classic" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system gtw mygateway
$ kubectl delete httproute httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Delete the secrets, certificates and keys:

    {{< text bash >}}
    $ kubectl delete -n istio-system secret httpbin-credential helloworld-credential
    $ rm -rf ./example_certs1 ./example_certs2
    {{< /text >}}

1)  Shutdown the `httpbin` and `helloworld` services:

    {{< text bash >}}
    $ kubectl delete -f samples/httpbin/httpbin.yaml
    $ kubectl delete deployment helloworld-v1
    $ kubectl delete service helloworld
    {{< /text >}}
