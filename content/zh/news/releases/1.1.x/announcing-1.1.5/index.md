---
title: Istio 1.1.5 发布公告
linktitle: 1.1.5
subtitle: 补丁发布
description: Istio 1.1.5 补丁发布。
publishdate: 2019-05-03
release: 1.1.5
aliases:
    - /zh/about/notes/1.1.5
    - /zh/blog/2019/announcing-1.1.5
    - /zh/news/2019/announcing-1.1.5
    - /zh/news/announcing-1.1.5
---

我们非常高兴的宣布 Istio 1.1.5 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 向 Pilot 增加额外的验证以拒绝网关配置中主机匹配重叠的问题（[Issue 13717](https://github.com/istio/istio/issues/13717)）。
- 根据最新稳定版本的 `istio-cni` 构建，而不是最新的每日构建（[Issue 13171](https://github.com/istio/istio/issues/13171)）。

## 小改进{#small-enhancements}

- 添加日志以帮助诊断主机名解析失败问题（[Issue 13581](https://github.com/istio/istio/issues/13581)）。
- 通过移除对 `busybox` 镜像的不必要依赖，提高安装 `prometheus` 的简便性（[Issue 13501](https://github.com/istio/istio/issues/13501)）。
- 使 Pilot Agent 的证书路径可配置（[Issue 11984](https://github.com/istio/istio/issues/11984)）。
