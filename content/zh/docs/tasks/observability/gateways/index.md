---
title: Remotely Accessing Telemetry Addons
description: This task shows you how to configure external access to the set of Istio telemetry addons.
weight: 99
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
aliases:
 - /zh/docs/tasks/telemetry/gateways/
---

This task shows how to configure Istio to expose and access the telemetry addons outside of
a cluster.

## Configuring remote access

Remote access to the telemetry addons can be configured in a number of different ways. This task covers
two basic access methods: secure (via HTTPS) and insecure (via HTTP). The secure method is *strongly
recommended* for any production or sensitive environment. Insecure access is simpler to set up, but
will not protect any credentials or data transmitted outside of your cluster.

### Option 1: Secure access (HTTPS)

A server certificate is required for secure access. Follow these steps to install and configure
server certificates for a domain that you control.

You may use self-signed certificates instead. Visit our
[Securing Gateways with HTTPS Using Secret Discovery Service task](/docs/tasks/traffic-management/ingress/secure-ingress-sds/)
for general information on using self-signed certificates to access in-cluster services.

{{< warning >}}
This option covers securing the transport layer *only*. You should also configure the telemetry
addons to require authentication when exposing them externally.
{{< /warning >}}

1. [Install cert-manager](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html) to manage certificates automatically.

1. [Install Istio](/docs/setup/install/istioctl) in your cluster and enable the `cert-manager` flag and configure `istio-ingressgateway` to use
the [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration).

    To install Istio accordingly, use the following installation options:

    * `--set values.gateways.enabled=true`
    * `--set values.gateways.istio-ingressgateway.enabled=true`
    * `--set values.gateways.istio-ingressgateway.sds.enabled=true`

    To additionally install the telemetry addons, use the following installation options:

    * Grafana: `--set values.grafana.enabled=true`
    * Kiali: `--set values.kiali.enabled=true`
    * Prometheus: `--set values.prometheus.enabled=true`
    * Tracing: `--set values.tracing.enabled=true`

1. Configure the DNS records for your domain.

    1. Get the external IP address of the `istio-ingressgateway`.

        {{< text bash >}}
        $ kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

    1. Set an environment variable to hold your target domain.

        {{< text bash >}}
        $ TELEMETRY_DOMAIN=<your.desired.domain>
        {{< /text >}}

    1. Point your desired domain at that external IP address via your domain provider.

        The mechanism for achieving this step varies by provider. Here are a few example documentation links:

        * Bluehost: [DNS Management Add Edit or Delete DNS Entries](https://my.bluehost.com/hosting/help/559)
        * GoDaddy: [Add an A record](https://www.godaddy.com/help/add-an-a-record-19238)
        * Google Domains: [Resource Records](https://support.google.com/domains/answer/3290350?hl=en)
        * Name.com: [Adding an A record](https://www.name.com/support/articles/115004893508-Adding-an-A-record)

    1. Verify that the DNS records are correct.

        {{< text bash >}}
        $ dig +short $TELEMETRY_DOMAIN
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

1. Generate a server certificate

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: Certificate
    metadata:
      name: telemetry-gw-cert
      namespace: istio-system
    spec:
      secretName: telemetry-gw-cert
      issuerRef:
        name: letsencrypt
        kind: ClusterIssuer
      commonName: $TELEMETRY_DOMAIN
      dnsNames:
      - $TELEMETRY_DOMAIN
      acme:
        config:
        - http01:
            ingressClass: istio
          domains:
          - $TELEMETRY_DOMAIN
    ---
    EOF
    certificate.certmanager.k8s.io "telemetry-gw-cert" created
    {{< /text >}}

1. Wait until the server certificate is ready.

    {{< text syntax="bash" expandlinks="false" >}}
    $ JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status}{end}{end}' && kubectl -n istio-system get certificates -o jsonpath="$JSONPATH"
    telemetry-gw-cert:Ready=True
    {{< /text >}}

1. Apply networking configuration for the telemetry addons.

    1. Apply the following configuration to expose Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15031
              name: https-grafana
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - grafana-gateway
          http:
          - match:
            - port: 15031
            route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "grafana-gateway" configured
        virtualservice.networking.istio.io "grafana-vs" configured
        destinationrule.networking.istio.io "grafana" configured
        {{< /text >}}

    1. Apply the following configuration to expose Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15029
              name: https-kiali
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - kiali-gateway
          http:
          - match:
            - port: 15029
            route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "kiali-gateway" configured
        virtualservice.networking.istio.io "kiali-vs" configured
        destinationrule.networking.istio.io "kiali" configured
        {{< /text >}}

    1. Apply the following configuration to expose Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15030
              name: https-prom
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - prometheus-gateway
          http:
          - match:
            - port: 15030
            route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "prometheus-gateway" configured
        virtualservice.networking.istio.io "prometheus-vs" configured
        destinationrule.networking.istio.io "prometheus" configured
        {{< /text >}}

    1. Apply the following configuration to expose the tracing service:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15032
              name: https-tracing
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - tracing-gateway
          http:
          - match:
            - port: 15032
            route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "tracing-gateway" configured
        virtualservice.networking.istio.io "tracing-vs" configured
        destinationrule.networking.istio.io "tracing" configured
        {{< /text >}}

1. Visit the telemetry addons via your browser.

    * Kiali: `https://$TELEMETRY_DOMAIN:15029/`
    * Prometheus: `https://$TELEMETRY_DOMAIN:15030/`
    * Grafana: `https://$TELEMETRY_DOMAIN:15031/`
    * Tracing: `https://$TELEMETRY_DOMAIN:15032/`

### Option 2: Insecure access (HTTP)

1. [Install Istio](/docs/setup/install/istioctl) in your cluster with your desired telemetry addons.

    To additionally install the telemetry addons, use the following installation options:

    * Grafana: `--set values.grafana.enabled=true`
    * Kiali: `--set values.kiali.enabled=true`
    * Prometheus: `--set values.prometheus.enabled=true`
    * Tracing: `--set values.tracing.enabled=true`

1. Apply networking configuration for the telemetry addons.

    1. Apply the following configuration to expose Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15031
              name: http-grafana
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - grafana-gateway
          http:
          - match:
            - port: 15031
            route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "grafana-gateway" configured
        virtualservice.networking.istio.io "grafana-vs" configured
        destinationrule.networking.istio.io "grafana" configured
        {{< /text >}}

    1. Apply the following configuration to expose Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15029
              name: http-kiali
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - kiali-gateway
          http:
          - match:
            - port: 15029
            route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "kiali-gateway" configured
        virtualservice.networking.istio.io "kiali-vs" configured
        destinationrule.networking.istio.io "kiali" configured
        {{< /text >}}

    1. Apply the following configuration to expose Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15030
              name: http-prom
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - prometheus-gateway
          http:
          - match:
            - port: 15030
            route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "prometheus-gateway" configured
        virtualservice.networking.istio.io "prometheus-vs" configured
        destinationrule.networking.istio.io "prometheus" configured
        {{< /text >}}

    1. Apply the following configuration to expose the tracing service:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 15032
              name: http-tracing
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - tracing-gateway
          http:
          - match:
            - port: 15032
            route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io "tracing-gateway" configured
        virtualservice.networking.istio.io "tracing-vs" configured
        destinationrule.networking.istio.io "tracing" configured
        {{< /text >}}

1. Visit the telemetry addons via your browser.

    * Kiali: `http://<IP ADDRESS OF CLUSTER INGRESS>:15029/`
    * Prometheus: `http://<IP ADDRESS OF CLUSTER INGRESS>:15030/`
    * Grafana: `http://<IP ADDRESS OF CLUSTER INGRESS>:15031/`
    * Tracing: `http://<IP ADDRESS OF CLUSTER INGRESS>:15032/`

## Cleanup

* Remove all related Gateways:

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* Remove all related Virtual Services:

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* If installed, remove the gateway certificate:

    {{< text bash >}}
    $ kubectl -n istio-system delete certificate telemetry-gw-cert
    certificate.certmanager.k8s.io "telemetry-gw-cert" deleted
    {{< /text >}}
