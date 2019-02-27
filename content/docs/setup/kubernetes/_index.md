---
title: Kubernetes
description: Instructions for installing the Istio control plane on Kubernetes and adding virtual machines into the mesh.
weight: 10
type: section-index
aliases:
    - /docs/tasks/installing-istio.html
    - /docs/setup/install-kubernetes.html
icon: kubernetes
keywords: [kubernetes, install, quick start, setup, installation]
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

Istio offers multiple installation paths depending on your Kubernetes platform.

However, the basic flow is the same regardless of platform:

1. [Review the pod requirements](./additional-setup/requirements/index.md)
1. [Prepare your platform for Istio](./platform/_index.md)
1. [Download the latest Istio release](./download-release/index.md)
1. [Install Istio on your platform](./helm/index.md)

Whether or not you intend to use Istio on production, is critical when deciding
which installation to perform.

## Evaluating Istio

To quickly test Istio's features, you can:

- Install Istio [on Kubernetes without Helm](./install/kubernetes/index.md)
- Perform Istio's [minimal installation](./install/minimal/index.md)

## Installing Istio for production

We recommend you install Istio for production using the
[Helm Installation guide](./install/helm/index.md)

If you run Kubernetes on a supported platform, you can follow the instructions
specific to your Kubernetes platform:

- [Alibaba Cloud Kubernetes Container Service](./install/alibaba/index.md)
- [Container Network Interface](./install/cni/index.md)
- [Google Kubernetes Engine](./install/gke/index.md)
- [IBM Cloud](./install/ibm/index.md)

If you want to perform a multicluster setup, visit our
[Multicluster installation documents](./multicluster/_index.md)

## Additional setup resources

Depending on your use case and platform, you might require additional setup.

To expand your existing mesh with additional containers or VMs, follow our
[Mesh Expansion guide](./additional-setup/mesh-expansion/index.md).

To perform a piecemeal installation of Istio, follow the instructions on
[Customizing the Istio Installation guide](./additional-setup/customize/index.md).

To learn more about sidecar injection, visit our
[Installing the Sidecar guide](./additional-setup/sidecars/index.md)
