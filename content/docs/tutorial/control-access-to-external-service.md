---
title: Egress control with Istio
overview: Control access to external services with Istio.

weight: 140

---

1.  Deploy a version of _details v2_ that sends an HTTP request to
    [Google Books APIs](https://developers.google.com/books/docs/v1/getting_started).

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/platform/kube/bookinfo-details-v2.yaml --dry-run -o yaml | kubectl set env --local -f - 'DO_NOT_ENCRYPT=false' -o yaml | kubectl apply -f -
    {{< /text >}}

1.  Direct the traffic destined to the _details_ microservice, to _details version v2_.

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.1/samples/bookinfo/networking/virtual-service-details-v2.yaml
    {{< /text >}}

1.  Configure the traffic to the external service:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: googleapis
    spec:
      hosts:
      - www.googleapis.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
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
        - www.googleapis.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-googleapis
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      trafficPolicy:
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: ISTIO_MUTUAL
            sni: www.googleapis.com    
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-traffic-through-egress-gateway
    spec:
      hosts:
      - www.googleapis.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - www.googleapis.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            port:
              number: 443
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: www.googleapis.com
            port:
              number: 443
          weight: 100    
    EOF
    {{< /text >}}

### Cleanup

{{< text bash >}}
$ kubectl delete deployment details-v2
$ kubectl delete virtualservice details
$ kubectl delete serviceentry googleapis
$ kubectl delete gateway istio-egressgateway
$ kubectl delete destinationrule egressgateway-for-googleapis
$ kubectl delete virtualservice direct-traffic-through-egress-gateway
{{< /text >}}
