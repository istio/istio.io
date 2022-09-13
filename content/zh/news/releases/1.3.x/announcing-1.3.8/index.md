---
title: Istio 1.3.8 发布公告
linktitle: 1.3.8
subtitle: 补丁发布
description: Istio 1.3.8 补丁发布。
publishdate: 2022-09-12
release: 1.3.8
aliases:
    - /zh/news/announcing-1.3.8
---

此版本包含了错误修复以提升稳定性。此发行说明描述了 Istio 1.3.7 和 Istio 1.3.8 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 在工作负载实例更新期间，Istio 未更新 `STRICT_DNS` 集群的端点列表的问题。  ([Issue #39505](https://github.com/istio/istio/issues/39505))

- **修复** 指定和不指定虚拟服务超时的服务错误设置超时的问题。  ([Issue #40299](https://github.com/istio/istio/issues/40299))

- **修复** 当与 GCP 元数据服务的连接仅部分中断时，`istiod` 启动非常缓慢的问题。  ([Issue #40601](https://github.com/istio/istio/issues/40601))

- **修复** 在 TCP 之后创建时有时导致 TLS `ServiceEntries` 无法工作的问题。

- **修复** `istioctl analyze` 开始显示无效告警消息的问题。

- **修复** 更新服务条目的主机名时潜在的内存泄漏。
