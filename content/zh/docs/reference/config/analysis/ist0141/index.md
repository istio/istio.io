---
title: InsufficientPermissions
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 [`istioctl x precheck`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
发现您不具备安装 Istio 所需的权限时，会出现此消息。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Error [IST0141] (Cluster) Missing required permission to create resource clusterroles (...)
{{< /text >}}

## 如何修复 {#how-to-resolve}

向集群管理员申请缺少的权限，或者使用具有集群管理员权限的用户安装 Istio。
您可以使用 `kubectl auth can-i` 检查某项权限：

{{< text bash >}}
$ kubectl auth can-i create clusterroles
{{< /text >}}
