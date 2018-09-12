---
title: Istio 1.0.2
weight: 90
icon: /img/notes.svg
---

此版本解决了使用 Istio 1.0.1 时社区发现的一些关键问题。本发行说明描述了 Istio 1.0.1 和 Istio 1.0.2 之间的不同之处
。

{{</* relnote_links */>}}

## 杂项

- 修复了 Envoy 中的错误，如果在双向 TLS 端口上接收到正常流量，则 sidecar 会崩溃。

- 修复了 Pilot 在多集群环境中向 Envoy 传播不完整更新的问题。

- 为 Grafana 添加了一些 Helm 选项。

- 改进了 Kubernetes 服务注册表队列性能。

- 修复了 `istioctl proxy-status` 未显示补丁版本的问题。

- 添加 `VirtualService` SNI 主机的验证。
