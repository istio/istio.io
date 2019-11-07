---
title: Istio DNS Certificate Management
description: Shows how to provision and manage DNS certificates in Istio.
weight: 90
keywords: [security,certificate]
---

{{< boilerplate experimental-feature-warning >}}

By default, the DNS certificates used by the webhooks of Galley and the sidecar
injector are provisioned and managed by Citadel, which is a large component
that maintains its own signing key and also acts as a CA for Istio.
This task shows how to provision and manage DNS certificates in Istio through
Chiron: a lightweight component that signs certificates
using Kubernetes CA APIs without maintaining its own private key.

## Before you begin

* Install Istio through `istioctl` with DNS certificates configured.

    {{< text bash >}}
    $ cat <<EOF | istioctl manifest apply -f -
    apiVersion: install.istio.io/v1alpha2
    kind: IstioControlPlane
    spec:
      values:
        global:
          certificates:
            - secretName: dns.istio-galley-service-account
              dnsNames: [istio-galley.istio-system.svc, istio-galley.istio-system]
            - secretName: dns.istio-sidecar-injector-service-account
              dnsNames: [istio-sidecar-injector.istio-system.svc, istio-sidecar-injector.istio-system]
    EOF
    {{< /text >}}

* Install [`jq`](https://stedolan.github.io/jq/) for JSON parsing.

## DNS certificate provisioning and management

Istio can provision the DNS names and secret names for the DNS certificates based on a configuration you provide.
The DNS certificates provisioned are signed by the Kubernetes CA and stored in the secrets following your configuration.
Istio also manages the lifecycle of the DNS certificates, including their rotations and regenerations.

## Configure DNS certificates

The [`values-istio-dns-cert.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml)
YAML file contains an example DNS certificate configuration. Within, the `dnsNames` field specifies the DNS
names in a certificate and the `secretName` field specifies the name of the Kubernetes secret used to
store the certificate and the key.

## Check the provision of DNS certificates

Previously, we learned how to configure Istio to generate DNS certificates and store them in secrets
of our choosing. Next, we have to verify that the certificates were provisioned and work properly.

To check that Istio generated the `dns.istio-galley-service-account` DNS certificate as configured in the example,
and that the certificate contains the configured DNS names, we need to get the secret from Kubernetes, parse it,
decode it, and view its text output with the following command:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

The text output should include:

    {{< text plain >}}
    X509v3 Subject Alternative Name:
      DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
    {{< /text >}}

## Regenerate a DNS certificate

Istio can also regenerate DNS certificates that were mistakenly deleted. Next,
we delete a certificate we recently configured and verify that Istio regenerates it automatically.

1.  Delete the secret storing the DNS certificate configured earlier:

    {{< text bash >}}
    $ kubectl delete secret dns.istio-galley-service-account -n istio-system
    {{< /text >}}

1.  To check that Istio regenerated the deleted DNS certificate, and that the certificate
contains the configured DNS names, we need to get the secret from Kubernetes, parse it, decode it,
and view its text output with the following command:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

The output should include:

    {{< text plain >}}
    X509v3 Subject Alternative Name:
      DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
    {{< /text >}}

## Congratulations

You successfully configured Istio to manage DNS certificates.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.
