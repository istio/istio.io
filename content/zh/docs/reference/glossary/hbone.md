---
title: HBONE
test: n/a
---

基于 HTTP 的上层网络环境（HTTP-Based Overlay Network Environment，HBONE）
是在 Istio 组件之间使用的安全隧道化协议。在 HBONE 中，用户流量通过
[mTLS 身份验证](/zh/docs/reference/glossary/#mutual-tls-authentication)加密的
HTTP `CONNECT` 隧道进行安全的隧道传输。
