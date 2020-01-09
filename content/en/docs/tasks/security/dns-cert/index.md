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

In certain deployments, you may want to use your own certificate authority
instead of Citadel. In those cases, Citadel ends up being used strictly for
its DNS certificate provisioning functionality. Rather than having to deploy
Citadel at all in this case, you can instead leverage Chiron, a lightweight
component linked with Pilot that signs certificates using the Kubernetes CA APIs without maintaining its own private key.

This task shows how to provision and manage DNS certificates for Istio control
plane components through Chiron. Using this feature has the following advantages:

* More lightweight than Citadel.

* Unlike Citadel, this feature doesn't require maintaining a private signing key, which enhances security.

* Simplified root certificate distribution to TLS clients. Clients no longer need to wait for Citadel to generate and distribute its CA certificate.

## Before you begin

* Install Istio through `istioctl` with DNS certificates configured.
The configuration is read when Pilot starts.

{{< text bash >}}
$ cat <<EOF > ./istio.yaml
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
$ istioctl manifest apply -f ./istio.yaml
{{< /text >}}

* Install [`jq`](https://stedolan.github.io/jq/) for validating the results from running the task.

## DNS certificate provisioning and management

Istio provisions the DNS names and secret names for the DNS certificates based on configuration you provide.
The DNS certificates provisioned are signed by the Kubernetes CA and stored in the secrets following your configuration.
Istio also manages the lifecycle of the DNS certificates, including their rotations and regenerations.

## Configure DNS certificates

The `IstioControlPlane` custom resource used to configure Istio in the `istioctl manifest apply` command, above,
contains an example DNS certificate configuration. Within, the `dnsNames` field specifies the DNS
names in a certificate and the `secretName` field specifies the name of the Kubernetes secret used to
store the certificate and the key.

## Check the provisioning of DNS certificates

After configuring Istio to generate DNS certificates and storing them in secrets
of your choosing, you can verify that the certificates were provisioned and work properly.

To check that Istio generated the `dns.istio-galley-service-account` DNS certificate as configured in the example,
and that the certificate contains the configured DNS names, you need to get the secret from Kubernetes, parse it,
decode it, and view its text output with the following command:

{{< text bash >}}
$ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in /dev/stdin -text -noout
{{< /text >}}

The text output should include:

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}

## Regenerating a DNS certificate

Istio can also regenerate DNS certificates that were mistakenly deleted. Next,
we show how you can delete a recently configured certificate and verify Istio regenerates it automatically.

1. Delete the secret storing the DNS certificate configured earlier:

    {{< text bash >}}
    $ kubectl delete secret dns.istio-galley-service-account -n istio-system
    {{< /text >}}

1. To check that Istio regenerated the deleted DNS certificate, and that the certificate
contains the configured DNS names, you need to get the secret from Kubernetes, parse it, decode it,
and view its text output with the following command:

    {{< text bash >}}
    $ kubectl get secret dns.istio-galley-service-account -n istio-system -o json | jq -r '.data["cert-chain.pem"]' | base64 --decode | openssl x509 -in /dev/stdin -text -noout
    {{< /text >}}

The output should include:

{{< text plain >}}
X509v3 Subject Alternative Name:
  DNS:istio-galley.istio-system.svc, DNS:istio-galley.istio-system
{{< /text >}}
