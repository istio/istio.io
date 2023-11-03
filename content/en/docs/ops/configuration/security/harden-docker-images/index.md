---
title: Harden Docker Container Images
description: Use hardened container images to reduce Istio's attack surface.
weight: 80
aliases:
  - /help/ops/security/harden-docker-images
  - /docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
status: Beta
---

Istio's [default images](https://hub.docker.com/r/istio/base) are based on `ubuntu` with some extra tools added.
An alternative image based on [distroless images](https://github.com/GoogleContainerTools/distroless) is also available.

These images strip all non-essential executables and libraries, offering the following benefits:

- The attack surface is reduced as they include the smallest possible set of vulnerabilities.
- The images are smaller, which allows faster start-up.

See also the [Why should I use distroless images?](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) section in the official distroless README.

## Install distroless images

Follow the [Installation Steps](/docs/setup/install/istioctl/) to set up Istio.
Add the `variant` option to use the *distroless images*.

{{< text bash >}}
$ istioctl install --set values.global.variant=distroless
{{< /text >}}

If you are only interested in using distroless images for injected proxy images, you can also use the `proxyImage` field in [Proxy Config](/docs/reference/config/networking/proxy-config/#ProxyImage).
Note the above `variant` flag will automatically set this for you.

## Debugging

Distroless images are missing all debugging tools (including a shell!).
While great for security, this limits the ability to do ad-hoc debugging using `kubectl exec` into the proxy container.

Fortunately, [Ephemeral Containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) can help here.
`kubectl debug` can attach a temporary container to a pod.
By using an image with extra tools, we can debug as we used to:

{{< text shell >}}
$ kubectl debug --image istio/base --target istio-proxy -it app-65c6749c9d-t549t
Defaulting debug container name to debugger-cdftc.
If you don't see a command prompt, try pressing enter.
root@app-65c6749c9d-t549t:/# curl example.com
{{< /text >}}

This deploys a new ephemeral container using the `istio/base`.
This is the same base image used in non-distroless Istio images, and contains a variety of tools useful to debug Istio.
However, any image will work.
The container is also attached to the process namespace of the sidecar proxy (`--target istio-proxy`) and the network namespace of the pod.
