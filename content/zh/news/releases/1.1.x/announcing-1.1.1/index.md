---
title: Istio 1.1.1 发布公告 
linktitle: 1.1.1
subtitle: 补丁发布
description: Istio 1.1.1 补丁发布。
publishdate: 2019-03-25
release: 1.1.1
aliases:
    - /zh/about/notes/1.1.1
    - /zh/blog/2019/announcing-1.1.1
    - /zh/news/2019/announcing-1.1.1
    - /zh/news/announcing-1.1.1
---

我们非常高兴的宣布 Istio 1.1.1 发布，请浏览下面的变更说明：

{{< relnote >}}

## Bug 修复和一些较小的增强{#bug-fixes-and-minor-enhancements}

- 配置 Prometheus 以监控 Citadel。（[Issue 12175](https://github.com/istio/istio/pull/12175)）
- 改善 [`istioctl verify-install`](/zh/docs/reference/commands/istioctl/#istioctl-verify-install) 命令的输出。（[Issue 12174](https://github.com/istio/istio/pull/12174)）
- 降低 SPIFFE URI 的缺少服务账户消息的日志级别。（[Issue 12108](https://github.com/istio/istio/issues/12108)）
- 修复 opt-in SDS 功能 Unix 域套接字路径错误的问题。（[Issue 12688](https://github.com/istio/istio/pull/12688)）
- 修复 Envoy 追踪在父级 span 传播空字符串时无法创建子 span 的问题。（[Envoy Issue 6263](https://github.com/envoyproxy/envoy/pull/6263)）
- 将名称空间作用域添加到网关的 “port” 名称。这解决了两个问题：
    - `IngressGateway` 仅遵守第一个端口为 443 的网关定义。（[Issue 11509](https://github.com/istio/istio/issues/11509)）
    - `IngressGateway` 路由错误，两个不同网关使用同一个端口名（SDS）（[Issue 12500](https://github.com/istio/istio/issues/12500)）
- 本地负载均衡权重相关的五个错误修复：
    - 修复导致每个位置的端点为空的错误。（[Issue 12610](https://github.com/istio/istio/issues/12610)）
    - 正确的应用本地负载均衡权重配置。（[Issue 12587](https://github.com/istio/istio/issues/12587)）
    - Kubernetes 中的位置标签 `istio-locality` 不应包含 `/`，应使用 `.`。（[Issue 12582](https://github.com/istio/istio/issues/12582)）
    - 修复了本地负载均衡方面的崩溃问题。（[Issue 12649](https://github.com/istio/istio/pull/12649)）
    - 修复了本地负载均衡标准化中的错误。（[Issue 12579](https://github.com/istio/istio/pull/12579)）
- 传播 Envoy 度量服务配置。（[Issue 12569](https://github.com/istio/istio/issues/12569)）
- 不应用 `VirtualService` 规则到错误的网关。（[Issue 10313](https://github.com/istio/istio/issues/10313)）
