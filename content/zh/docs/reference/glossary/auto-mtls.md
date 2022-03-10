---
title: 自动 mTLS
test: n/a
---

自动 mTLS 是 Istio 的一个特性，用以发送
[双向 TLS 流量](/zh/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls)，
其中客户端和服务器都能够处理 Mutual TLS 的流量。
当客户端或服务器无法处理此类流量时，Istio 将其会降级为纯文本。
