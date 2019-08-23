---
title: MicroK8s
description: Instructions to setup microK8s for use with Istio.
weight: 20
skip_seealso: true
aliases:
    - /docs/setup/kubernetes/prepare/platform-setup/microK8s/
    - /docs/setup/kubernetes/platform-setup/microK8s/
keywords: [platform-setup,kubernetes,microK8s]
---

Follow these instructions to prepare microK8s for using Istio.

{{< warning >}}
Administrative privileges are required to run microK8s.
{{< /warning >}}

1.  Install the latest version of
    [microK8s](https://microK8s.io) using the command {{< text bash >}}
    $ sudo snap install microk8s --classic
    {{< /text >}}

1.  Enable Istio with the following command:

    {{< text bash >}}
    $ microk8s.enable istio
    {{< /text >}}

1.  Choose whether to enforce mutual TLS authentication among sidecars?
    If you have a mixed deployment with non-Istio and Istio enabled services 
    or you're unsure, choose No. And We're done.
    
