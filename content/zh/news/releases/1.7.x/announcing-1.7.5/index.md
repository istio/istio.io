---
title: 发布 Istio 1.7.5 版本
linktitle: 1.7.5
subtitle: 补丁发布
description: Istio 1.7.5 补丁发布。
publishdate: 2020-11-19
release: 1.7.5
aliases:
- /zh/news/announcing-1.7.5
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.7.4 和 Istio 1.7.5 之间的不同之处。

{{< relnote >}}

## 改动{#changes}

- **修复** 试验代理应用程序探针连接泄漏的问题。([Issue #27726](https://github.com/istio/istio/issues/27726))

- **修复** `install-cni` 如何应用 `istio-cni` 插件配置。以前，新的配置会被添加到列表中。在插入新的插件之前，进行了更改，从 CNI 配置中删除现有的 `istio-cni` 插件。([Issue #27771](https://github.com/istio/istio/issues/27771))

- **修复** 当一个节点有多个 IP 地址（例如，网格扩展方案中的虚拟机）时。Istio Proxy 现在会将入站监听器绑定到列表中第一个适用的地址，而不是最后一个。([Issue #28269](https://github.com/istio/istio/issues/28269))

- **修复** 当代理配置为 `FILE_MOUNTED_CERTS` 时，Istio 将不运行网关私密获取程序。

- **修复** 多集群 `EnvoyFilter` 在 Envoy 的 API 发生基本变化后才能进行有效的配置的问题。([Issue #27909](https://github.com/istio/istio/issues/27909))

- **修复** 在从 Istio 1.6 升级到 1.7 的过程中，导致错误短暂增加的问题。之前，xDS 版本会自动从 xDS v2 升级到 xDS v3，导致从 Istio 1.6 升级到 Istio 1.7 出现停机。这一问题已被修复，使升级不再导致停机。需要注意的是，从 Istio 1.7.x 升级到 Istio 1.7.5 仍然会导致任何现有的 1.6 代理的停机，在这种情况下，您可以在 Istiod 中设置 `PILOT_ENABLE_TLS_XDS_DYNAMIC_TYPES` 环境变量为 `false`，以保持之前的行为。([Issue #28120](https://github.com/istio/istio/issues/28120))

- **修复** 当虚拟机 Sidecar 连接到 `istiod`，但后来注册了 `WorkloadEntry` 时，虚拟机上缺少监听器的问题。([Issue #28743](https://github.com/istio/istio/issues/28743))

### 升级通知{#upgrade-notice}

当把的Istio数据平面从 1.7.x（其中 x<5）升级到 1.7.5 或更新版本时，您可能观察到网关和 Sidecar 之间的连接问题，或者 Sidecar 之间的连接问题的，日志中出现 503 错误。这种情况发生在 1.7.5 以上的代理发送 HTTP 1xx 或 204 响应代码的标头，1.7.x 的代理拒绝接受。要解决这个问题，请尽快将您的所有代理（网关和 Sidecar）升级到 1.7.5+。([Issue 29427](https://github.com/istio/istio/issues/29427), [更新信息](https://github.com/istio/istio/pull/28450))
