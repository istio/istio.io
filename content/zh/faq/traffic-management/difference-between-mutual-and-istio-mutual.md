---
title: MUTUAL 和 ISTIO_MUTUAL TLS 模式有什么区别?
weight: 30
---

两个 `DestinationRule` 设置都会发送双向的 TLS 流量。
使用`ISTIO_MUTUAL`时，将会自动使用 Istio 证书。
对于`MUTUAL`，必须配置密钥、证书和可信任的CA。
允许与非 non-Istio 应用启动双向的 TLS。
