---
title: Control Ingress Traffic
description: Describes how to configure Istio to expose a service outside of the service mesh.
weight: 30
keywords: [traffic-management,ingress]
aliases:
    - /docs/tasks/ingress.html
---

In a Kubernetes environment, the [Kubernetes Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/)
is used to specify services that should be exposed outside the cluster.
In an Istio service mesh, a better approach (which also works in both Kubernetes and other environments) is to use a
different configuration model, namely [Istio Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway).
A `Gateway` allows Istio features such as monitoring and route rules to be applied to traffic entering the cluster.

This task describes how to configure Istio to expose a service outside of the service mesh using an Istio `Gateway`.

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Make sure your current directory is the `istio` directory.

*   Start the [httpbin]({{< github_tree >}}/samples/httpbin) sample,
    which will be used as the destination service to be exposed externally.

    If you have enabled [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection), deploy the `httpbin` service:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    Otherwise, you have to manually inject the sidecar before deploying the `httpbin` application:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@)
    {{< /text >}}

*   Determine the ingress IP and ports as described in the following subsection.

### Determining the ingress IP and ports

Execute the following command to determine if your Kubernetes cluster is running in an environment that supports external load balancers:

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

If the `EXTERNAL-IP` value is set, your environment has an external load balancer that you can use for the ingress gateway.
If the `EXTERNAL-IP` value is `<none>` (or perpetually `<pending>`), your environment does not provide an external load balancer for the ingress gateway.
In this case, you can access the gateway using the service's [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport).

Depending on your environment, follow the instructions in one of the following **mutually exclusive** subsections.

#### Determining the ingress IP and ports when using an external load balancer

Follow these instructions if you have determined that your environment **does have** an external load balancer.

Set the ingress IP and ports:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

Note that in certain environments, the load balancer may be exposed using a host name, instead of an IP address.
In this case, the `EXTERNAL-IP` value in the output from the command in the previous section will not be an IP address,
but rather a host name, and the above command will have failed to set the `INGRESS_HOST` environment variable. In this case, use the following command to correct the `INGRESS_HOST` value:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

#### Determining the ingress IP and ports when using a node port

Follow these instructions if you have determined that your environment **does not have** an external load balancer.

Set the ingress ports:

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

Setting the ingress IP depends on the cluster provider:

1.  _GKE:_

    {{< text bash >}}
    $ export INGRESS_HOST=<workerNodeAddress>
    {{< /text >}}

    You need to create firewall rules to allow the TCP traffic to the _ingressgateway_ service's ports.
    Run the following commands to allow the traffic for the HTTP port, the secure port (HTTPS) or both:

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

1.  _Docker For Desktop:_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _Other environments (e.g., IBM Cloud Private etc):_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
    {{< /text >}}

## Configuring ingress using an Istio Gateway

An ingress [Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) describes a load balancer operating at the edge of the mesh that receives incoming HTTP/TCP connections.
It configures exposed ports, protocols, etc.
but, unlike [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/),
does not include any traffic routing configuration. Traffic routing for ingress traffic is instead configured
using Istio routing rules, exactly in the same was as for internal service requests.

Let's see how you can configure a `Gateway` on port 80 for HTTP traffic.

1.  Create an Istio `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

1.  Configure routes for traffic entering via the `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

    You have now created a [virtual service](/docs/reference/config/istio.networking.v1alpha3/#VirtualService)
    configuration for the `httpbin` service containing two route rules that allow traffic for paths `/status` and
    `/delay`.

    The [gateways](/docs/reference/config/istio.networking.v1alpha3/#VirtualService-gateways) list
    specifies that only requests through your `httpbin-gateway` are allowed.
    All other external requests will be rejected with a 404 response.

    Note that in this configuration, internal requests from other services in the mesh are not subject to these rules
    but instead will default to round-robin routing. To apply these or other rules to internal calls,
    you can add the special value `mesh` to the list of `gateways`.

1.  Access the _httpbin_ service using _curl_:

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

    Note that you use the `-H` flag to set the _Host_ HTTP Header to
    "httpbin.example.com". This is needed because your ingress `Gateway` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    {{< /text >}}

## Accessing ingress services using a browser

Entering the `httpbin` service URL in a browser won't work because you can't tell the browser to pretend to be accessing `httpbin.example.com` like with `curl`. In a real world situation, this is not a problem because because you configure the requested host properly and DNS resolvable. Thus, you use the host's domain name in the URL, for example, `https://httpbin.example.com/status/200`.

To work around this problem for simple tests and demos, use a wildcard `*` value for the host in the `Gateway` and `VirtualService` configurations. For example, if you change your ingress configuration to the following:

{{< text bash >}}
$ kubectl apply -f - <<EOF
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

You can then use `$INGRESS_HOST:$INGRESS_PORT` (e.g., `192.168.99.100:31380`) in the browser URL. For example, `http://192.168.99.100:31380/headers` should display the request headers sent by your browser.

## Understanding what happened

The `Gateway` configuration resources allow external traffic to enter the
Istio service mesh and make the traffic management and policy features of Istio
available for edge services.

In the preceding steps, you created a service inside the service mesh
and exposed an HTTP endpoint of the service to external traffic.

## Cleanup

Delete the `Gateway` configuration, the `VirtualService` and the secret, and shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
