---
title: Kubernetes Gateway API
description: Describes how to configure the Kubernetes Gateway API with Istio.
weight: 50
aliases:
    - /docs/tasks/traffic-management/ingress/service-apis/
    - /latest/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster, using the Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/).
These APIs are an actively developed evolution of the Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) APIs.

## Setup

1. Install the Gateway API CRDs:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0-rc1" | kubectl apply -f -
    {{< /text >}}

1. Install Istio:

    {{< text bash >}}
    $ istioctl install
    {{< /text >}}

1. Follow the instructions in the [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) sections of the [Ingress Gateways task](/docs/tasks/traffic-management/ingress/ingress-control/) in order to retrieve the external IP address of your ingress gateway.

## Configuring a Gateway

See the [Gateway API](https://gateway-api.sigs.k8s.io/) documentation for information about the APIs.

1. Deploy a test application:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Deploy the Gateway API configuration:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: GatewayClass
    metadata:
      name: istio
    spec:
      controller: istio.io/gateway-controller
    ---
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-system
    spec:
      gatewayClassName: istio
      listeners:
      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-system
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: Prefix
            value: /get
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
        backendRefs:
        - name: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  Access the _httpbin_ service using _curl_:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    Note the use of the `-H` flag to set the _Host_ HTTP header to
    "httpbin.example.com". This is needed because the `HTTPRoute` is configured to handle "httpbin.example.com",
    but in your test environment you have no DNS binding for that host and are simply sending your request to the ingress IP.

1.  Access any other URL that has not been explicitly exposed. You should see an HTTP 404 error:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}
