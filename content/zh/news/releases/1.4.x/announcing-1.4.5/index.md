---
title: Istio 1.4.5 发布公告
linktitle: 1.4.5
subtitle: 补丁发布
description: Istio 1.4.5 补丁发布。
publishdate: 2020-02-18
release: 1.4.5
aliases:
    - /zh/news/announcing-1.4.5
---

此版本包含一些 bug 修复程序，可提高稳定性。此发行说明描述了 Istio 1.4.4 和 Istio 1.4.5 之间的区别。

以下修复程序着重于节点重新启动期间发生的各种错误。如果您在使用 Istio CNI，或重启节点，则强烈建议您进行升级。

{{< relnote >}}

## 改进{#improvements}

- **修复** 节点重启触发的 bug，该 bug 会导致 Pod 接收到错误的配置（[Issue 20676](https://github.com/istio/istio/issues/20676)）。
- **改进** [Istio CNI](/zh/docs/setup/additional-setup/cni/) 的健壮性。以前，当节点重新启动时，可能会在安装 CNI 之前就创建新的 Pod，从而导致在没有配置 `iptables` 规则的情况下创建 Pod（[Issue 14327](https://github.com/istio/istio/issues/14327)）。
- **修复** MCP 指标，现在会包含 MCP 响应的大小，而不只是包含请求（[Issue 21049](https://github.com/istio/istio/issues/21049)）。
