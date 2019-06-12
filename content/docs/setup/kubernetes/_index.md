---
title: Kubernetes
description: Instructions for installing the Istio control plane on Kubernetes and adding virtual machines into the mesh.
weight: 10
aliases:
    - /docs/tasks/installing-istio.html
    - /docs/setup/install-kubernetes.html
    - /docs/setup/kubernetes/quick-start.html
    - /docs/setup/kubernetes/download-release/
    - /docs/setup/kubernetes/download/
icon: kubernetes
keywords: [kubernetes,install,quick-start,setup,installation]
content_above: true
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

Istio offers [multiple installation flows](/docs/setup/kubernetes/getting-started/)
depending on your platform and whether or not you intend to use Istio in production.
At a high level, the basic flow is the same regardless of platform:

1. [Review the pod requirements](/docs/setup/kubernetes/additional-setup/requirements/)
1. [Prepare your platform for Istio](/docs/setup/kubernetes/platform-setup/)
1. [Download the Istio release](#downloading-the-release)
1. [Install Istio on your platform](/docs/setup/kubernetes/install)

## Installing Istio

Choose one of the following installation options, depending on your intended use:

- [Demo installation](/docs/setup/kubernetes/install/kubernetes/):
   This option is ideal if you're new to Istio and just want to try it out.
   It allows you to experiment with many Istio features with modest resource requirements.

- [Custom installation with Helm](/docs/setup/kubernetes/install/helm/):
   This option is ideal to install Istio for production use or for performance evaluation.

- [Supported platform installation](/docs/setup/kubernetes/install/platform/):
   This option is ideal if your platform provides native support for Istio-enabled clusters
   with a [configuration profile](/docs/setup/kubernetes/additional-setup/config-profiles/)
   corresponding to your intended use.

After choosing an option and installing Istio on your cluster, you can deploy
your own application or experiment with some of our [tasks](/docs/tasks/) and [examples](/docs/examples/).

{{< tip >}}
If you're running your own application, make sure to
check the [requirements for pods and services](/docs/setup/kubernetes/additional-setup/requirements/).
{{< /tip >}}

When you're ready to consider more advanced Istio use cases, check out the following resources:

- To install using Istio's Container Network Interface
(CNI) plugin, visit our [CNI guide](/docs/setup/kubernetes/additional-setup/cni/).

- To perform a multicluster setup, visit our
[multicluster installation documents](/docs/setup/kubernetes/install/multicluster/).

- To expand your existing mesh with additional containers or VMs not running on
your mesh's Kubernetes cluster, follow our [mesh expansion guide](/docs/setup/kubernetes/additional-setup/mesh-expansion/).

- To add services requires detailed understanding of sidecar injection. Visit our
[sidecar injection guide](/docs/setup/kubernetes/additional-setup/sidecar-injection/)
to learn more.

## Downloading the release

Istio is installed in its own `istio-system` namespace and can manage
services from all other namespaces.

1.  Go to the [Istio release](https://github.com/istio/istio/releases) page to
    download the installation file corresponding to your OS. On a macOS or
    Linux system, you can run the following command to download and
    extract the latest release automatically:

    {{< text bash >}}
    $ curl -L https://git.io/getLatestIstio | ISTIO_VERSION={{< istio_full_version >}} sh -
    {{< /text >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Installation YAML files for Kubernetes in `install/kubernetes`
    - Sample applications in `samples/`
    - The `istioctl` client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy.

1.  Add the `istioctl` client to your `PATH` environment variable, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. You can enable the [auto-completion option](/docs/ops/setup/istioctl) when working with a bash or ZSH console.

