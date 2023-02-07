---
title: 发布 Istio 1.7.4 版本
linktitle: 1.7.4
subtitle: 补丁发布
description: Istio 1.7.4 补丁发布。
publishdate: 2020-10-27
release: 1.7.4
aliases:
    - /zh/news/announcing-1.7.4
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.7.3 和 Istio 1.7.4 之间的不同之处。

{{< relnote >}}

## 变动{#changes}

- **优化** 在 Sidecar 服务器端的入站路径上配置 TLS，以强制执行 TLS 2.0 版本和推荐的密码套件。默认情况下禁用此功能，可以通过设置环境变量 `PILOT_SIDECAR_ENABLE_INBOUND_TLS_V2` 为 true 来启用。

- **新增** 为多集群安装配置域后缀的能力。([Issue #27300](https://github.com/istio/istio/issues/27300))

- **新增** `istioctl proxy-status` 和其他命令在放弃之前会尝试使用端口转发和 exec 来联系控制平面，在不提供端口转发的集群上恢复控制平面的功能。([Issue #27421](https://github.com/istio/istio/issues/27421))

- **新增** 在 Kubernetes 设置中支持对 Operator API 的 `securityContext`。([Issue #26275](https://github.com/istio/istio/issues/26275))

- **新增** 支持基于修订版的 Istiod 到 Istioctl 版本。([Issue #27756](https://github.com/istio/istio/issues/27756))

- **修复** 删除用于多集群安装的远程秘密会删除远程端点。

- **修复** Istiod 的 `cacert.pem` 在 `testdata` 目录下的问题。([Issue #27574](https://github.com/istio/istio/issues/27574))

- **修复** `istio-egressgateway` 的 `PodDisruptionBudget` 不匹配任何 Pod 的问题。([Issue #27730](https://github.com/istio/istio/issues/27730))

- **修复** 当在主机头中设置端口时，防止调用通配符（如*.example.com）域的问题。

- **修复** 在Pilot的`syncz`调试端点中，周期性导致死锁的问题。

- **移除** 从全局值中弃用了 `outboundTrafficPolicy`。([Issue #27494](https://github.com/istio/istio/issues/27494))
