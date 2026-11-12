---
title: UnsupportedKubernetesVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 [`istioctl x precheck`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
发现您的 Kubernetes 集群版本低于当前 Istio 版本所支持的最低版本时，会出现此消息。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Error [IST0142] (Cluster) The Kubernetes Version "1.30.0" is lower than the minimum version: 1.33
{{< /text >}}

## 如何修复 {#how-to-resolve}

升级您的 Kubernetes 集群，或者使用支持您的 Kubernetes 版本的 Istio 版本。
有关支持的版本，请参阅[支持的版本](/zh/docs/releases/supported-releases/)。
