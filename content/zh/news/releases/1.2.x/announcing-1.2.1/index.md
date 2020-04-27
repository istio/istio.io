---
title: Istio 1.2.1 发布公告
linktitle: 1.2.1
subtitle: 补丁发布
description: Istio 1.2.1 补丁发布。
publishdate: 2019-06-27
release: 1.2.1
aliases:
    - /zh/about/notes/1.2.1
    - /zh/blog/2019/announcing-1.2.1
    - /zh/news/2019/announcing-1.2.1
    - /zh/news/announcing-1.2.1
---

我们很高兴的宣布 Istio 1.2.1 现在是可用的，具体更新内容如下。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复在安装中生成重复 CRD 的问题（[Issue 14976](https://github.com/istio/istio/issues/14976)）
- 修复禁用 Galley 时无法启动 Mixer 的问题（[Issue 14841](https://github.com/istio/istio/issues/14841)）
- 修复环境变量遮蔽的问题（NAMESPACE 用于监控的命名空间覆盖了 Citadel 的存储命名空间（istio-system）
- 修复升级过程中的 'TLS error: Secret is not supplied by SDS' 错误（[Issue 15020](https://github.com/istio/istio/issues/15020)）

## 次要改进{#minor-enhancements}

- 通过将重试设置为 0，允许用户禁用 Istio 的默认重试（[Issue 14900](https://github.com/istio/istio/issues/14900)）
- 引入 Redis 过滤器（此功能由环境特性标志 `PILOT_ENABLE_REDIS_FILTER` 保护，默认情况下处于禁用状态）
- 将 HTTP/1.0 支持添加到网关配置生成（[Issue 13085](https://github.com/istio/istio/issues/13085)）
- 为 Istio 组件添加了[容忍](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)（[Pull Request 15081](https://github.com/istio/istio/pull/15081)）
