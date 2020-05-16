---
title: Istio 1.1.9 发布公告
linktitle: 1.1.9
subtitle: 补丁发布
description: Istio 1.1.9 补丁发布。
publishdate: 2019-06-17
release: 1.1.9
aliases:
    - /zh/about/notes/1.1.9
    - /zh/blog/2019/announcing-1.1.9
    - /zh/news/2019/announcing-1.1.9
    - /zh/news/announcing-1.1.9
---

我们非常高兴的宣布 Istio 1.1.9 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 防止将太大的字符串发送到 Prometheus（[Issue 14642](https://github.com/istio/istio/issues/14642)）。
- 如果在续订期间遇到传输错误，将重用先前缓存的 JWT 公共密钥（[Issue 14638](https://github.com/istio/istio/issues/14638)）。
- 绕过 HTTP OPTIONS 方法的 JWT 身份验证以支持 CORS 请求。
- 修复 Mixer 过滤器导致的 Envoy 崩溃（[Issue 14707](https://github.com/istio/istio/issues/14707)）。

## 小改进{#small-enhancements}

- 将加密签名验证功能公开给 Envoy 的 `Lua` 过滤器（[Envoy Issue 7009](https://github.com/envoyproxy/envoy/issues/7009)）。
