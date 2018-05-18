---
title: Control Ingress Traffic
description: Describes how to configure Istio to expose a service outside of the service mesh.

weight: 30

redirect_from: /docs/tasks/ingress.html
---
{% include home.html %}

In a Kubernetes environment, the [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
is used to specify services that should be exposed outside the cluster.

In an Istio service mesh, a better approach (which also works in both Kubernetes and other environments) is to use a different configuration model, namely [Istio Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway). It allows Istio features, for example, monitoring and route rules, to be applied to traffic entering the cluster.

This task describes how to configure Istio to expose a service outside of the service mesh using an [Istio Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway).

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Make sure your current directory is the `istio` directory.

*   Start the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) sample,
    which will be used as the destination service to be exposed externally.

    If you installed  [Istio-Initializer]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection), do

    ```command
    $ kubectl apply -f samples/httpbin/httpbin.yaml
    ```

    Without Istio-Initializer:

    ```command
    $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
    ```

*   Generate a certificate and key that will be used to demonstrate a TLS-secured gateway

    A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

    ```command
    $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=httpbin.example.com"
    ```

## Configuring ingress using an Istio Gateway

An ingress [Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway) describes a load balancer operating at the edge of the mesh receiving incoming HTTP/TCP connections.
It configures exposed ports, protocols, etc.,
but, unlike [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/),
does not include any traffic routing configuration. Traffic routing for ingress traffic is instead configured
using Istio routing rules, exactly in the same was as for internal service requests.

In the following subsections we configure a `Gateway` on port 80 for unencrypted HTTP traffic first. Then we add a secure port 443 for HTTPS traffic.

### Configuring a gateway for HTTP

1.  Create an Istio `Gateway`

    ```bash
    cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: httpbin-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "httpbin.example.com"
    EOF
    ```

1.  Configure routes for traffic entering via the `Gateway`

    ```bash
    cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "*"
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

    Here we've created a [virtual service]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#VirtualService)
    configuration for the `httpbin` service, containing two route rules that allow traffic for paths `/status` and
    `/delay`.

    The [gateways]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#VirtualService.gateways) list
    specifies that only requests through our `httpbin-gateway` are allowed.
    All other external requests will be rejected with a 404 response.

    Note that in this configuration internal requests from other services in the mesh are not subject to these rules,
    but instead will simply default to round-robin routing. To apply these (or other rules) to internal calls,
    we could add the special value `mesh` to the list of `gateways`.

### Verifying the gateway for HTTP

The proxy instances implementing a particular `Gateway` configuration can be specified using a
[selector]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway.selector) field.
In our case, we have set the selector value to `istio: ingressgateway` to use the default
`istio-ingressgateway` implementation. Therefore, to test our gateway we will send requests to
the default `istio-ingressgateway` service.

1.  Get the `ingressgateway` controller pod's hostIP:

    ```command
    $ kubectl -n istio-system get po -l istio=ingressgateway -o jsonpath='{.items[0].status.hostIP}'
    169.47.243.100
    ```

1.  Get the `istio-ingressgateway` service's _nodePort_ for port 80:

    ```command
    $ kubectl -n istio-system get svc istio-ingressgateway
    NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    istio-ingressgateway   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
    ```

    ```command
    $ export INGRESS_HOST=169.47.243.100
    $ export INGRESS_PORT=31486
    ```

1.  Access the _httpbin_ service using _curl_. Note the `--resolve` flag of _curl_ that allows to access an IP address by using an arbitrary domain name. In our case we access our ingress Gateway by "httpbin.example.com". Note that we specified "httpbin.example.com" as a host handled by our `Gateway`.

    ```command
    $ curl --resolve httpbin.example.com:$INGRESS_PORT:$INGRESS_HOST -I http://httpbin.example.com:$INGRESS_PORT/status/200
    HTTP/1.1 200 OK
    server: envoy
    date: Mon, 29 Jan 2018 04:45:49 GMT
    content-type: text/html; charset=utf-8
    access-control-allow-origin: *
    access-control-allow-credentials: true
    content-length: 0
    x-envoy-upstream-service-time: 48
    ```

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    ```command
    $ curl --resolve httpbin.example.com:$INGRESS_PORT:$INGRESS_HOST -I http://httpbin.example.com:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    ```

### Add a secure port (HTTPS) to our gateway

In this subsection we add to our gateway the port 443 to handle the HTTPS traffic. We create a secret with a certificate and a private key. Then we replace the previous `Gateway` definition with a definition that contains a server on the port 443, in addition to the previously defined server on the port 80.

1. Create a Kubernetes `Secret` to hold the key/cert

   Create the secret `istio-ingressgateway-certs` in namespace `istio-system` using `kubectl`. The Istio gateway
   will automatically load the secret.

   > The secret MUST be called `istio-ingressgateway-certs` in the `istio-system` namespace, or it will not
   be mounted and available to the Istio gateway.

   ```command
   $ kubectl create -n istio-system secret tls istio-ingressgateway-certs --key /tmp/tls.key --cert /tmp/tls.crt
   ```

   Note that by default all service accounts in the `istio-system` namespace can access this ingress key/cert,
   which risks leaking the key/cert. You can change the Role-Based Access Control (RBAC) rules to protect them.
   See (Link TBD) for details.

1. Replace the previous `Gateway` definition with a server section for the port 443.

   > The location of the certificate and the private key MUST be `/etc/istio/ingressgateway-certs`, or the gateway will fail to load them.

   ```bash
   cat <<EOF | istioctl replace -f -
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

### Verifying the gateway for HTTPS

1. Verify that our gateway still works for the port 80 and accepts unencrypted HTTP traffic as before. We do it by accessing the _httpbin_ service, port 80, as described in the [Verifying the gateway for HTTP](#verifying-the-gateway-for-http) subsection.

1. Get the `istio-ingressgateway` service's _nodePort_ for the port 443:

   ```command
   $ kubectl -n istio-system get svc istio-ingressgateway
   NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   istio-ingressgateway   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
   ```

   ```command
   $ export SECURE_INGRESS_PORT=32254
   ```
1. Access the _httpbin_ service by HTTPS. Here we use _curl_'s `-k` option to instruct _curl_ not to check our certificate (since it is a fake certificate we created for testing the Gateway only, _curl_ is not aware of it).

   ```command
   $ curl --resolve httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST -I -k https://httpbin.example.com:$SECURE_INGRESS_PORT/status/200
   HTTP/2 200
   server: envoy
   date: Mon, 14 May 2018 13:54:53 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 6
   ```

### Disable the HTTP port

If we want allow HTTPS traffic only into our service mesh, we can remove the HTTP port from our gateway.

1.  Redefine the `Gateway` without the HTTP port:

    ```bash
    cat <<EOF | istioctl replace -f -
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
    ```

1.  Access the HTTP port and verify that it is not accessible (an error is returned):

    ```command
    $ curl --resolve httpbin.example.com:$INGRESS_PORT:$INGRESS_HOST -I http://httpbin.example.com:$INGRESS_PORT/status/200
    ```

## Understanding what happened

The `Gateway` configuration resources allow external traffic to enter the
Istio service mesh and make the traffic management and policy features of Istio
available for edge services.

In the preceding steps we created a service inside the Istio service mesh
and showed how to expose both HTTP and HTTPS endpoints of the service to
external traffic.

## Cleanup

1.  Remove the `Gateway` configuration.

    ```command
    $ istioctl delete gateway httpbin-gateway
    ```

1.  Remove the `VirtualService` and secret.

    ```command
    $ istioctl delete virtualservice httpbin
    $ kubectl delete -n istio-system secret istio-ingressgateway-certs
    ```

1.  Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

    ```command
    $ kubectl delete -f samples/httpbin/httpbin.yaml
    ```

## What's next

* Learn more about [Traffic Routing]({{home}}/docs/reference/config/istio.networking.v1alpha3.html).
