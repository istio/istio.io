---
title: Kubernetes Ingress
description: Describes how to configure a Kubernetes Ingress object to expose a service outside of the service mesh.
weight: 40
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster, using the Kubernetes [Ingress Resource](https://kubernetes.io/docs/concepts/services-networking/ingress/).

{{< tip >}}
Using a [Gateway](/docs/tasks/traffic-management/ingress/ingress-control/), rather than Ingress,
is recommended to make use of the full feature set that Istio offers, such as rich traffic management and security features.
{{< /tip >}}

## Before you begin

Follow the instructions in the [Before you begin](/docs/tasks/traffic-management/ingress/ingress-control/#before-you-begin) and [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) sections of the [Ingress Gateways task](/docs/tasks/traffic-management/ingress/ingress-control/).

## Configuring ingress using an Ingress resource

A [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.

Let's see how you can configure a `Ingress` on port 80 for HTTP traffic.

1.  Create an `Ingress` resource:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
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
          - path: /status
            pathType: Prefix
            backend:
              service:
                name: httpbin
                port:
                  number: 8000
    EOF
    {{< /text >}}

    The `kubernetes.io/ingress.class` annotation is required to tell the Istio gateway controller that it should handle this `Ingress`, otherwise it will be ignored.

1.  Access the _httpbin_ service using _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Note that you use the `-H` flag to set the _Host_ HTTP header to
    "httpbin.example.com". This is needed because the `Ingress` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Next Steps

### TLS

`Ingress` supports [specifying TLS settings](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). This is supported by Istio, but the referenced `Secret` must exist in the namespace of the `istio-ingressgateway` deployment (typically `istio-system`). [cert-manager](/docs/ops/integrations/certmanager/) can be used to generate these certificates.

### Specifying path type

By default, Istio will treat paths as exact matches, unless they end in `/*` or `.*`, in which case they will become prefix matches. Other regular expressions are not supported.

In Kubernetes 1.18, a new field, `pathType`, was added. This allows explicitly declaring a path as `Exact` or `Prefix`.

### Specifying `IngressClass`

In Kubernetes 1.18, a new resource, `IngressClass`, was added, replacing the `kubernetes.io/ingress.class` annotation on the `Ingress` resource. If you are using this resource, you will need to set the `controller` field to `istio.io/ingress-controller`. For example:

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
spec:
  ingressClassName: istio
  rules:
  - host: httpbin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 8000
{{< /text >}}

## Cleanup

Delete the `Ingress` configuration, and shutdown the [httpbin]({{< github_tree >}}/samples/httpbin) service:

{{< text bash >}}
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
