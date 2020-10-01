---
title: Harden Docker Container Images
description: Use hardened container images to reduce Istio's attack surface.
weight: 80
aliases:
  - /help/ops/security/harden-docker-images
  - /docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
---
To ease the process of hardening docker images, Istio provides a set of images based on  [distroless images](https://github.com/GoogleContainerTools/distroless)

## Install distroless images

Follow the [Installation Steps](/docs/setup/install/istioctl/) to setup Istio.
Add the option `--set tag={{< istio_full_version >}}-distroless` to use the *distroless images*.

{{< text bash >}}
$ istioctl install --set tag={{< istio_full_version >}}-distroless
{{< /text >}}

## Benefits

Non-essential executables and libraries are no longer part of the images when using the distroless variant.

- The attack surface is reduced. Include the smallest possible set of vulnerabilities.
- The images are smaller, which allows faster start-up.

See also the [Why should I use distroless images?](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) section in the official distroless README.

{{< warning >}}
Be aware that common debugging tools such as `bash`, `curl`, `netcat`, `tcpdump`, etc. are not available on distroless images.
{{< /warning >}}
