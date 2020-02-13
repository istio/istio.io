---
title: Istio 1.2.5 发布公告
linktitle: 1.2.5
subtitle: 发布补丁
description: Istio 1.2.5 版本发布公告。
publishdate: 2019-08-26
release: 1.2.5
aliases:
    - /zh/about/notes/1.2.5
    - /zh/blog/2019/announcing-1.2.5
    - /zh/news/2019/announcing-1.2.5
    - /zh/news/announcing-1.2.5
---

我们很高兴地宣布 Istio 1.2.5 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## 安全更新{#security-update}

遵循 [ISTIO-SECURITY-2019-003](/zh/news/security/istio-security-2019-003/)
和 [ISTIO-SECURITY-2019-004](/zh/news/security/istio-security-2019-004) 中描述的安全漏洞的修复，我们现在解决内部控制平面的通信问题。这些修复在我们之前的安全版本中不可用，并且我们认为控制平面 `gRPC` 表面更难以开发。

您可以在它们的邮件列表中找到 `gRPC` 的漏洞修复说明，详情参见 [HTTP/2 Security Vulnerabilities](https://groups.google.com/forum/#!topic/grpc-io/w5jPamxdda4)。

## Bug 修复{#bug-fixes}

- 修复了一个 Envoy 错误，打破 `java.net.http.HttpClient` 和其他客户端试图使用 `Upgrade: h2c` 的 header 从 `HTTP/1.1` 到 `HTTP/2` 进行升级，详情参见 ([Issue 16391](https://github.com/istio/istio/issues/16391))。

- 修复了一个在发送超时时出现内存泄漏的问题 ([Issue 15876](https://github.com/istio/istio/issues/15876))。
