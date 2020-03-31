---
title: Ingress (Kubernetes)
description: Describes how to configure a Kubernetes Ingress object to expose a service outside of the service mesh.
weight: 15
keywords: [traffic-management,ingress]
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster, using the Kubernetes [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

{{< tip >}}
Using the [Istio Gateway](/docs/tasks/traffic-management/ingress/ingress-control/), rather than Ingress, is recommended to make use of the full feature set that Istio offers.
{{< /tip >}}

## Before you begin

*   Setup Istio by following the instructions in the [Installation guide](/docs/setup/).

*   Make sure your current directory is the `istio` directory.

{{< boilerplate start-httpbin-service >}}

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

Choose the instructions corresponding to your environment:

{{< tabset category-name="gateway-ip" >}}

{{< tab name="external load balancer" category-value="external-lb" >}}

Follow these instructions if you have determined that your environment has an external load balancer.

Set the ingress IP and ports:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
In certain environments, the load balancer may be exposed using a host name, instead of an IP address.
In this case, the ingress gateway's `EXTERNAL-IP` value will not be an IP address,
but rather a host name, and the above command will have failed to set the `INGRESS_HOST` environment variable.
Use the following command to correct the `INGRESS_HOST` value:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="node port" category-value="node-port" >}}

Follow these instructions if you have determined that your environment does not have an external load balancer,
so you need to use a node port instead.

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
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Configuring ingress using an Istio gateway

A [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.

Let's see how you can configure a `Ingress` on port 80 for HTTP traffic.

1.  Create an Istio `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1beta1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: istio
      name: ingress
    spec:
      rules:
      - host: httpbin.example.com
        http:
          paths:
          - path: /status/*
            backend:
              serviceName: httpbin
              servicePort: 8000
    EOF
    {{< /text >}}

    The `kubernetes.io/ingress.class` annotation is required to tell Istio that it should handle this `Ingress`, otherwise it will be ignored.

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

    Note that you use the `-H` flag to set the _Host_ HTTP header to
    "httpbin.example.com". This is needed because the `Ingress` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    {{< /text >}}

## Next Steps

### TLS

`Ingress` supports [specifying TLS settings](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). This is supported by Istio, but the referenced `Secret` must exist in the namespace of the `istio-ingressgateway` deployment (typical `istio-system`). [cert-manager](/docs/ops/integrations/certmanager/) can be used to generate these certificates.

### Specifying path type

By default, Istio will treat paths as exact matches, unless they end in `/*` or `.*`, in which case they will become prefix matches.

In Kubernetes 1.18, a new field, `pathType`, was added. This allows explicitly declaring a path as `Exact` or `Prefix`

### Specifying `IngressClass`

In Kubneretes 1.18, a new object, `IngressClass`, was added, replacing the `kubernetes.io/ingress.class` annotation on the `Ingress` object. If you are using this object, you will need to set the `controller` field to `istio.io/ingress-controller`. For example,

{{< text yaml >}}
apiVersion: networking.k8s.io/v1beta1
kind: IngressClass
metadata:
  name: istio-test
spec:
  controller: istio.io/ingress-controller
{{< /text >}}

## Cleanup

Delete the `Ingress` configuration, and shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

{{< text bash >}}
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
