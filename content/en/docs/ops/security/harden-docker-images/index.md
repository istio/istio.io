---
title: Harden Docker Container Images
description: Use hardened container images to reduce Istio's attack surface.
weight: 80
aliases:
    - /help/ops/security/harden-docker-images
---
To ease the process of hardening docker images, Istio provides a set of images based on  [distroless images](https://github.com/GoogleContainerTools/distroless)

{{< warning >}}
The *distroless images* are work-in-progress.
The following images haven't been updated to support *distroless*:

- `proxyproxy`
- `proxy_debug`
- `kubectl`
- `app_sidecar`

For ease of the installation, they are available with a `-distroless` suffix.
{{< /warning >}}

## Install distroless images

Follow the [Installation Steps](/docs/setup/install/operator/) to setup Istio.
Add the option `--set tag={{< istio_full_version >}}-distroless` to use the *distroless images*.

## Benefits

Non-essential executables and libraries are no longer part of the images when using the distroless variant.

- The attack surface is reduced. Include the smallest possible set of vulnerabilities.
- The images are smaller, which allows faster start-up.

See also the [Why should I use distroless images?](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) section in the official distroless README.

{{< warning >}}
Be aware that common debugging tools such as `bash`, `curl`, `netcat`, `tcpdump`, etc. are not available on distroless images.
{{< /warning >}}
