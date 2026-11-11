---
title: UnsupportedKubernetesVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when [`istioctl x precheck`](/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
finds that the version of your Kubernetes cluster is lower than the minimum version that this
version of Istio supports.

## An example

You will receive a message like this:

{{< text plain >}}
Error [IST0142] (Cluster) The Kubernetes Version "1.30.0" is lower than the minimum version: 1.33
{{< /text >}}

## How to resolve

Upgrade your Kubernetes cluster, or use a version of Istio that supports your version of Kubernetes.
Refer to [Supported Releases](/docs/releases/supported-releases/) for the supported versions.
