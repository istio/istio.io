---
title: Istio 1.1.1
publishdate: 2019-03-25
icon: notes
---

该版本包括安全漏洞修复和健壮性改进。本发布说明描述了 Istio 1.1.1 和 Istio 1.0 之间的差异。

{{< relnote_links >}}

## 漏洞修复与小增强

- 配置 Prometheus 监控 Citadel ([Issue 12175](https://github.com/istio/istio/pull/12175))
- 改进 [`istioctl experimental verify-install`](/zh/docs/reference/commands/istioctl/) 命令的输出 ([Issue 12174](https://github.com/istio/istio/pull/12174))
- 降低 SPIFFE URI 丢失服务账户的消息日志级别 ([Issue 12108](https://github.com/istio/istio/issues/12108))
- 修复 SDS 功能在 Unix 系统上损坏的路径 ([Issue 12688](https://github.com/istio/istio/pull/12688))
- 修复 Envoy 追踪中如果父 span 使用空字符串传播子 span 的创建被阻止的问题 ([Envoy Issue 6263](https://github.com/envoyproxy/envoy/pull/6263))
- 为网关端口添加命名空间范围。这修复了两个问题：
    - `IngressGateway` 只关注第一个端口 443 网关定义 ([Issue 11509](https://github.com/istio/istio/issues/11509))
    - Istio `IngressGateway` 因为具有相同端口的不同网关（SDS）发生路由失败([Issue 12500](https://github.com/istio/istio/issues/12500))
- 地点加权负载均衡的五个 Bug 修复：
    - 修复了为每个区域生成空端点的问题 ([Issue 12610](https://github.com/istio/istio/issues/12610))
    - 正确应用地点加权负载均衡配置 ([Issue 12587](https://github.com/istio/istio/issues/12587))
    - Kubernetes 中的地点标签 `istio-locality` 不应该包含 `/`，而应该使用 `.` ([Issue 12582](https://github.com/istio/istio/issues/12582))
    - 修复地点负载均衡崩溃问题 ([Issue 12649](https://github.com/istio/istio/pull/12649))
    - 修复地点负载均衡规范化中的 Bug ([Issue 12579](https://github.com/istio/istio/pull/12579))
- 传播 Envoy 度量服务配置 ([Issue 12569](https://github.com/istio/istio/issues/12569))
- 不应用 `VirtualService` 规则到错误的网关 ([Issue 10313](https://github.com/istio/istio/issues/10313))
