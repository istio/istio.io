---
title: Control Ingress Traffic
description: Describes how to configure Istio to expose a service outside of the service mesh.

weight: 30

redirect_from: /docs/tasks/ingress.html
---
{% include home.html %}

In a Kubernetes environment, the [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
allows users to specify services that should be exposed outside the cluster.
For traffic entering an Istio service mesh, however, an Istio-aware [ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-controllers)
is needed to allow Istio features, for example, monitoring and route rules, to be applied to traffic entering the cluster.

Istio provides an Envoy-based ingress controller that implements very limited support for standard Kubernetes `Ingress` resources
as well as full support for an alternative specification,
[Istio Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway).
Using a `Gateway` is the recommended approach for configuring ingress traffic for Istio services.
It is significantly more functional, not to mention the only option for non-Kubernetes environments.

This task describes how to configure Istio to expose a service outside of the service mesh using either specification.

## Before you begin

* Setup Istio by following the instructions in the
  [Installation guide]({{home}}/docs/setup/).

* Make sure your current directory is the `istio` directory.

* Start the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) sample,
  which will be used as the destination service to be exposed externally.

  If you installed  [Istio-Initializer]({{home}}/docs/setup/kubernetes/sidecar-injection.html#automatic-sidecar-injection), do

  ```command
  $ kubectl apply -f samples/httpbin/httpbin.yaml
  ```

  Without Istio-Initializer:

  ```command
  $ kubectl apply -f <(istioctl kube-inject -f samples/httpbin/httpbin.yaml)
  ```

* Generate a certificate and key that will be used to demonstrate a TLS-secured gateway

   A private key and certificate can be created for testing using [OpenSSL](https://www.openssl.org/).

   ```command
   $ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/tls.key -out /tmp/tls.crt -subj "/CN=foo.bar.com"
   ```

## Configuring ingress using an Istio Gateway resource (recommended)

An [Istio Gateway]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway) is the preferred
model for configuring ingress traffic in Istio.
An ingress `Gateway` describes a load balancer operating at the edge of the mesh receiving incoming
HTTP/TCP connections.
It configures exposed ports, protocols, etc.,
but, unlike [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/),
does not include any traffic routing configuration. Traffic routing for ingress traffic is instead configured
using Istio routing rules, exactly in the same was as for internal service requests.

In the following subsections we configure a `Gateway` on port 80 for unencrypted HTTP traffic first. Then we add a secure port 443 for HTTPS traffic.

### Configuring unencrypted gateway (HTTP)

1. Create an Istio `Gateway`

   ```bash
   cat <<EOF | istioctl create -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: Gateway
   metadata:
     name: httpbin-gateway
   spec:
     selector:
       istio: ingressgateway # use istio default controller
     servers:
     - port:
         number: 80
         name: http
         protocol: HTTP
       hosts:
       - "foo.bar.com"
   EOF
   ```

1. Configure routes for traffic entering via the `Gateway`

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
   configuration for the `httpbin` service, containing two route rules that allow traffic for paths `/status` and `/delay`.
   The [gateways]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#VirtualService.gateways) list
   specifies that only requests through our `httpbin-gateway` are allowed.
   All other external requests will be rejected with a 404 response.

   Note that in this configuration internal requests from other services in the mesh are not subject to these rules,
   but instead will simply default to round-robin routing. To apply these (or other rules) to internal calls,
   we could add the special value `mesh` to the list of `gateways`.

### Verifying unencrypted gateway

The proxy instances implementing a particular `Gateway` configuration can be specified using a
[selector]({{home}}/docs/reference/config/istio.networking.v1alpha3.html#Gateway.selector) field.
In our case, we have set the selector value to `istio: ingressgateway` to use the default
`istio-ingressgateway` controller. Therefore, to test our gateway we will send requests to
the default `istio-ingressgateway` service.

1. Get the `ingressgateway` controller pod's hostIP:

   ```command
   $ kubectl -n istio-system get po -l istio=ingressgateway -o jsonpath='{.items[0].status.hostIP}'
   169.47.243.100
   ```

1. Get the `istio-ingressgateway` service's _nodePort_ for port 80:

   ```command
   $ kubectl -n istio-system get svc istio-ingressgateway
   NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   istio-ingressgateway   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
   ```

   ```command
   $ export INGRESS_HOST=169.47.243.100
   $ export INGRESS_PORT=31486
   ```

1. Access the _httpbin_ service using _curl_. Note the `--resolve` flag of _curl_ that allows to access an IP address by using an arbitrary domain name. In our case we access our ingress Gateway by "foo.bar.com". Note that we specified "foo.bar.com" as a host handled by our `Gateway`.

   ```command
   $ curl --resolve foo.bar.com:$INGRESS_PORT:$INGRESS_HOST -I http://foo.bar.com:$INGRESS_PORT/status/200
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 48
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see an HTTP 404 error:

   ```command
   $ curl --resolve foo.bar.com:$INGRESS_PORT:$INGRESS_HOST -I http://foo.bar.com:$INGRESS_PORT/headers
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

### Add a secure port (HTTPS) to our gateway

In this subsection we add the port 443 to handle the HTTPS traffic. We redeploy the pod of the Istio ingress gateway controller with our private key and certificate to use for TLS traffic. Then we replace the previous `Gateway` definition with a definition that contains a server on the port 443, in addition to the previously defined server on the port 80.

#### Inject our private key and certificate into the pod of the Istio ingress gateway controller

1. Create a Kubernetes secret of the type `tls` from the private key and the certificate we created in the [Before you begin](#before-you-begin) section. We can use any name as the name of the secret, let's call it _my-ingress-cert_.

   ```command
   kubectl create -n istio-system secret tls my-ingress-cert --key /tmp/tls.key --cert /tmp/tls.crt
   ```

1. Render the Kubernetes manifest of the pod of `istio-ingressgateway` (the default ingress gateway controller) with Helm. Add a volume to the pod from the secret we created in the previous step. To perform this, we set the value of `ingressgateway.deployment.secretVolumes` to a list of volumes we want to mount. We can specify any name for the volume and any mount path. Let's call our volume _my-ingress-cert-volume_ and mount it at _/etc/my-ingress-cert_. We use Helm's syntax for passing values as parameters by `--set` option. In particular, we can pass a list of volumes to mount, by specifying indexes of the `ingressgateway.deployment.secretVolumes` value: `ingressgateway.deployment.secretVolumes[0]`, `ingressgateway.deployment.secretVolumes[1]` etc.

   ```command
   helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
   --set ingressgateway.deployment.secretVolumes[0].name=my-ingress-cert-volume,ingressgateway.deployment.secretVolumes[0].secretName=my-ingress-cert,ingressgateway.deployment.secretVolumes[0].mountPath=/etc/my-ingress-cert
  -x charts/ingressgateway/templates/deployment.yaml > $HOME/istio-ingressgateway-deployment.yaml
   ```

    **Alternative: if we deployed Istio by Helm, we can upgrade our release, see the next step.

1. Redeploy the rendered `istio-ingressgateway`:

   ```command
   kubectl apply -f $HOME/istio-ingressgateway-deployment.yaml
   ```

   **Alternative: if we deployed Istio by Helm, we _upgrade_ our release, setting the value of `ingressgateway.deployment.secretVolumes`:

   ```command
   helm upgrade istio install/kubernetes/helm/istio --namespace istio-system \
   --set ingressgateway.deployment.secretVolumes[0].name=my-ingress-cert-volume,ingressgateway.deployment.secretVolumes[0].secretName=my-ingress-cert,ingressgateway.deployment.secretVolumes[0].mountPath=/etc/my-ingress-cert
   ```

1. Verify that our gateway still works for the port 80 and accepts unencrypted HTTP traffic as before. We do it by accessing the _httpbin_ service, port 80, as described in the [Verifying unencrypted gateway](#verifying-unencrypted-gateway) subsection.

#### Add a secure server on the port 443 to our Gateway definition

1. Replace the previous `Gateway` definition with a server section for the port 443. Specify the locations of the certificate and the private key we mounted in the previous subsection.

   ```bash
   cat <<EOF | istioctl replace -f -
   apiVersion: networking.istio.io/v1alpha3
   kind: Gateway
   metadata:
     name: httpbin-gateway
   spec:
     selector:
       istio: ingressgateway # use istio default controller
     servers:
     - port:
         number: 80
         name: http
         protocol: HTTP
       hosts:
       - "foo.bar.com"
     - port:
         number: 443
         name: https
         protocol: HTTPS
       tls:
         mode: SIMPLE
         serverCertificate: /etc/my-ingress-cert/tls.crt
         privateKey: /etc/my-ingress-cert/tls.key
       hosts:
       - "foo.bar.com"
   EOF
   ```

### Verifying secure gateway

1. Get the `istio-ingressgateway` service's _nodePort_ for the port 443:

   ```command
   $ kubectl -n istio-system get svc istio-ingressgateway
   NAME                   CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   istio-ingressgateway   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
   ```

   ```command
   $ export SECURE_INGRESS_PORT=32254
   ```
1. Access the _httpbin_ service by HTTPS. Here we use _curl_'s `-k` option to instruct _curl_ not to check our certificate (since it is a fake certificate we created for testing the Gateway only, _curl_ is not aware about it).

   ```command
   $ curl --resolve foo.bar.com:$SECURE_INGRESS_PORT:$INGRESS_HOST -I -k https://foo.bar.com:$SECURE_INGRESS_PORT/status/200
   HTTP/2 200
   server: envoy
   date: Mon, 14 May 2018 13:54:53 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 6
   ```

## Configuring ingress using a Kubernetes Ingress resource

An Istio `Ingress` specification is based on the standard [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
specification, with the following differences:

1. Istio `Ingress` specification contains a `kubernetes.io/ingress.class: istio` annotation.

1. All other annotations are ignored.

1. Path syntax is [c++11 regex format](http://en.cppreference.com/w/cpp/regex/ecmascript)

Note that `Ingress` traffic is not affected by routing rules configured for a backend
(i.e., an Istio `VirtualService` cannot be combined with an `Ingress` specification).
Traffic splitting, fault injection, mirroring, header match, etc., will not work for ingress traffic.
A `DestinationRule` associated with the backend service will, however, work as expected.

The `servicePort` field in the `Ingress` specification can take a port number
(integer) or a name. The port name must follow the Istio port naming
conventions (e.g., `grpc-*`, `http2-*`, `http-*`, etc.) in order to
function properly. The name used must match the port name in the backend
service declaration.

### Configuring simple Ingress

1. Create a basic `Ingress` specification for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: simple-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     rules:
     - http:
         paths:
         - path: /status/*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

### Verifying simple Ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers, use the ingress' external address:

   ```command
   $ kubectl get ingress simple-ingress -o wide
   NAME             HOSTS     ADDRESS                 PORTS     AGE
   simple-ingress   *         130.211.10.121          80        1d
   ```

   ```command
   $ export INGRESS_HOST=130.211.10.121
   ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:

   ```command
   $ kubectl -n istio-system get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
   169.47.243.100
   ```

   along with the istio-ingress service's nodePort for port 80:

   ```command
   $ kubectl -n istio-system get svc istio-ingress
   NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
   ```

   ```command
   $ export INGRESS_HOST=169.47.243.100:31486
   ```

1. Access the httpbin service using _curl_:

   ```command
   $ curl -I http://$INGRESS_HOST/status/200
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 48
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```command
   $ curl -I http://$INGRESS_HOST/headers
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

### Configuring secure Ingress (HTTPS)

1. Create a Kubernetes `Secret` to hold the key/cert

   Create the secret `istio-ingress-certs` in namespace `istio-system` using `kubectl`. The Istio ingress controller
   will automatically load the secret.

   > The secret MUST be called `istio-ingress-certs` in the `istio-system` namespace, or it will not
   be mounted and available to the Istio ingress controller.

   ```command
   $ kubectl create -n istio-system secret tls istio-ingress-certs --key /tmp/tls.key --cert /tmp/tls.crt
   ```

   Note that by default all service accounts in the `istio-system` namespace can access this ingress key/cert,
   which risks leaking the key/cert. You can change the Role-Based Access Control (RBAC) rules to protect them.
   See (Link TBD) for details.

1. Create the `Ingress` specification for the httpbin service

   ```bash
   cat <<EOF | kubectl create -f -
   apiVersion: extensions/v1beta1
   kind: Ingress
   metadata:
     name: secure-ingress
     annotations:
       kubernetes.io/ingress.class: istio
   spec:
     tls:
       - secretName: istio-ingress-certs # currently ignored
     rules:
     - http:
         paths:
         - path: /status/*
           backend:
             serviceName: httpbin
             servicePort: 8000
         - path: /delay/*
           backend:
             serviceName: httpbin
             servicePort: 8000
   EOF
   ```

   > Because SNI is not yet supported, Envoy currently only allows a single TLS secret in the ingress.
   > That means the secretName field in ingress resource is not used.

### Verifying secure Ingress

1. Determine the ingress URL:

   * If your cluster is running in an environment that supports external load balancers,
   use the ingress' external address:

   ```command
   $ kubectl get ingress secure-ingress -o wide
   NAME             HOSTS     ADDRESS                 PORTS     AGE
   secure-ingress   *         130.211.10.121          80        1d
   ```

   ```command
   $ export SECURE_INGRESS_HOST=130.211.10.121
   ```

   * If load balancers are not supported, use the ingress controller pod's hostIP:

   ```command
   $ kubectl -n istio-system get po -l istio=ingress -o jsonpath='{.items[0].status.hostIP}'
   169.47.243.100
   ```

   along with the istio-ingress service's nodePort for port 443:

   ```command
   $ kubectl -n istio-system get svc istio-ingress
   NAME            CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   istio-ingress   10.10.10.155   <pending>     80:31486/TCP,443:32254/TCP   32m
   ```

   ```command
   $ export SECURE_INGRESS_HOST=169.47.243.100:32254
   ```

1. Access the httpbin service using _curl_:

   ```command
   $ curl -I -k https://$SECURE_INGRESS_HOST/status/200
   HTTP/1.1 200 OK
   server: envoy
   date: Mon, 29 Jan 2018 04:45:49 GMT
   content-type: text/html; charset=utf-8
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 0
   x-envoy-upstream-service-time: 96
   ```

1. Access any other URL that has not been explicitly exposed. You should
   see a HTTP 404 error

   ```command
   $ curl -I -k https://$SECURE_INGRESS_HOST/headers
   HTTP/1.1 404 Not Found
   date: Mon, 29 Jan 2018 04:45:49 GMT
   server: envoy
   content-length: 0
   ```

## Understanding what happened

`Gateway` or `Ingress` configuration resources allow external traffic to enter the
Istio service mesh and make the traffic management and policy features of Istio
available for edge services.

In the preceding steps we created a service inside the Istio service mesh
and showed how to expose both HTTP and HTTPS endpoints of the service to
external traffic. Using an Istio `Gateway` provides significantly more functionality
and is recommended. Using a Kubernetes `Ingress`, however, is also supported
and may be especially useful when moving existing Kubernetes applications to Istio.

## Cleanup

1. Remove the `Gateway` configuration.

   ```command
   $ kubectl delete gateway httpbin-gateway
   ```

1. Remove the `Ingress` configuration.

   ```command
   $ kubectl delete ingress simple-ingress secure-ingress
   ```

1. Remove the routing rule and secret.

   ```command
   $ istioctl delete virtualservice httpbin
   $ kubectl delete -n istio-system secret istio-ingress-certs
   ```

1. Shutdown the [httpbin](https://github.com/istio/istio/tree/master/samples/httpbin) service.

   ```command
   $ kubectl delete -f samples/httpbin/httpbin.yaml
   ```

## What's next

* Learn more about [Traffic Routing]({{home}}/docs/reference/config/istio.networking.v1alpha3.html).
