---
title: Downloading the Release
linktitle: Download
description: Download the Istio release and prepare for installation.
weight: 15
aliases:
    - /docs/setup/kubernetes/download-release/
keywords: [kubernetes]
---

## Download and prepare for the installation

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

    * Installation YAML files for Kubernetes in `install/`
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy.
    * The `istio.VERSION` configuration file

1.  Add the `istioctl` client to your `PATH` environment variable, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## Helm Chart Release Repositories

To use the Istio release Helm chart repository, add the Istio release repository as follows:

{{< text bash >}}
$ helm repo add istio.io https://storage.googleapis.com/istio-release/releases/{{< istio_full_version >}}/charts/
{{< /text >}}
