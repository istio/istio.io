---
title: Istio as a Proxy for External Services
subtitle: Configure Istio ingress gateway to act as a proxy for external services
description: Configure Istio ingress gateway to act as a proxy for external services.
publishdate: 2019-10-15
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,ingress,https,http]
---

The [Control Ingress Traffic](/docs/tasks/traffic-management/ingress) and the
[Ingress Gateway without TLS Termination](/docs/tasks/traffic-management/ingress/ingress-sni-passthrough/) tasks describe
how to configure an ingress gateway to expose services inside the mesh to external traffic. The services can be HTTP or
HTTPS. In the case of HTTPS, the gateway passes the traffic through, without terminating TLS.

This blog post describes how to use the same ingress gateway mechanism of Istio to enable access to external services and
not to applications inside the mesh. This way Istio as a whole can serve just as a proxy server, with the added value of
observability, traffic management and policy enforcement.

The blog post shows configuring access to an HTTP and an HTTPS external service, namely `httpbin.org` and
`edition.cnn.com`.

## Configure an ingress gateway

1.  Define an ingress gateway with a `servers:` section configuring the `80` and `443` ports.
    Ensure `mode:` is set to `PASSTHROUGH` for `tls:` in the port `443`, which instructs the gateway to pass the
    ingress traffic AS IS, without terminating TLS.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: proxy
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - httpbin.org
      - port:
          number: 443
          name: tls
          protocol: TLS
        tls:
          mode: PASSTHROUGH
        hosts:
        - edition.cnn.com
    EOF
    {{< /text >}}

1.  Create service entries for the `httpbin.org` and `edition.cnn.com` services to make them accessible from the ingress
    gateway:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Create a service entry and configure a destination rule for the `localhost` service.
    You need this service entry in the next step as a destination for traffic to the external services from
    applications inside the mesh to block traffic from inside the mesh. In this example you use Istio as a proxy between
    external applications and external services.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: localhost
    spec:
      hosts:
      - localhost.local
      location: MESH_EXTERNAL
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: tls
        protocol: TLS
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: localhost
    spec:
      host: localhost.local
      trafficPolicy:
        tls:
          mode: DISABLE
          sni: localhost.local
    EOF
    {{< /text >}}

1.  Create a virtual service for each external service to configure routing to it. Both virtual services include the
    `proxy` gateway in the `gateways:` section and in the `match:` section for HTTP and HTTPS traffic accordingly.

    Notice the `route:` section for the `mesh` gateway, the gateway that represents the applications inside
    the mesh. The `route:` for the `mesh` gateway shows how the traffic is directed to the `localhost.local` service,
    effectively blocking the traffic.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - httpbin.org
      gateways:
      - proxy
      - mesh
      http:
      - match:
        - gateways:
          - proxy
          port: 80
          uri:
            prefix: /status
        route:
        - destination:
            host: httpbin.org
            port:
              number: 80
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: localhost.local
            port:
              number: 80
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - proxy
      - mesh
      tls:
      - match:
        - gateways:
          - proxy
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: localhost.local
            port:
              number: 443
    EOF
    {{< /text >}}

1.  [Enable Envoy's access logging](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging).

1.  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
    to define the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables.

1.  Access the `httbin.org` service through your ingress IP and port which you stored in the
    `$INGRESS_HOST` and `$INGRESS_PORT` environment variables, respectively, during the previous step.
    Access the `/status/418` path of the `httpbin.org` service that returns the HTTP status
    [418 I'm a teapot](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418).

    {{< text bash >}}
    $ curl $INGRESS_HOST:$INGRESS_PORT/status/418 -Hhost:httpbin.org

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1.  If the Istio ingress gateway is deployed in the `istio-system` namespace, print the gateway's log with the following command:

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | grep 'httpbin.org'
    {{< /text >}}

1. Search the log for an entry similar to:

    {{< text plain >}}
    [2019-01-31T14:40:18.645Z] "GET /status/418 HTTP/1.1" 418 - 0 135 187 186 "10.127.220.75" "curl/7.54.0" "28255618-6ca5-9d91-9634-c562694a3625" "httpbin.org" "34.232.181.106:80" outbound|80||httpbin.org - 172.30.230.33:80 10.127.220.75:52077 -
    {{< /text >}}

1.  Access the `edition.cnn.com` service through your ingress gateway:

    {{< text bash >}}
    $ curl -s --resolve edition.cnn.com:$SECURE_INGRESS_PORT:$INGRESS_HOST https://edition.cnn.com:$SECURE_INGRESS_PORT | grep -o "<title>.*</title>"
    <title>CNN International - Breaking News, US News, World News and Video</title>
    {{< /text >}}

1. If the Istio ingress gateway is deployed in the `istio-system` namespace, print the gateway's log with the following command:

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | grep 'edition.cnn.com'
    {{< /text >}}

1. Search the log for an entry similar to:

    {{< text plain >}}
    [2019-01-31T13:40:11.076Z] "- - -" 0 - 589 17798 1644 - "-" "-" "-" "-" "172.217.31.132:443" outbound|443||edition.cnn.com 172.30.230.33:54508 172.30.230.33:443 10.127.220.75:49467 edition.cnn.com
    {{< /text >}}

## Cleanup

Remove the gateway, the virtual services and the service entries:

{{< text bash >}}
$ kubectl delete gateway proxy
$ kubectl delete virtualservice cnn httpbin
$ kubectl delete serviceentry cnn httpbin-ext localhost
$ kubectl delete destinationrule localhost
{{< /text >}}
