---
title: Installing on Kubernetes
linktitle: Kubernetes
description: Instructions for installing the Istio control plane on Kubernetes and adding virtual machines into the mesh.
weight: 10
aliases:
    - /docs/tasks/installing-istio.html
    - /docs/setup/install-kubernetes.html
    - /docs/setup/kubernetes/quick-start.html
icon: kubernetes
keywords: [kubernetes,install,quick-start,setup,installation]
content_above: true
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

Istio offers [multiple installation flows](/docs/setup/kubernetes/getting-started/) depending on your platform and intended use.
At a high level, the basic flow is the same regardless of platform:

1. [Review the pod requirements](/docs/setup/kubernetes/additional-setup/requirements/)
1. [Prepare your platform for Istio](/docs/setup/kubernetes/platform-setup/)
1. [Download the Istio release](/docs/setup/kubernetes/getting-started/#downloading-the-release)
1. [Install Istio on your platform](/docs/setup/kubernetes/install)

To proceed with your installation, follow our [getting started guide](/docs/setup/kubernetes/getting-started/).
