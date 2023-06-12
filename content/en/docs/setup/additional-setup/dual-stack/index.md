---
title: Install Istio on a Dual-Stack Kubernetes Cluster
description: Install and use Istio in Dual-Stack mode running on a Dual-Stack Kubernetes cluster
weight: 70
aliases:
    - /docs/setup/kubernetes/install/dual-stack
    - /docs/setup/kubernetes/additional-setup/dual-stack
keywords: [dual-stack]
owner: istio/wg-networking-maintainers
test: yes
---

{{< boilerplate experimental >}}

This guide is intended to be used with:
* Kubernetes 1.23 or later
   * [Configured for dual-stack operations](https://kubernetes.io/docs/concepts/services-networking/dual-stack/)
* Istio 1.17 or later.


## Installation

The installation guide requires changes to both istiod and the injected sidecars. When
installing Istio you will need to modify your `IstioOperator` or Helm values overrides
files with the following when you are installing Istio.

{{< tip >}}
Currently Istio only supports dual stack clusters on initial installation. While it is possible
to migrate from an installation on a dual-stack Kubernetes cluster with the following
parameters not defined, this is not currently supported.
{{< /tip >}}

{< tabset category-name="dualstack" >}

{{< tab name="IstioOperator" category-value="iop" >}}

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_AGENT_DUAL_STACK: "true"
  values:
    pilot:
      env:
        ISTIO_DUAL_STACK: "true"
{{< /text >}}

{{< /tab >}}

{{< tab name="Helm" category-value="helm" >}}

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_AGENT_DUAL_STACK: "true"
values:
  pilot:
    env:
      ISTIO_DUAL_STACK: "true"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< warning >}}
It is not clear if this works well with Ambient.
{{< /warning >}}

## Feedback

Please report any issues found either on [GitHub](https://github.com/istio/istio.io/issues) or
the istio's slack channel, #dualstack.