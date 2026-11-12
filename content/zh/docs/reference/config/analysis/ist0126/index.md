---
title: UnknownMeshNetworksServiceRegistry
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当网格网络配置中的某个网络包含一个 Istio 无法识别的 `fromRegistry` 值的端点时，会出现此消息。

已知的服务注册表包括 `Kubernetes`、`External`，以及拥有远程 Secret
（带有 `istio/multiCluster: "true"` 标签的 `Secret`）的远程集群的集群 ID。

## 示例 {#example}

假设一个网格网络配置引用了名为 `cluster2` 的注册表，但不存在 `cluster2` 的远程 Secret：

{{< text yaml >}}
networks:
  network1:
    endpoints:
    - fromRegistry: cluster2
    gateways:
    - address: 192.0.2.10
      port: 15443
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Error [IST0126] (MeshNetworks istio-system/meshnetworks) Unknown service registry cluster2 in network network1
{{< /text >}}

## 如何修复 {#how-to-resolve}

- 确保 `fromRegistry` 的值与远程集群的集群 ID 相同。
- 确保该集群存在远程 Secret。您可以使用
  [`istioctl create-remote-secret`](/zh/docs/reference/commands/istioctl/#istioctl-create-remote-secret)
  创建远程 Secret。

更多信息请参阅[安装多集群](/zh/docs/setup/install/multicluster/)。
