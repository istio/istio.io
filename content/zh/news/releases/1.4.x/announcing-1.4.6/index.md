---
title: Istio 1.4.6 发布公告
linktitle: 1.4.6
subtitle: 补丁发布
description: Istio 1.4.6 补丁发布。
publishdate: 2020-03-03
release: 1.4.6
aliases:
    - /zh/news/announcing-1.4.6
---

此版本包含修复针对 [2020 年 3 月 3 日新闻](/zh/news/security/istio-security-2020-003)中所述的安全漏洞。此发行说明描述了 Istio 1.4.5 和 Istio 1.4.6 之间的区别。

{{< relnote >}}

## 安全更新{#security update}

- **ISTIO-SECURITY-2020-003** Envoy中有两个不受控制的资源消耗和两个不正确的访问控制漏洞。

__[CVE-2020-8659](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8659)__: 当代理具有许多小块（即 1 个字节）的 HTTP / 1.1 请求或响应时，Envoy 代理可能会消耗过多的内存。Envoy 为每个传入或传出的块分配一个单独的缓冲区片段，其大小四舍五入到最接近的 4Kb，并且在提交数据后不会释放空的块。如果对等节点速度很慢或无法读取代理数据，则处理具有很多小块的请求或响应可能会导致极高的内存开销。内存开销可能比配置的缓冲区限制大两到三个数量级。

__[CVE-2020-8660](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8660)__: Envoy 代理包含一个 TLS 检查器，客户端仅使用 TLS 1.3 可以绕过该检查器（不将其识别为 TLS 客户端）。由于未检查 TLS 扩展（SNI，ALPN），因此这些连接可能与错误的过滤器链匹配，从而可能绕过某些安全限制。

__[CVE-2020-8661](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8661)__: 响应管道的 HTTP / 1.1 请求时，Envoy 代理可能会消耗过多的内存。对于非法形成的请求，Envoy 发送内部产生的 400 错误，并将其发送到 Network::Connection 缓冲区。如果客户端读取这些响应的速度很慢，则可能会建立大量的响应，并消耗功能上不受限制的内存。这绕过 Envoy 的过载管理器，当 Envoy 接近配置的内存阈值时，该管理器本身将发送内部生成的响应，从而加剧了问题。

__[CVE-2020-8664](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8664)__: 对于 Envoy 代理中的 SDS TLS 验证上下文，仅在首次接收到密钥或密钥值更改时才调用更新回调。这将导致一个竞争条件，引用同一密钥的其他资源（例如，受信任的 CA）将保持未配置状态，直到密钥的值发生更改，从而创建一个可能相当大的窗口，在该窗口中可能发生绕过静态（“默认”）部分的安全检查。

- Istio 1.4.5 及更早版本的 Istio 证书轮换机制由 SDS 实现，并启用了 SDS 和双向 TLS 时，将受此漏洞影响。默认情况下，SDS 是关闭的，并且必须由操作员在 Istio 1.5 之前的所有版本的 Istio 中明确启用。基于 Kubernetes 秘密装载的 Istio 的默认秘密分发实现不受此漏洞影响。
