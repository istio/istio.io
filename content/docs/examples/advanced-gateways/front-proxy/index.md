---
title: Istio as a Front Proxy for External Services
description: Describes how to configure ingress gateway for external services.
weight: 9
keywords: [traffic-management,ingress,https,http]
---

The [Control Ingress Traffic](/docs/tasks/traffic-management/ingress) task and the [Ingress Gateway without TLS Termination](/docs/examples/advanced-gateways/ingress-sni-passthrough/) example describe how to configure an ingress gateway to expose services inside the mesh to external traffic. The services can be HTTP or HTTPS. In the the case of HTTPS, the gateway performs passthrough, without terminating TLS.

This example describes how use an ingress gateway as a front proxy to services outside of the mesh.

## Configure an ingress gateway

1.  Define a `Gateway` with a `server` section for ports 80 and 443. Note the `PASSTHROUGH` `tls` `mode` on the 443
    port, which instructs the gateway to pass the ingress traffic AS IS, without terminating TLS.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: front-proxy
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
        hosts:
        - "*"
    EOF
    {{< /text >}}

1.  Configure routes for traffic entering via the `Gateway`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: front-proxy
    spec:
      hosts:
      - "*"
      gateways:
      - front-proxy
      tls:
      - match:
        - port: 443
          sni_hosts:
          - www.google.com
        route:
        - destination:
            host: www.google.com
            port:
              number: 443
    EOF
    {{< /text >}}

1.  Create a Service Entry for `www.google.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

1.  Follow the instructions in
    [Determining the ingress IP and ports](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports)
    to define the `SECURE_INGRESS_PORT` and `INGRESS_HOST` environment variables.

1.  Access the www.google.com through your ingress:

    {{< text bash >}}
    $ curl -s --resolve www.google.com:$SECURE_INGRESS_PORT:$INGRESS_HOST https://www.google.com:$SECURE_INGRESS_PORT | grep -o "<title>.*</title>"
    <title>Google</title>
    {{< /text >}}

1.  Check the logs of the `istio-ingressgateway` pods. If the gateway is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain >}}
    [2019-01-31T13:40:11.076Z] "- - -" 0 - 589 17798 1644 - "-" "-" "-" "-" "172.217.31.132:443" outbound|443||www.google.com 172.30.230.33:54508 172.30.230.33:443 10.127.220.75:49467 www.google.com
    {{< /text >}}

1.  Check the Mixer log. If Istio is deployed in the `istio-system` namespace, the command to print the log is:

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'www.google.com' | grep '"sourceWorkload":"istio-ingressgateway"'| grep '"connectionEvent":"open"'
    {{< /text >}}

    You should see a line similar to the following:

    {{< text plain >}}
    {"level":"info","time":"2019-01-31T13:40:11.309958Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"rNkfhA==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":225,"reporter":"source","requestedServerName":"www.google.com","sentBytes":0,"sourceApp":"istio-ingressgateway","sourceIp":"Cn/cSw==","sourceName":"istio-ingressgateway-899f57d65-svpnt","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-ingressgateway","sourcePrincipal":"","sourceWorkload":"istio-ingressgateway","totalReceivedBytes":225,"totalSentBytes":0}
    {{< /text >}}

## Cleanup

Remove the gateway, the virtual service and the service entry:

{{< text bash >}}
$ kubectl delete gateway front-proxy
$ kubectl delete virtualservice front-proxy
$ kubectl delete serviceentry google
{{< /text >}}
