---
title: HBONE
description: 了解 Istio 的安全隧道协议。
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

**HBONE**（HTTP Based Overlay Network Encapsulation，基于 HTTP 的覆盖网络封装）
是 Istio 组件之间使用的安全隧道协议。HBONE 是 Istio 特定的术语。
它是一种通过单个 mTLS 加密网络连接（加密隧道）透明地多路复用与许多不同应用程序连接相关的 TCP 流的机制。

在 Istio 当前的实现中，HBONE 协议包含三个开放标准：

- [HTTP/2](https://httpwg.org/specs/rfc7540.html)
- [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT)
- [双向 TLS（mTLS）](https://datatracker.ietf.org/doc/html/rfc8446)

HTTP CONNECT 用于建立隧道连接，mTLS 用于保护和加密该连接，
HTTP/2 用于在单个安全和加密隧道上复用应用程序连接流，并传送其他流级元数据。

## 安全和租户 {#security-and-tenancy}

根据 mTLS 规范的强制要求，每个底层隧道连接必须具有唯一的来源身份和唯一的目标身份，
并且必须使用这些身份为该连接进行加密。

这意味着通过 HBONE 协议从应用程序到同一个目标身份的连接将在同一个共享的、
加密的和安全的底层 HTTP/2 连接上进行多路复用。实际上，
即使该底层专用连接正在处理多个应用程序级连接，
每个唯一的来源和目标也必须获取自己专用的安全隧道连接。

## 实现细节 {#implementation-details}

根据 Istio 约定，ztunnel 和其他理解 HBONE 协议的代理在 TCP 端口 15008 上公开侦听器。

由于 HBONE 只是 HTTP/2、HTTP CONNECT 和 mTLS 的组合，
因此在启用 HBONE 的代理之间流动的 HBONE 隧道数据包如下图所示：

{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 数据包格式"
>}}
随着 Ambient 模式和标准的发展，未来将研究 HBONE 和 HTTP 隧道（例如 UDP）的其他用例。
