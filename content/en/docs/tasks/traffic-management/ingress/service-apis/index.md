---
title: Kubernetes Service APIs
description: Describes how to configure the Kubernetes Service APIs with Istio.
weight: 50
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

This task describes how to configure Istio to expose a service outside of the service mesh cluster, using the Kubernetes [Service APIs](https://kubernetes-sigs.github.io/gateway-api/).
These APIs are an actively developed evolution of the Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) APIs.

## Setup

1. Install the Service APIs CRDs:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/service-apis/config/crd?ref=v0.1.0" | kubectl apply -f -
    {{< /text >}}

1. Install Istio, or reconfigure an existing installation to enable the Service APIs controller:

    {{< text bash >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLED_SERVICE_APIS=true
    {{< /text >}}

1. Follow the instructions in the [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) sections of the [Ingress Gateways task](/docs/tasks/traffic-management/ingress/ingress-control/) in order to retrieve the external IP address of your ingress gateway.

## Configuring a Gateway

See the [Service APIs](https://kubernetes-sigs.github.io/gateway-api/) documentation for information about the APIs.

1. Deploy a test application:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Deploy the Service APIs configuration:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: GatewayClass
    metadata:
      name: istio
    spec:
      controller: istio.io/gateway-controller
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-system
    spec:
      gatewayClassName: istio
      listeners:
      - hostname: "*"
        port: 80
        protocol: HTTP
        routes:
          namespaces:
            from: All
          selector:
            matchLabels:
              selected: "yes"
          kind: HTTPRoute
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
      labels:
        selected: "yes"
    spec:
      gateways:
        allow: All
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
              my-added-header: added-value
        forwardTo:
        - serviceName: httpbin
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
