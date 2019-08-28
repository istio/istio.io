---
title: Docker Desktop
description: Instructions to setup Docker Desktop for use with Istio.
weight: 12
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/docker-for-desktop/
    - /docs/setup/kubernetes/prepare/platform-setup/docker/
    - /docs/setup/kubernetes/platform-setup/docker/
keywords: [platform-setup,kubernetes,docker-desktop]
---

1. To run Istio with Docker Desktop, install a version which contains a supported Kubernetes version
    ({{< supported_kubernetes_versions >}}).

1. If you want to run Istio under Docker Desktop's built-in Kubernetes, you need to increase Docker's memory limit
    under the *Advanced* pane of Docker Desktop's preferences. Set the resources to 8.0 `GB` of memory and 4 `CPUs`.

    {{< image width="60%" link="./dockerprefs.png"  caption="Docker Preferences"  >}}

    {{< warning >}}
    Minimum memory requirements vary.  8 `GB` is sufficent to run
    Istio and Bookinfo.  If you don't have enough memory allocated in Docker Desktop,
    the following errors could occur:

    - image pull failures
    - healthcheck timeout failures
    - kubectl failures on the host
    - general network instability of the hypervisor

    Additional Docker Desktop resources may be freed up using:

    {{< text bash >}}
    $ docker system prune
    {{< /text >}}

    {{< /warning >}}
