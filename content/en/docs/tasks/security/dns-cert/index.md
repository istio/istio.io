---
title: Istio DNS Certificate Management
description: Shows how to provision and manage DNS certificates in Istio.
weight: 10
keywords: [security,certificate]
---

{{< boilerplate experimental-feature-warning >}}

In existing Istio implementation, the DNS certificates of Galley and Sidecar
Injector are provisioned and managed by Citadel, which is a large component
that manages its own signing key and also acts as a CA for Istio.
This task shows how to provision and manage DNS certificates in Istio through
a lightweight component (called Chiron) linked in Pilot that provisions and manages
DNS certificates through APIs of Kubernetes CA.

## Before you begin

* Create a new Kubernetes cluster to run the example in this tutorial.
The DNS certificates in this task are signed by Kubernetes CA so it requires
a Kubernetes cluster.

## DNS certificate provision and management

At high level, a user configures the DNS names and secret names for the DNS certificates
to be provisioned by Istio. Based on the user configuration, Istio provisions DNS certificates
signed by Kubernetes CA and stores them in the secrets as configured by the user. Istio
also manages the lifecycle of the DNS certificates (e.g., rotation and regeneration).

## Configure DNS certificates and install Istio

1.  The yaml file [`values-istio-dns-cert.yaml`]({{< github_file >}}/install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml)
    contains an example DNS certificate configuration. Install Istio with the DNS certificate configuration
    using [Helm](/docs/setup/install/helm/#prerequisites):

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user="$(gcloud config get-value core/account)"
    $ kubectl create namespace istio-system
    $ helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
    $ helm template \
        --name=istio \
        --namespace=istio-system \
        --values install/kubernetes/helm/istio/example-values/values-istio-dns-cert.yaml \
        install/kubernetes/helm/istio > istio-dns-cert.yaml
    $ kubectl apply -f istio-dns-cert.yaml
    {{< /text >}}

## Check DNS certificates

The DNS certificates generated are stored in the secrets specified in the configuration.

1.  Check that a DNS certificate (e.g., `dns.istio-galley-service-account`) in the example configuration
(`values-istio-dns-cert.yaml`) has been generated and contains the DNS names in the configuration:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in - -text -noout
    {{< /text >}}

The output from the above command should include:

    {{< text plain >}}
    X509v3 Subject Alternative Name:
      DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
    {{< /text >}}

**Congratulations!** You successfully configured Istio to generate DNS certificates.

## Cleanup

After completing this tutorial, you may delete the testing cluster created
at the beginning of this tutorial.
