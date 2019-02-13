---
title: Istio 1.0.2
publishdate: 2018-09-06
icon: notes
---

此版本解决了社区在使用 Istio 1.0.1 过程中发现的一些关键问题。本文描述了 Istio 1.0.1 和 Istio 1.0.2 之间的差异。

{{< relnote_links >}}

## 杂项

- 如果在双向 TLS 端口上接收到正常流量，会造成 Sidecar 崩溃，本版本中修复了 Envoy 的这一问题。

- 修复了 Pilot 在多集群环境中向 Envoy 传播不完整更新的问题。

- 为 Grafana 添加了一些 Helm 选项。

- 改进了 Kubernetes 服务注册表队列性能。

- 修复了 `istioctl proxy-status` 未显示补丁版本的问题。

- 添加 `VirtualService` SNI 主机的验证。
