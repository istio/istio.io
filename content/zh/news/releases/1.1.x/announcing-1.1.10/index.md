---
title: Istio 1.1.10 发布公告
linktitle: 1.1.10
subtitle: 补丁发布
description: Istio 1.1.10 补丁发布。
publishdate: 2019-06-28
release: 1.1.10
aliases:
    - /zh/about/notes/1.1.10
    - /zh/blog/2019/announcing-1.1.10
    - /zh/news/2019/announcing-1.1.10
    - /zh/news/announcing-1.1.10
---

我们很高兴的宣布 Istio 1.1.10 现在是可用的。更新详情如下。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 消除因 Envoy 重新启动后无法与 SDS 节点代理对话而导致的 503 错误（[Issue 14853](https://github.com/istio/istio/issues/14853)）。
- 解决升级过程中由于 'TLS error: Secret is not supplied by SDS' 导致的错误（[Issue 15020](https://github.com/istio/istio/issues/15020)）。
- 修复由 JWT 格式错误导致的 Istio JWT Envoy 过滤器崩溃（[Issue 15084](https://github.com/istio/istio/issues/15084)）。
