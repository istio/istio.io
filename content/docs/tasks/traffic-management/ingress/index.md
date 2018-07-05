---
title: Control Ingress Traffic
description: Describes how to configure Istio to expose a service outside of the service mesh.
weight: 30
keywords: [traffic-management,ingress]
aliases:
    - /docs/tasks/ingress.html
---

> Note: This task uses the new [v1alpha3 traffic management API](/blog/2018/v1alpha3-routing/). The old API has been deprecated and will be removed in the next Istio release. If you need to use the old version, follow the docs [here](https://archive.istio.io/v0.7/docs/tasks/traffic-management/).

In a Kubernetes environment, the [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
is used to specify services that should be exposed outside the cluster.
In an Istio service mesh, a better approach (which also works in both Kubernetes and other environments) is to use a
different configuration model, namely [Istio Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway).
A `Gateway` allows Istio features, for example, monitoring and route rules, to be applied to traffic entering the cluster.

This task describes how to configure Istio to expose a service outside of the service mesh using an Istio `Gateway`.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Make sure your current directory is the `istio` directory.

*   Start the [httpbin]({{< github_tree >}}/samples/httpbin) sample,
    which will be used as the destination service to be exposed externally.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), do

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    otherwise, you have to manually inject the sidecar before deploying the `httpbin` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}

*   Determine the ingress IP and ports as described in the following subsection.

### Determining the ingress IP and ports

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers.

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

If the `EXTERNAL-IP` value is set, your environment has an external load balancer that you can use for the ingress gateway.
If the `EXTERNAL-IP` value is `<none>` (or perpetually `<pending>`), your environment does not provide an external load balancer for the ingress gateway.
In this case, you can access the gateway using the service's [node port](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport).

#### Determining the ingress IP and ports when using an external load balancer

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

#### Determining the ingress IP and ports when using a node port

Determine the ports:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

Determining the ingress IP depends on the cluster provider.

1.  _GKE:_

    {{< text bash >}}
    $ export INGRESS_HOST=<workerNodeAddress>
    {{< /text >}}

    You need to create firewall rules to allow the TCP traffic to the _ingressgateway_ service's ports.
    Run the following commands to allow the traffic for the HTTP port, the secure port (HTTPS) or both.

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow tcp:$INGRESS_PORT
    $ gcloud compute firewall-rules create allow-gateway-https --allow tcp:$SECURE_INGRESS_PORT
    {{< /text >}}

1.  _IBM Cloud Kubernetes Service Free Tier:_

    {{< text bash >}}
    $ bx cs workers <cluster-name or id>
    $ export INGRESS_HOST=<public IP of one of the worker nodes>
    {{< /text >}}

1.  _Minikube:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(minikube ip)
    {{< /text >}}

1.  _Other environments (e.g., IBM Cloud Private etc):_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
    {{< /text >}}

## Configuring ingress using an Istio Gateway

An ingress [Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) describes a load balancer operating at the edge of the mesh receiving incoming HTTP/TCP connections.
It configures exposed ports, protocols, etc.,
but, unlike [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/),
does not include any traffic routing configuration. Traffic routing for ingress traffic is instead configured
using Istio routing rules, exactly in the same was as for internal service requests.

Let's see how you can configure a `Gateway` on port 80 for HTTP traffic.

1.  Create an Istio `Gateway`

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
    {{< /text >}}

1.  Configure routes for traffic entering via the `Gateway`

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

    Here we've created a [virtual service](/docs/reference/config/istio.networking.v1alpha3/#VirtualService)
    configuration for the `httpbin` service, containing two route rules that allow traffic for paths `/status` and
    `/delay`.

    The [gateways](/docs/reference/config/istio.networking.v1alpha3/#VirtualService-gateways) list
    specifies that only requests through our `httpbin-gateway` are allowed.
    All other external requests will be rejected with a 404 response.

    Note that in this configuration internal requests from other services in the mesh are not subject to these rules,
    but instead will simply default to round-robin routing. To apply these (or other rules) to internal calls,
    we could add the special value `mesh` to the list of `gateways`.

1.  Access the _httpbin_ service using _curl_.

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200
    HTTP/1.1 200 OK
    server: envoy
    date: Mon, 29 Jan 2018 04:45:49 GMT
    content-type: text/html; charset=utf-8
    access-control-allow-origin: *
    access-control-allow-credentials: true
    content-length: 0
    x-envoy-upstream-service-time: 48
    {{< /text >}}

    Note that we use the `-H` flag to set the _Host_ HTTP Header to
    "httpbin.example.com". This is needed because our ingress `Gateway` is configured to handle "httpbin.example.com",
    but in our test environment we have no DNS binding for that host and are simply sending our request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    {{< /text >}}

## Accessing ingress services using a browser

As you may have guessed, entering the httpbin service URL in a browser won't work because we don't have a way to tell the browser to pretend to be accessing "httpbin.example.com", like we did with _curl_. In a real world situation this wouldn't be a problem because the requested host would be properly configured and DNS resolvable, so we would simply be using its domain name in the URL (e.g., `https://httpbin.example.com/status/200`).

To work around this problem for simple tests and demos, we can use a wildcard `*` value for the host in the `Gateway` and `VirutualService` configurations. For example, if we change our ingress configuration to the following:

{{< text bash >}}
$ cat <<EOF | istioctl replace -f -
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
    - "*"
---
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
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

We can then use `$INGRESS_HOST:$INGRESS_PORT` (e.g., `192.168.99.100:31380`) in the URL that we enter in a browser. For example, `http://192.168.99.100:31380/headers` should display the request headers sent by our browser.

## Understanding what happened

The `Gateway` configuration resources allow external traffic to enter the
Istio service mesh and make the traffic management and policy features of Istio
available for edge services.

In the preceding steps we created a service inside the service mesh
and showed how to expose an HTTP endpoint of the service to
external traffic.

## Cleanup

Delete the `Gateway` configuration, the `VirtualService` and the secret, and shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

{{< text bash >}}
$ istioctl delete gateway httpbin-gateway
$ istioctl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
