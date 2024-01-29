---
title: Managing In-Mesh Certificates
linktitle: Managing In-Mesh Certificates
description: How to configure certificates within your mesh.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers,istio/wg-environments-maintainers
test: n/a
---

{{< boilerplate experimental >}}

Many users need to manage the types of the certificates used within their environment. For example,
some users require the use of Elliptical Curve Cryptography (ECC) while others may need to use a
stronger bit length for RSA certificates. Configuring certificates within your environment can be
a daunting task for most users.

This document is only intended to be used for in-mesh communication. For managing certificates at
your Gateway, see the [Secure Gateways](/docs/tasks/traffic-management/ingress/secure-ingress/) document.
For managing the CA used by istiod to generate workload certificates, see
the [Plugin CA Certificates](/docs/tasks/security/cert-management/plugin-ca-cert/) document.

## istiod

When Istio is installed without a root CA certificate, istiod will generate a self-signed
CA certificate using RSA 2048.

To change the self-signed CA certificate's bit length, you will need to modify either the IstioOperator manifest provided to
istioctl or the values file used during the Helm installation of the istio-discovery chart.

{{< tip >}}
While there are many environment variables that can be changed for
[pilot-discovery](/docs/reference/commands/pilot-discovery/), this document will only
outline some of them.
{{< /tip >}}

{{< tabset category-name="certificates" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    pilot:
      env:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
pilot:
  env:
    CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Sidecars

Since sidecars manage their own certificates for in-mesh communication, the sidecars
are responsible for managing their private keys and generated Certificate Signing Request (CSRs). The sidecar
injector needs to be modified to inject the environment variables to be used for
this purpose.

{{< tip >}}
While there are many environment variables that can be changed for
[pilot-agent](/docs/reference/commands/pilot-agent/), this document will only
outline some of them.
{{< /tip >}}

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
{{< /text >}}

{{< /tab >}}

{{< tab name="Annotation" category-value="annotation" >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          CITADEL_SELF_SIGNED_CA_RSA_KEY_SIZE: 4096
    spec:
      ...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Signature Algorithm

By default, the sidecars will create RSA certificates. If you want to change it to
ECC, you need to set `ECC_SIGNATURE_ALGORITHM` to `ECDSA`.

{{< tabset category-name="gateway-install-type" >}}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ECC_SIGNATURE_ALGORITHM: "ECDSA"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Only P256 and P384 are supported via `ECC_CURVE`.

If you prefer to retain RSA signature algorithms and want to modify the RSA key size,
you can change the value of `WORKLOAD_RSA_KEY_SIZE`.
