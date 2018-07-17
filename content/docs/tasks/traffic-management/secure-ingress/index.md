---
title: Securing Gateways with HTTPS
description: Describes how to configure Istio to expose a service outside of the service mesh, over TLS or Mutual TLS.
weight: 31
keywords: [traffic-management,ingress]
---

> Note: This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

The [Control Ingress Traffic](/docs/tasks/traffic-management/ingress) task describes how to configure an ingress
gateway to expose an HTTP endpoint of a service to external traffic. This task extends that task to enable HTTPS access to the service using either simple or mutual TLS.

## Before you begin

1.  Perform the steps in the [Before you begin](/docs/tasks/traffic-management/ingress#before-you-begin) and [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress#determining-the-ingress-ip-and-ports) sections of the
[Control Ingress Traffic](/docs/tasks/traffic-management/ingress) task. After performing those steps you should have Istio and the [httpbin]({{< github_tree >}}/samples/httpbin) service deployed, and the environment variables `INGRESS_HOST` and `SECURE_INGRESS_PORT` set.

1.  For macOS users, verify that you use _curl_ compiled with the [LibreSSL](http://www.libressl.org) library:

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    If a version of _LibreSSL_ is printed as in the output above, your _curl_ should work correctly with the
    instructions in this task. Otherwise, try another installation of _curl_, for example on a Linux machine.

## Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. This example uses [a script](https://github.com/nicholasjackson/mtls-go-example/blob/master/generate.sh)
from the <https://github.com/nicholasjackson/mtls-go-example> repository.

1.  Clone the <https://github.com/nicholasjackson/mtls-go-example> repository:

    {{< text bash >}}
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    {{< /text >}}

1.  Change directory to the cloned repository:

    {{< text bash >}}
    $ cd mtls-go-example
    {{< /text >}}

1.  Generate the certificates (use any password):

    {{< text bash >}}
    $ ./generate.sh httpbin.example.com <password>
    {{< /text >}}

     When prompted, select `y` for all the questions. The command will generate four directories: `1_root`,
     `2_intermediate`, `3_application`, and `4_client` containing the client and server certificates you use in the
     procedures below.

## Configure a TLS ingress gateway

In this subsection you configure an ingress gateway with port 443 to handle HTTPS traffic. You first create a secret
with a certificate and a private key. Then you create a `Gateway` definition that contains a `server` on port 443.

1. Create a Kubernetes `Secret` to hold the server's certificate and private key. Use `kubectl` to create the secret
`istio-ingressgateway-certs` in namespace `istio-system` . The Istio gateway will load the secret automatically.

    > The secret **must** be called `istio-ingressgateway-certs` in the `istio-system` namespace, or it will not
    > be mounted and available to the Istio gateway.

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key 3_application/private/httpbin.example.com.key.pem --cert 3_application/certs/httpbin.example.com.cert.pem
    secret "istio-ingressgateway-certs" created
    {{< /text >}}

    Note that by default all the service accounts in the `istio-system` namespace can access this secret, so the private
    key can be leaked. You can change the
    [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) rules to protect
    it.

1.  Define a `Gateway` with a `server` section for port 443.

    > The location of the certificate and the private key **must** be `/etc/istio/ingressgateway-certs`, or the gateway will fail to load them.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
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
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the `Gateway`. Define the same `VirtualService` as in the [Control Ingress Traffic](/docs/tasks/traffic-management/ingress/#configuring-ingress-using-an-istio-gateway) task:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "httpbin.example.com"
      gateways:
      - httpbin-gateway
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

1.  Access the `httpbin` service with HTTPS by sending an `https` request using _curl_ to `SECURE_INGRESS_PORT`.

    The `--resolve` flag instructs _curl_ to supply the
    [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) value "httpbin.example.com" when accessing the gateway IP
      over TLS. The `--cacert` option instructs _curl_ to use your generated certificate to verify the server.

    By sending the request to the `/status/418` URL path, you get a nice visual clue that your `httpbin` service was
    indeed accessed. The `httpbin` service will return the
    [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

    {{< text bash >}}
    $ curl -v --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST --cacert 2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    ...
    Server certificate:
      subject: C=US; ST=Denial; L=Springfield; O=Dis; CN=httpbin.example.com
      start date: Jun 24 18:45:18 2018 GMT
      expire date: Jul  4 18:45:18 2019 GMT
      common name: httpbin.example.com (matched)
      issuer: C=US; ST=Denial; O=Dis; CN=httpbin.example.com
    SSL certificate verify ok.
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

    > It might take time for the gateway definition to propagate so you might get the following error:
    > `Failed to connect to httpbin.example.com port <your secure port>: Connection refused`. Wait for a minute and
    > retry the _curl_ call.

    Look for the _Server certificate_ section in the _curl_ output and note the line about matching the _common name_:
    `common name: httpbin.example.com (matched)`. According to the line `SSL certificate verify ok` in the output of
    _curl_, you can be sure that the server's certificate was verified successfully. Note the returned status of 418 and
    a nice drawing of a teapot.

If you need to support [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication) proceed to the next section.

## Configure a mutual TLS ingress gateway

In this section you extend your gateway's definition from the previous section to support
[mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication) between external clients and the gateway.

1. Create a Kubernetes `Secret` to hold the [CA](https://en.wikipedia.org/wiki/Certificate_authority) certificate that
the server will use to verify its clients. Create the secret `istio-ingressgateway-ca-certs` in namespace `istio-system`
 using `kubectl`. The Istio gateway will automatically load the secret.

    > The secret **must** be called `istio-ingressgateway-ca-certs` in the `istio-system` namespace, or it will not
    > be mounted and available to the Istio gateway.

    {{< text bash >}}
    $ kubectl create -n istio-system secret generic istio-ingressgateway-ca-certs --from-file=2_intermediate/certs/ca-chain.cert.pem
    secret "istio-ingressgateway-ca-certs" created
    {{< /text >}}

1.  Redefine your previous `Gateway` to change the `tls` `mode` to `MUTUAL` and specifying `caCertificates`:

    > The location of the certificate **must** be `/etc/istio/ingressgateway-ca-certs`, or the gateway
    will fail to load them. The file name of the certificate must be identical to the filename you create the secret
    from, in this case `ca-chain.cert.pem`.

    {{< text bash >}}
    $ cat <<EOF | istioctl replace -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
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
          serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
          privateKey: /etc/istio/ingressgateway-certs/tls.key
          caCertificates: /etc/istio/ingressgateway-ca-certs/ca-chain.cert.pem
        hosts:
        - "httpbin.example.com"
    EOF
    {{< /text >}}

1.  Access the `httpbin` service by HTTPS as in the previous section:

    {{< text bash >}}
    $ curl --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST  --cacert 2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
    curl: (35) error:14094410:SSL routines:SSL3_READ_BYTES:sslv3 alert handshake failure
    {{< /text >}}

    > It might take time for the gateway definition to propagate so you might still get _418_. Wait for a minute and retry
    the _curl_ call.

    This time you get an error since the server refuses to accept unauthenticated requests. You have to send a client
    certificate and pass _curl_ your private key for signing the request.

1.  Resend the previous request by _curl_, this time passing as parameters your client certificate (the `--cert` option)
 and your private key (the `--key` option):

    {{< text bash >}}
    $ curl --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST  --cacert 2_intermediate/certs/ca-chain.cert.pem --cert 4_client/certs/httpbin.example.com.cert.pem --key 4_client/private/httpbin.example.com.key.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

    This time the server performed client authentication successfully and you received the pretty teapot drawing again.

## Troubleshooting

1.  Inspect the values of the `INGRESS_HOST` and `SECURE_INGRESS_PORT` environment variables. Make sure
they have valid values, according to the output of the following commands:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT
    {{< /text >}}

1.  Verify that the key and the certificate are successfully loaded in the `istio-ingressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-certs
    {{< /text >}}

    `tls.crt` and `tls.key` should exist in the directory contents.

1.  Verify that the _Subject_ is correct in the certificate of the ingress gateway:

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-certs/tls.crt | openssl x509 -text -noout | grep 'Subject:'
        Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=httpbin.example.com
    {{< /text >}}

1.  Check the log of `istio-ingressgateway` for error messages:

    {{< text bash >}}
    $ kubectl logs -n istio-system -l istio=ingressgateway
    {{< /text >}}

1.  For macOS users, verify that you use _curl_ compiled with the [LibreSSL](http://www.libressl.org) library, as
    described in the [Before you begin](#before-you-begin) section.

### Troubleshooting for mutual TLS

In addition to the steps in the previous section, perform the following:

1.  Verify that the CA certificate is loaded in the `istio-ingressgateway` pod:

    {{< text bash >}}
    $ kubectl exec -it -n istio-system $(kubectl -n istio-system get pods -l istio=ingressgateway -o jsonpath='{.items[0].metadata.name}') -- ls -al /etc/istio/ingressgateway-ca-certs
    {{< /text >}}

    `ca-chain.cert.pem` should exist in the directory contents.

1.  Verify that the _Subject_ is correct in the CA certificate of the ingress gateway:

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/istio/ingressgateway-ca-certs/ca-chain.cert.pem | openssl x509 -text -noout | grep 'Subject:'
    Subject: C=US, ST=Denial, L=Springfield, O=Dis, CN=httpbin.example.com
    {{< /text >}}

## Cleanup

1.  Delete the `Gateway` configuration, the `VirtualService`, and the secrets:

    {{< text bash >}}
    $ istioctl delete gateway httpbin-gateway
    $ istioctl delete virtualservice httpbin
    $ kubectl delete --ignore-not-found=true -n istio-system secret istio-ingressgateway-certs istio-ingressgateway-ca-certs
    {{< /text >}}

1.  Shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

    {{< text bash >}}
    $ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}
