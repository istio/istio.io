---
title: Istio Installation Options
description: You can follow several paths to install Istio. Choose the path that best suits your needs and platform.
weight: 15
icon: setup
---

Istio offers multiple installation paths depending on your Kubernetes platform.

However, the basic flow is the same regardless of platform:

1. [Review the pod requirements](./reqs/index.md)
1. [Download the latest Istio release](./download-release/index.md)
1. [Prepare your platform for Istio](./platform/_index.md)
1. [Install Istio on your platform](./helm/index.md)

We recommend you install Istio [with the included Helm chart](./helm/index.md).

To quickly test Istio's features, you can:

- Install Istio [on Kubernetes without Helm](./kubernetes/index.md)
- Perform Istio's [minimal installation](./minimal/index.md)

Alternatively, you can follow the instructions specific to your Kubernetes
platform:

- [Alibaba Cloud Kubernetes Container Service](./alibaba/index.md)
- [Ansible](./ansible/index.md)
- [Container Network Interface](./cni/index.md)
- [Google Kubernetes Engine](./gke/index.md)
- [IBM Cloud](./ibm/index.md)

To perform a piecemeal installation of Istio, follow the instructions on
[Customizing the Istio Installation](./custom/index.md).

If you want to perform a multicluster setup, visit our
[Multicluster installation documents](./multicluster/index.md)



{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases:
{{< supported_kubernetes_versions >}}.
{{< /tip >}}

