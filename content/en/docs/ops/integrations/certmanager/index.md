---
title: cert-manager
description: Information on how to integrate with cert-manager.
weight: 26
keywords: [integration,cert-manager]
aliases:
  - /docs/tasks/traffic-management/ingress/ingress-certmgr/
  - /docs/examples/advanced-gateways/ingress-certmgr/
owner: istio/wg-environments-maintainers
test: no
---

[cert-manager](https://cert-manager.io/) is a tool that automates certificate management.
This can be integrated with Istio gateways to manage TLS certificates.

## Configuration

Consult the [cert-manager installation documentation](https://cert-manager.io/docs/installation/kubernetes/)
to get started. No special changes are needed to work with Istio.

## Usage

### Istio Gateway

cert-manager can be used to write a secret to Kubernetes, which can then be referenced by a Gateway.

1. To get started, configure an `Issuer` resource, following the [cert-manager issuer documentation](https://cert-manager.io/docs/configuration/). `Issuer`s are Kubernetes resources that represent certificate authorities (CAs) that are able to generate signed certificates by honoring certificate signing requests. For example: an `Issuer` may look like:

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: ca-issuer
      namespace: istio-system
    spec:
      ca:
        secretName: ca-key-pair
    {{< /text >}}

    {{< tip >}}
    For a common Issuer type, ACME, a pod and service are created to respond to challenge requests in order to verify the client owns the domain. To respond to those challenges, an endpoint at `http://<YOUR_DOMAIN>/.well-known/acme-challenge/<TOKEN>` will need to be reachable. That configuration may be implementation specific.
    {{< /tip >}}

1. Next, configure a `Certificate` resource, following the
[cert-manager documentation](https://cert-manager.io/docs/usage/certificate/).
The `Certificate` should be created in the same namespace as the `istio-ingressgateway` deployment.
For example, a `Certificate` may look like:

    {{< text yaml >}}
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ingress-cert
      namespace: istio-system
    spec:
      secretName: ingress-cert
      commonName: my.example.com
      dnsNames:
      - my.example.com
      ...
    {{< /text >}}

1. Once we have the certificate created, we should see the secret created in the `istio-system` namespace.
  This can then be referenced in the `tls` config for a Gateway under `credentialName`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1
    kind: Gateway
    metadata:
      name: gateway
    spec:
      selector:
        istio: ingressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: SIMPLE
          credentialName: ingress-cert # This should match the Certificate secretName
        hosts:
        - my.example.com # This should match a DNS name in the Certificate
    {{< /text >}}

### Kubernetes Ingress

cert-manager provides direct integration with Kubernetes Ingress by configuring an
[annotation on the Ingress object](https://cert-manager.io/docs/usage/ingress/).
If this method is used, the Ingress must reside in the same namespace as the
`istio-ingressgateway` deployment, as secrets will only be read within the same namespace.

Alternatively, a `Certificate` can be created as described in [Istio Gateway](#istio-gateway),
then referenced in the `Ingress` object:

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
  annotations:
    kubernetes.io/ingress.class: istio
spec:
  rules:
  - host: my.example.com
    http: ...
  tls:
  - hosts:
    - my.example.com # This should match a DNS name in the Certificate
    secretName: ingress-cert # This should match the Certificate secretName
{{< /text >}}
