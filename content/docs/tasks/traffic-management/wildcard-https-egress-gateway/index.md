---
title: Configure Egress Gateway for HTTPS traffic to wildcarded domains
description: Use an SNI proxy in addition to the Envoy instance in the istio-egressgateway for wildcarded domains
keywords: [traffic-management,egress]
weight: 44
---

The [Configure Egress Gateway](/docs/tasks/traffic-management/egress-gateway/) task, the
[Direct HTTPS traffic through an egress gateway](/docs/tasks/traffic-management/egress-gateway/#direct-https-traffic-through-an-egress-gateway)
section described how to configure an Istio egress gateway for HTTPS traffic for specific hostnames, like
`edition.cnn.com`. This task explains how to enable an egress gateway for HTTPS traffic to a set of domains, for
example to `*.wikipedia.org`, without the need to specify each and every host.

## Background

Suppose we want to enable secure egress traffic control in Istio for the `wikipedia.org` sites in all the languages.
Each version of `wikipedia.org` in a particular language has its own hostname, e.g. `en.wikipedia.org` and
`de.wikipedia.org` in the English and the German languages, respectively. We want to enable the egress traffic by common
configuration items for all the _wikipedia_ sites, without the need to specify the sites in all the languages.

## Before you begin

This task assumes you deployed Istio with mutual [mutual TLS Authentication](/docs/tasks/security/mutual-tls/)
enabled. Follow the steps in the [Before you begin](/docs/tasks/traffic-management/egress-gateway/#before-you-begin)
section of the [Configure an Egress Gateway](/docs/tasks/traffic-management/egress-gateway) task.

## Configure an egress gateway for HTTPS traffic

Let's configure an egress gateway for traffic to `*.wikipedia.org`

1.  Define a `ServiceEntry` for `*.wikipedia.org`:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: tls
        protocol: TLS
    EOF
    {{< /text >}}

1.  Verify that your `ServiceEntry` was applied correctly. Send HTTPS requests to
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Create an egress `Gateway` for _*.wikipedia.org_, port 443, protocol TLS and virtual services to direct the traffic
    through the egress gateway and from the egress gateway to the external service.

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: MUTUAL
                clientCertificate: /etc/certs/cert-chain.pem
                privateKey: /etc/certs/key.pem
                caCertificates: /etc/certs/root-cert.pem
                subjectAltNames:
                - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
                sni: placeholder.wikipedia.org # an SNI to match egress gateway's expectation for an SNI
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: wikipedia
            port:
              number: 443
          weight: 100
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - istio-egressgateway
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  Send HTTPS requests to
        [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  Check the statistics of the egress gateway's proxy and see a counter that corresponds to our
    requests to _*.wikipedia.org_. If Istio is deployed in the `istio-system` namespace, the command to print the
    counter is:

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c egressgateway -n istio-system -- curl -s localhost:15000/stats | grep wikipedia.org.upstream_cx_total
    cluster.outbound|443||wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

## Cleanup

1.  Delete the configuration items you created:

    {{< text bash >}}
    $ istioctl delete serviceentry wikipedia
    $ istioctl delete gateway istio-egressgateway
    $ istioctl delete virtualservice direct-wikipedia-through-egress-gateway wikipedia
    $ istioctl delete destinationrule set-sni-for-egress-gateway
    {{< /text >}}

1.  Shutdown the [sleep](https://github.com/istio/istio/tree/{{<branch_name>}}/samples/sleep) service:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}
