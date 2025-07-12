---
title: Download the Istio release 
description: Get the files required to install and explore Istio.
weight: 30
keywords: [profiles,install,release,istioctl]
owner: istio/wg-environments-maintainers
test: n/a
---

Each Istio release includes a _release archive_ which contains:

- the [`istioctl`](/es/docs/ops/diagnostic-tools/istioctl/) binary
- [installation profiles](/es/docs/setup/additional-setup/config-profiles/) and [Helm charts](/es/docs/setup/install/helm)
- samples, including the [Bookinfo](/es/docs/examples/bookinfo/) application

A release archive is built for each supported processor architecture and operating system.

## Download Istio {#download}

1.  Go to the [Istio release]({{< istio_release_url >}}) page to
    download the installation file for your OS, or download and
    extract the latest release automatically (Linux or macOS):

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    The command above downloads the latest release (numerically) of Istio.
    You can pass variables on the command line to download a specific version
    or to override the processor architecture.
    For example, to download Istio {{< istio_full_version >}} for the x86_64 architecture,
    run:

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  Move to the Istio package directory. For example, if the package is
    `istio-{{< istio_full_version >}}`:

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    The installation directory contains:

    - Sample applications in `samples/`
    - The [`istioctl`](/es/docs/reference/commands/istioctl) client binary in the
      `bin/` directory.

1.  Add the `istioctl` client to your path (Linux or macOS):

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}
