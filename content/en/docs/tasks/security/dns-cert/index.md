---
title: Istio DNS Certificate Management
description: Shows how to provision and manage DNS certificates in Istio.
weight: 10
keywords: [security,certificate]
---

{{< boilerplate experimental-feature-warning >}}

By default, the DNS certificates of Galley and Sidecar
Injector are provisioned and managed by Citadel, which is a large component
that maintains its own signing key and also acts as a CA for Istio.
This task shows how to provision and manage DNS certificates in Istio through
a lightweight component (called Chiron), which signs certificates
using Kubernetes CA APIs without maintaining its own private key.

## Before you begin

* Create a Kubernetes cluster with Istio installed and the DNS certificate configuration
in [`values-istio-dns-cert.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml).
Istio installation guides can be found [here](/docs/setup/install).

* Install [`jq`](https://stedolan.github.io/jq/) for JSON parsing.

## DNS certificate provisioning and management

You can configure the DNS names and secret names for the DNS certificates
to be provisioned by Istio. Based on the user configuration, Istio provisions DNS certificates
signed by Kubernetes CA and stores them in the secrets as configured by the user.
Istio also manages the lifecycle of the DNS certificates, including their rotations and regenerations.

## Configure DNS certificates

The YAML file [`values-istio-dns-cert.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml)
contains an example DNS certificate configuration, in which `dnsNames` specifies the DNS
names in a certificate and `secretName` specifies the name of the Kubernetes secret to
store the certificate and the key.

## Check DNS certificate provisioning

The DNS certificates generated are stored in the secrets specified in the configuration.

Check that a DNS certificate (e.g., `dns.istio-galley-service-account`) in the example configuration
has been generated and contains the DNS names in the configuration:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

The output from the above command should include:

    {{< text plain >}}
    X509v3 Subject Alternative Name:
      DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
    {{< /text >}}

## Check DNS certificate regeneration

Istio not only provisions a DNS certificate but also manages the lifecycle of the certificate,
e.g., regenerating a certificate mistakenly deleted.

1.  Delete a DNS certificate in the example configuration:

    {{< text bash >}}
    $ kubectl delete secret dns.istio-galley-service-account -n istio-system
    {{< /text >}}

1.  Check that the DNS certificate deleted has been regenerated and contains the DNS names in the configuration:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

The output from the above command should include:

    {{< text plain >}}
    X509v3 Subject Alternative Name:
      DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
    {{< /text >}}

**Congratulations!** You successfully configured Istio to manage DNS certificates.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.
