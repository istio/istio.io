---
title: MicroK8s
description: Instructions to setup MicroK8s for use with Istio.
weight: 20
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/MicroK8s/
    - /docs/setup/kubernetes/platform-setup/MicroK8s/
keywords: [platform-setup,kubernetes,MicroK8s]
---

Follow these instructions to prepare MicroK8s for using Istio.

{{< warning >}}
Administrative privileges are required to run MicroK8s.
{{< /warning >}}

1.  Install the latest version of [MicroK8s](https://microk8s.io) using the command

    {{< text bash >}}
    $ sudo snap install microk8s --classic
    {{< /text >}}

1.  Enable Istio with the following command:

    {{< text bash >}}
    $ microk8s.enable istio
    {{< /text >}}

1.  When prompted, choose whether to enforce mutual TLS authentication among sidecars.
    If you have a mixed deployment with non-Istio and Istio enabled services or you're unsure, choose No.

Please run the following command to check deployment progress:

    {{< text bash >}}
    $ watch microk8s.kubectl get all --all-namespaces
    {{< /text >}}
