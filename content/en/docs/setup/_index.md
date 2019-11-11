---
title: Setup
description: Instructions for installing the Istio control plane on Kubernetes and adding virtual machines into the mesh.
weight: 15
icon: setup
aliases:
    - /docs/tasks/installing-istio.html
    - /docs/setup/install-kubernetes.html
    - /docs/setup/kubernetes/quick-start.html
    - /docs/setup/kubernetes/download-release/
    - /docs/setup/kubernetes/download/
    - /docs/setup/kubernetes/
keywords: [kubernetes,install,quick-start,setup,installation]
list_below: true
---

{{< tip >}}
Istio {{< istio_version >}} has been tested with these Kubernetes releases: {{< supported_kubernetes_versions >}}.
{{< /tip >}}

Visit our [getting started guide](/docs/setup/getting-started/) to
learn how to evaluate and try Istio's basic features quickly.

Istio offers multiple installation flows
depending on your platform and whether or not you intend to use Istio in production.
At a high level, the basic flow is the same regardless of platform:

1. [Review the pod requirements](/docs/setup/additional-setup/requirements/)
1. [Prepare your platform for Istio](/docs/setup/platform-setup/)
1. [Download the Istio release](#downloading-the-release)
1. [Install Istio on your platform](#installing-istio)

## Downloading the release

Download the Istio release which includes installation files, samples and a command line utility.

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file corresponding to your OS. Alternatively, on a macOS or
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
    - The [`istioctl`](/docs/reference/commands/istioctl) client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy.

1.  Add the `istioctl` client to your path, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. You can optionally enable the [auto-completion option](/docs/ops/diagnostic-tools/istioctl#enabling-auto-completion) when working with a bash or ZSH console.

## Installing Istio

Istio is installed in its own `istio-system` namespace and can manage
services from all other namespaces. Choose one of the following installation options, depending on your intended use:

- [Demo installation](/docs/setup/install/kubernetes/):
   This option is ideal if you're new to Istio and just want to try it out.
   It allows you to experiment with many Istio features with modest resource requirements.

- [Custom installation with Helm](/docs/setup/install/helm/):
   This option is ideal to install Istio for production use or for performance evaluation.

- Cloud provider installation instructions:
   This option is ideal if your cloud provider has native support for Istio-enabled clusters
   with a [configuration profile](/docs/setup/additional-setup/config-profiles/)
   corresponding to your intended use. Refer to your cloud provider's documentation for details.

After choosing an option and installing Istio on your cluster, you can deploy
your own applications or experiment with some of our [tasks](/docs/tasks/) and [examples](/docs/examples/).

When you're ready to consider more advanced Istio use cases, check out the following resources:

- To install using Istio's Container Network Interface
(CNI) plugin, visit our [CNI guide](/docs/setup/additional-setup/cni/).

- To perform a multicluster setup, visit our
[multicluster installation documents](/docs/setup/install/multicluster/).

- To add VMs or additional containers not running on your mesh's cluster to your
  existing mesh, see our [VM-related tasks](/docs/examples/virtual-machines/).

- To add services using sidecar injection, see our
[sidecar injection guide](/docs/setup/additional-setup/sidecar-injection/)
to learn more.
