---
title: Istio 1.13.8 发布公告
linktitle: 1.13.8
subtitle: 补丁发布
description: Istio 1.13.8 补丁发布。
publishdate: 2022-09-12
release: 1.13.8
aliases:
    - /zh/news/announcing-1.13.8
---

此版本包含了错误修复以提升稳健性。此发布说明描述了 Istio 1.13.7 和 Istio 1.13.8 之间的区别。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了工作负载实例更新期间 Istio 未更新 `STRICT_DNS` 集群中端点列表的问题。  ([Issue #39505](https://github.com/istio/istio/issues/39505))

- **修复** 修复了一个服务在指定或不指定虚拟服务超时时间时会不正确地设置超时时间的问题。  ([Issue #40299](https://github.com/istio/istio/issues/40299))

- **修复** 修复了当与 GCP 元数据服务的连接仅部分中断时，`istiod` 启动非常缓慢的问题。  ([Issue #40601](https://github.com/istio/istio/issues/40601))

- **修复** 修复了 TCP 之后创建时会造成 TLS `ServiceEntries` 有时不起作用的问题。

- **修复** 修复了 `istioctl analyze` 开始时显示无效警告消息的问题。

- **修复** 修复了更新服务条目的主机名称时可能出现内存泄漏的问题。
