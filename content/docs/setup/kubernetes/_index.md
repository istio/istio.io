---
title: Kubernetes
description: Instructions for installing the Istio control plane on Kubernetes and adding virtual machines into the mesh.
weight: 10
type: section-index
aliases:
    - /docs/tasks/installing-istio.html
    - /docs/setup/install-kubernetes.html
icon: kubernetes
keywords: [kubernetes,install,quick-start,setup,installation]
content_above: true
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

## Getting started

Istio offers multiple installation paths depending on your Kubernetes platform.

However, the basic flow is the same regardless of platform:

1. [Review the pod requirements](/docs/setup/kubernetes/additional-setup/requirements/)
1. [Prepare your platform for Istio](/docs/setup/kubernetes/platform-setup/)
1. [Install Istio on your platform](/docs/setup/kubernetes/)

Some platforms additionally require you [download the latest Istio release](/docs/setup/kubernetes/download-release/)
manually.

Whether or not you intend to use Istio on production, is critical when deciding
which installation to perform.

## Evaluating Istio

To quickly test Istio's features, you can:

- Install Istio [on Kubernetes without Helm](/docs/setup/kubernetes/install/kubernetes/)
- Configure Istio's **minimal** profile using the [helm installation guide](/docs/setup/kubernetes/install/helm/)

## Installing Istio for production

We recommend you install Istio for production using the
[Helm Installation guide](/docs/setup/kubernetes/install/helm/).

If you run Kubernetes on a supported platform, you can follow the instructions
specific to your Kubernetes platform:

- [Alibaba Cloud Kubernetes Container Service](/docs/setup/kubernetes/install/platform/alicloud/)
- [Google Kubernetes Engine](/docs/setup/kubernetes/install/platform/gke/)
- [IBM Cloud](/docs/setup/kubernetes/install/platform/ibm/)

If you want your installation to use Istio's Container Network Interface
(CNI) plugin, visit our [CNI guide](/docs/setup/kubernetes/additional-setup/cni/).

If you want to perform a multicluster setup, visit our
[Multicluster installation documents](/docs/setup/kubernetes/install/multicluster/).

## Adding services to your mesh

To expand your existing mesh with additional containers or VMs not running on
your mesh's Kubernetes cluster, follow our [Mesh Expansion guide](/docs/setup/kubernetes/additional-setup/mesh-expansion/).

Adding services requires understanding sidecar injection in detail. Visit our
[Installing the Sidecar guide](/docs/setup/kubernetes/additional-setup/sidecar-injection/)
to learn more.
