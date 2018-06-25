---
title: Secure Ingress Traffic Control
description: Describes how to configure Istio to expose a service outside of the service mesh, over TLS or Mutual TLS.
weight: 31
keywords: [traffic-management,ingress]
---

> Note: This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

The [Control Ingress Traffic](/docs/tasks/traffic-management/ingress.md) task describes how to configure an ingress
gateway to enable TLS (non-mutual) traffic from outside the mesh into the mesh. This task extends that task to enable
Mutual TLS ingress traffic.

## Before you begin

Perform the steps in the [Before you begin](/docs/tasks/traffic-management/ingress.md#before-you-begin) and [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports) sections of the
[Control Ingress Traffic](/docs/tasks/traffic-management/ingress.md) task. After performing those steps you should have Istio and _httbin_ service deployed, and the environment variables `INGRESS_HOST`, `INGRESS_PORT` and `SECURE_INGRESS_PORT` set.

## Generate client and server certificates and keys

For this task you can use your favorite tool to generate certificates and keys. We used [a script](https://github.com/nicholasjackson/mtls-go-example/blob/master/generate.sh)
from the https://github.com/nicholasjackson/mtls-go-example repository.


1.  Clone the https://github.com/nicholasjackson/mtls-go-example repository:

    ```command
    $ git clone https://github.com/nicholasjackson/mtls-go-example
    ```

1.  Change directory to the cloned repository:

    ```command
    $ cd mtls-go-example
    ```

1.  Generate the certificates (use any password):

    ```command
    generate.sh httpbin.example.com <password>
    ```

    The command will generate four directories: `1_root`, `2_intermediate`, `3_application` and `4_client` with client
    and server certificates you will use.

### Configure a TLS ingress gateway

In this subsection we configure an ingress gateway with the port 443 to handle the HTTPS traffic. We create a secret
with a certificate and a private key. Then we create a `Gateway` definition that contains a server on the port 443.

1. Create a Kubernetes `Secret` to hold the key/cert

    Create the secret `istio-ingressgateway-certs` in namespace `istio-system` using `kubectl`. The Istio gateway
    will automatically load the secret.

    > The secret MUST be called `istio-ingressgateway-certs` in the `istio-system` namespace, or it will not
    > be mounted and available to the Istio gateway.

    ```command
    $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key 3_application/private/httpbin.example.com.key.pem --cert 3_application/certs/httpbin.example.com.cert.pem
    ```

    Note that by default all service accounts in the `istio-system` namespace can access this ingress key/cert,
    which risks leaking the key/cert. You can change the
    [Role-Based Access Control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) rules to protect
    them.

1.  Define a `Gateway` with a server section for the port 443.

    > The location of the certificate and the private key MUST be `/etc/istio/ingressgateway-certs`, or the gateway will fail to load them.

    ```bash
        cat <<EOF | istioctl create -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: httpbin-gateway
        spec:
          selector:
            istio: ingressgateway # use istio default ingress gateway
          servers:
          - port:
              number: 80
              name: http
              protocol: HTTP
            hosts:
            - "httpbin.example.com"
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
    ```

1.  Configure routes for traffic entering via the `Gateway`. Define a `VirtualService` to route the traffic entering via `Gateway` (it is the `VirtualService` as in the [Control Ingress Traffic](/docs/tasks/traffic-management/ingress/#configuring-ingress-using-an-istio-gateway) task:

    ```bash
        cat <<EOF | istioctl create -f -
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
    ```

1.  Access the _httpbin_ service by HTTPS, sending an HTTPS request by _curl_ to `SECURE_INGRESS_PORT`.
Use _curl_'s `--cacert` option to instruct it to use your generated certificate to verify the server. Send the request
to the _/status/418_ URL path, to get a nice visual clue that your _httpbin_ service was indeed accessed. The _httpbin_
service will return the [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3) code.

    ```command
    $ curl -v --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST  --cacert 2_intermediate/certs/ca-chain.cert.pem https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418
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
    ```

    > Note that it may take time for the new gateway definition to propagate and you may get the following error:
    `Failed to connect to httpbin.example.com port <your secure port>: Connection refused`. Wait for a minute and retry
    the `curl` call again.

    Look for the _Server certificate_ section in the output of `curl`, note the line about matching the _common name_:
    `common name: httpbin.example.com (matched)`. According to the line _SSL certificate verify ok_ in the output of
    `curl`, you can be sure that the server's certificate was verified successfully. Note the returned status of 418 and
    a nice drawing of a teapot.


### Cleanup the TLS gateway

Delete the `Gateway` configuration, the `VirtualService` and the secret:

```command
$ istioctl delete gateway httpbin-gateway
$ istioctl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -n istio-system secret istio-ingressgateway-certs
```

## Cleanup

Shutdown the [httpbin](https://github.com/istio/istio/blob/{{<branch_name>}}/samples/httpbin) service:

```command
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
```
