---
title: 发布 Istio 1.10.5 版本
linktitle: 1.10.5
subtitle: 补丁发布
description: Istio 1.10.5 补丁发布。
publishdate: 2021-10-07
release: 1.10.5
aliases:
    - /zh/news/announcing-1.10.5
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明描述了 Istio 1.10.4 和 Istio 1.10.5 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **改进** 改进了在执行 `istioctl install` 遇到安装失败时，能够提供更多的细节信息。

- **新增** 增加了 Istio Gateway Helm 图表的值，用于配置 ServiceAccount 注解。使能够在 AWS EKS 上开启 [IAM Roles for Service Accounts](https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/iam-roles-for-service-accounts.html) 。
  ([Issue #34837](https://github.com/istio/istio/issues/34837))

- **修复** 修复了一个导致 `istioctl profile diff` 和 `istioctl profile dump` 输出异常信息日志的问题

- **修复** 修复了当分析与虚拟服务关联的网关时， `istioctl analyze` 显示意外的 `IST0132` 消息的问题。
  ([Issue #34653](https://github.com/istio/istio/issues/34653))

- **修复** 修复了产生部署分析器在分析过程中忽略服务命名空间的问题。

- **修复** 修复了 `DestinationRule` 更新不会触发网关上的 `AUTO_PASSTHROUGH` 监听器更新的问题。
  ([Issue #34944](https://github.com/istio/istio/issues/34944))

- **修复** 修复了导致 XDS 客户端断开连接后内存无法释放的问题。
