---
title: 在 Istio 使用 ZipKin 功能时，是否可以返回 x-request-id？
weight: 120
---

除非复制标头，否则 Istio 也无法知道接受原始请求的应用程序何时给出响应消息。如果复制标头，则可以将其包含在响应标头中。