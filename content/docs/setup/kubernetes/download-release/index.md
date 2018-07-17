---
title: Download the Istio release
description: Instructions to download the Istio release.
weight: 10
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
    $ curl -L https://git.io/getLatestIstio | sh -
    {{< /text >}}

1.  Move to the Istio package directory . For example, if the package is
    istio-{{< istio_version >}}.0:

    {{< text bash >}}
    $ cd istio-{{< istio_version >}}.0
    {{< /text >}}

    The installation directory contains:

    * Installation `.yaml` files for Kubernetes in `install/`
    * Sample applications in `samples/`
    * The `istioctl` client binary in the `bin/` directory. `istioctl` is
      used when manually injecting Envoy as a sidecar proxy and for creating
      routing rules and policies.
    * The `istio.VERSION` configuration file

1.  Add the `istioctl` client to your PATH environment variable, on a macOS or
    Linux system:

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}
