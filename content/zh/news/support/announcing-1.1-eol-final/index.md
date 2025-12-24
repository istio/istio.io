---
title: 对 Istio 1.1 的支持已终止
subtitle: 支持公告
description: Istio 1.1 支持终止公告。
publishdate: 2019-10-21
aliases:
    - /zh/news/2019/announcing-1.1-eol-final
---

正如[先前已公告](/zh/news/support/announcing-1.1-eol/)，对 Istio 1.1 的支持现已正式结束。

由于我们在 [10 月 8 日发布之后](/zh/news/security/istio-security-2019-005)了解到该版本存在安全漏洞，而该漏洞仍处于 1.1 版本支持的期限内，因此我们决定将 1.1 支持期限延长至原始公告之后并发布 [1.1.16](/zh/news/releases/1.1.x/announcing-1.1.16)。然后，我们发现此版本引入了 [HTTP header 计算大小的错误](https://github.com/istio/istio/issues/17735)因此我们决定最后发布一个补丁程序 [1.1.17](/zh/news/releases/1.1.x/announcing-1.1.17) 发布之后，将会彻底关闭 1.1 系列版本。

自此，我们将不再为 Istio 1.1 提供任何安全漏洞或重大缺陷的修复支持。因此，如果您尚未升级，
我们衷心建议您升级到最新版本的 Istio（{{<istio_release_name>}}）。
