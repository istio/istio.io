---
title: Istio 1.11.3 发布公告
linktitle: 1.11.3
subtitle: 补丁发布
description: Istio 1.11.3 补丁发布。
publishdate: 2021-09-23
release: 1.11.3
aliases:
    - /zh/news/announcing-1.11.3
---

此版本包含一些 bug 修复用以提高程序的健壮性。同时此发布说明也描述了 Istio 1.11.2 和 Istio 1.11.3 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **更新** 更新了允许指定的 NICs 绕过 Istio iptables 中的流量捕获。
  ([Issue #34753](https://github.com/istio/istio/issues/34753))

- **新增** 为 Istio Gateway Helm charts 新增了一个 values，用于配置 `ServiceAccount` 上的注释。可用于在 AWS EKS 上启用[服务帐户 IAM 角色](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/iam-roles-for-service-accounts.html)。

- **修复** 修复了 `istioctl analyze` 命令在分析虚拟服务网关时不输出 [IST0132] 消息的问题。
  ([Issue #34653](https://github.com/istio/istio/issues/34653))

- **修复** 修复了在 sidecar 的出口监听器具有端口的情况下使用 Service 的指针地址来获取其实例的错误。

- **修复** 修复了 "image: auto" 分析器无法考虑 Deployment 命名空间的错误。
  ([Issue #34929](https://github.com/istio/istio/issues/34929))

- **修复** 修复了 `istioctl x workload` 命令输出用以设置正确 `discoveryAddress` 的修订控制平面。
  ([Issue #34058](https://github.com/istio/istio/issues/34058))

- **修复** 修复了当网关 spec 中没有选择器时，网关分析器的消息报告问题。
  ([Issue #35093](https://github.com/istio/istio/issues/35093))

- **修复** 修复了当 XDS 客户端断开连接后，内存无法释放的问题。

- **修复** 修复了 `VirtualServices` 在不同命名空间中存在多个相同名称时发生的问题。
  ([Issue #35127](https://github.com/istio/istio/issues/35127))
