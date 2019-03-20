---
title: Istio as a Proxy for External Services
description: Describes how to configure ingress gateway as a proxy for external services.
weight: 9
keywords: [traffic-management,ingress,https,http]
---

The [Control Ingress Traffic](/docs/tasks/traffic-management/ingress) task and the
[Ingress Gateway without TLS Termination](/docs/examples/advanced-gateways/ingress-sni-passthrough/) example describe
how to configure an ingress gateway to expose services inside the mesh to external traffic. The services can be HTTP or
HTTPS. In the case of HTTPS, the gateway passes the traffic through, without terminating TLS.

This example describes how to use the same ingress gateway mechanism of Istio to enable access to external services and
not to applications inside the mesh. This way Istio as a whole can serve just as a proxy server, with the added value of
observability, traffic management and policy enforcement.

The example shows configuring access to an HTTP and an HTTPS external service, namely `httpbin.org` and
`www.google.com`.

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
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
        hosts:
        - www.google.com
    EOF
    {{< /text >}}

1.  Create service entries for the `httpbin.org` and `www.google.com` services to make them accessible from the ingress
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
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
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
        name: https
        protocol: HTTPS
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
      name: google
    spec:
      hosts:
      - www.google.com
      gateways:
      - proxy
      - mesh
      tls:
      - match:
        - gateways:
          - proxy
          port: 443
          sni_hosts:
          - www.google.com
        route:
        - destination:
            host: www.google.com
            port:
              number: 443
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - www.google.com
        route:
        - destination:
            host: localhost.local
            port:
              number: 443
    EOF
    {{< /text >}}

1.  [Enable Envoy's access logging](/docs/tasks/telemetry/logs/access-log/#enable-envoy-s-access-logging).

1.  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports)
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

1.  If Istio is deployed in the `istio-system` namespace, print the Mixer log with the following command:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'httpbin.org'
    {{< /text >}}

1. Search the log for an entry similar to:

    {{< text plain >}}
    {"level":"info","time":"2019-01-31T14:40:18.645864Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"unknown","destinationApp":"","destinationIp":"Iui1ag==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"httpbin.org","destinationWorkload":"unknown","grpcMessage":"","grpcStatus":"","httpAuthority":"httpbin.org","latency":"187.003904ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":327,"referer":"","reporter":"source","requestId":"28255618-6ca5-9d91-9634-c562694a3625","requestSize":0,"requestedServerName":"","responseCode":418,"responseSize":135,"responseTimestamp":"2019-01-31T14:40:18.832770Z","sentBytes":365,"sourceApp":"istio-ingressgateway","sourceIp":"AAAAAAAAAAAAAP//rB7mIQ==","sourceName":"istio-ingressgateway-899f57d65-svpnt","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway","sourcePrincipal":"","sourceWorkload":"istio-ingressgateway","url":"/status/418","userAgent":"curl/7.54.0","xForwardedFor":"10.127.220.75"}
    {{< /text >}}

1.  Access the `www.google.com` service through your ingress gateway:

    {{< text bash >}}
    $ curl -s --resolve www.google.com:$SECURE_INGRESS_PORT:$INGRESS_HOST https://www.google.com:$SECURE_INGRESS_PORT | grep -o "<title>.*</title>"
    <title>Google</title>
    {{< /text >}}

1. If the Istio ingress gateway is deployed in the `istio-system` namespace, print the gateway's log with the following command:

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | grep 'www.google.com'
    {{< /text >}}

1. Search the log for an entry similar to:

    {{< text plain >}}
    [2019-01-31T13:40:11.076Z] "- - -" 0 - 589 17798 1644 - "-" "-" "-" "-" "172.217.31.132:443" outbound|443||www.google.com 172.30.230.33:54508 172.30.230.33:443 10.127.220.75:49467 www.google.com
    {{< /text >}}

1. If Istio is deployed in the `istio-system` namespace, print the Mixer log with the following command:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'www.google.com' | grep '"sourceWorkload":"istio-ingressgateway"'| grep '"connectionEvent":"open"'
    {{< /text >}}

1. Search the log for an entry similar to:

    {{< text plain >}}
    {"level":"info","time":"2019-01-31T13:40:11.309958Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"rNkfhA==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":225,"reporter":"source","requestedServerName":"www.google.com","sentBytes":0,"sourceApp":"istio-ingressgateway","sourceIp":"Cn/cSw==","sourceName":"istio-ingressgateway-899f57d65-svpnt","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway","sourcePrincipal":"","sourceWorkload":"istio-ingressgateway","totalReceivedBytes":225,"totalSentBytes":0}
    {{< /text >}}

## Cleanup

Remove the gateway, the virtual service and the service entries:

{{< text bash >}}
$ kubectl delete gateway proxy
$ kubectl delete virtualservice proxy
$ kubectl delete serviceentry google httpbin-ext localhost
$ kubectl delete destinationrule localhost
{{< /text >}}
