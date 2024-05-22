---
title: Getting Started
description: How to deploy and install Istio in ambient mode.
weight: 2
aliases:
  - /docs/ops/ambient/getting-started
  - /latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
test: yes
---

This guide lets you quickly evaluate Istio's {{< gloss "ambient" >}}ambient mode{{< /gloss >}}. These steps require you to have a {{< gloss >}}cluster{{< /gloss >}} running a
[supported version](/docs/releases/supported-releases#support-status-of-istio-releases) of Kubernetes ({{< supported_kubernetes_versions >}}).
You can install Istio ambient mode on [any supported Kubernetes platform](/docs/setup/platform-setup/), but this guide will assume the use of [kind](https://kind.sigs.k8s.io/) for simplicity.

{{< tip >}}
Note that ambient mode currently requires the use of [istio-cni](/docs/setup/additional-setup/cni) to configure Kubernetes nodes, which must run as a privileged pod. Ambient mode is compatible with every major CNI that previously supported sidecar mode.
{{< /tip >}}

Follow these steps to get started with Istio's ambient mode:

1. [Download and install](#download)
1. [Deploy the sample application](#bookinfo)
1. [Adding your application to ambient](#addtoambient)
1. [Secure application access](#secure)
1. [Control traffic](#control)
1. [Uninstall](#uninstall)
