---
title: Istio 1.1.4 发布
linktitle: 1.1.4
subtitle: 补丁发布
description: Istio 1.1.4 补丁发布.
publishdate: 2019-04-24
release: 1.1.4
aliases:
    - /zh/about/notes/1.1.4
    - /zh/blog/2019/announcing-1.1.4
    - /zh/news/2019/announcing-1.1.4
    - /zh/news/announcing-1.1.4
---

我们很高心的宣布最新的 Istio 1.1.4 版本已经发布 ，具体更改如下。

{{< relnote >}}

## 行为变更 {#behavior-change}

- 更改了 Pilot 的默认行为，以允许流量流向网格外部，即使该流量与内部服务位于同一端口上也是如此，此行为可由 `PILOT_ENABLE_FALLTHROUGH_ROUTE` 环境变量控制。

## Bug 修复 {#bug-fixes}

- 修复了 `ExternalName` 类型服务的出口路由的生成。

- 添加了对配置 Envoy 的空闲连接超时的支持，预防内存或者 IP 端口耗尽 ([Issue 13355](https://github.com/istio/istio/issues/13355)).

- 修复了基于本地负载均衡的故障转移处理中的 Pilot 崩溃错误。

- 修复了在 Pilot 获得自定义证书路径时崩溃的错误。

- 修复了 Pilot 中的一个错误，该错误忽略了用作服务条目主机的短名称 ([Issue 13436](https://github.com/istio/istio/issues/13436))。

- 向 envoy-metrics-service 集群配置中添加了缺失的 `https_protocol_options`。

- 修复了 Pilot 中的一个错误，当路由 fall through 时，Pilot 无法正确处理 https 流量 ([Issue 13386](https://github.com/istio/istio/issues/13386))。

- 修复了之前遗留的一个问题，从 Kubernetes 移除端点后，Pilot 并未从 Envoy 移除端点 ([Issue 13402](https://github.com/istio/istio/issues/13402))。

- 修复了节点代理中的崩溃错误 ([Issue 13325](https://github.com/istio/istio/issues/13325))。

- 添加了缺少的验证，以防止网关名称包含点（.）([Issue 13211](https://github.com/istio/istio/issues/13211))。

- 修复了 [`ConsistentHashLB.minimumRingSize`](/zh/docs/reference/config/networking/destination-rule#LoadBalancerSettings-ConsistentHashLB)
默认为 0 而不是记录的 1024 ([Issue 13261](https://github.com/istio/istio/issues/13261))。

## 小改进 {#small-enhancements}

- 更新了 [Kiali](https://www.kiali.io) 附加组件的最新版本。

- 更新了最新版本的 [Grafana](https://grafana.com)。

- 添加了验证以确保仅使用单个副本部署 Citadel ([Issue 13383](https://github.com/istio/istio/issues/13383))。

- 添加了对配置代理和 Istio 控制平面的日志记录级别的支持 (([Issue 11847](https://github.com/istio/istio/issues/11847))。

- 允许 Sidecar 绑定到任何环回地址，而不仅限于 127.0.0.1 ([Issue 13201](https://github.com/istio/istio/issues/13201))。
