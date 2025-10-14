---
title: 发布 1.27.2
linktitle: 1.27.2
subtitle: 补丁发布
description: Istio 1.27.2 补丁发布。
publishdate: 2025-10-13
release: 1.27.2
aliases:
    - /zh/news/announcing-1.27.2
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.1 和 Istio 1.27.2 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **改进** 改进了对引用的 TLS Secret 的访问，要求命名空间和服务帐户匹配（之前仅要求命名空间匹配），
  或者对于 Kubernetes Gateway API 网关具有显式的 `ReferenceGrant`。
  使用主机名地址的网关仍然仅限于命名空间。

- **修复** 修复了多集群中的 goroutine 泄漏，
  其中来自远程集群的数据的 `krt` 集合即使在该集群被移除后仍会保留在内存中。
  ([Issue #57269](https://github.com/istio/istio/issues/57269))

- **修复** 修复了当 `get daemonset` 命令失败并出现“未找到”以外的错误时，
  istio-cni 清理的行为。现在，当无法确定正在进行的是升级、删除还是节点重启时，
  默认不清理 CNI 配置和二进制文件。
  ([Issue #57316](https://github.com/istio/istio/issues/57316))

- **修复** 修复了当设置 `PILOT_SKIP_VALIDATE_TRUST_DOMAIN`
  时集群 waypoint `correct_originate` 的配置。
  ([Issue #56741](https://github.com/istio/istio/issues/56741))

- **修复** 修复了 `istio.io/reroute-virtual-interfaces` 和已弃用的
  `traffic.sidecar.istio.io/kubevirtInterfaces` 注解同时被处理的问题。
  现在，较新的 `reroute-virtual-interfaces` 注解将正确优先。
  ([Issue #57662](https://github.com/istio/istio/issues/57662))

- **修复** 修复了 ztunnel 中的 `ServiceEntry` 解析问题，
  当未设置明确的 `targetPort` 时，将端口名称与 Pod 容器端口进行匹配，
  使行为与 Sidecar 保持一致。
  ([Issue #57713](https://github.com/istio/istio/issues/57713))

- **修复** 修复了 MeshConfig 更改中缺少网关协调的问题。
  ([Issue #57890](https://github.com/istio/istio/issues/57890))

- **移除** 移除了 pilot 和 CNI 之间的 istioctl 安装依赖关系。
  CNI 安装不再依赖于 pilot 的先安装。如果 istio-cni 配置在安装前就已存在
  （使用 istio 拥有的 CNI 配置时可能会出现这种情况），
  则在等待 CNI 准备就绪时，pilot 的安装不会失败，因为 CNI 的安装不再依赖于 pilot。
  ([Issue #57600](https://github.com/istio/istio/issues/57600))
