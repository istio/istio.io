---
title: 发布 Istio 1.9.2 版本
linktitle: 1.9.2
subtitle: 补丁发布
description: Istio 1.9.2 补丁发布。
publishdate: 2021-03-25
release: 1.9.2
aliases:
    - /zh/news/announcing-1.9.2
---

这个版本说明描述了 Istio 1.9.1 和 Istio 1.9.2 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了一个问题。现在在 `EnvoyFilter` 中配置参数时，传输套接字的参数将会被包含在其中。
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **修复** 修复了在 `istiod` 中禁用默认入口控制器后导致日志泄露的问题。
  ([Issue #31336](https://github.com/istio/istio/issues/31336))

- **修复** 修正了一个问题，现在的 Kubernetes API 服务器默认情况下认为是存在于集群本地内。 这意味着任何试图访问 `kubernetes.default.svc` 的 pod 都
将被定向到集群内的服务器。
  ([Issue #31340](https://github.com/istio/istio/issues/31340))

- **修复** 修复了 Azure 平台的元数据处理问题，
以允许 `tagsList` 序列化实例元数据上的标签。
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **修复** 修复了因为 DNS 代理导致 `StatefulSets` 地址不能被负载均衡访问的问题。
  ([Issue #31064](https://github.com/istio/istio/issues/31064))
