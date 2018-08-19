---
title: 流量管理观测
description: 描述观测流量管理或相关问题的工具和技术。
weight: 5
---

## Envoy 在负载下 crash

检查 `ulimit -a`。很多系统默认文件描述符最大为 1024，会导致 Envoy 断言出错并 crash：

{{< text plain >}}
[2017-05-17 03:00:52.735][14236][critical][assert] assert failure: fd_ != -1: external/envoy/source/common/network/connection_impl.cc:58
{{< /text >}}

确保调整了最大限制值。例如：`ulimit -n 16384`

## 为什么创建加权路由规则在两个版本的服务之间切分的流量不按权重工作？

当前 Envoy sidecar 的实现，可能需要多于 100 个请求才能观察到相应的分布。

## 为什么配置的路由规则不会立即生效？

Kubernetes 上的 Istio 使用最终一致性的算法来确保所有 Envoy sidecar 配置生效，包括所有路由规则。配置变更需要花一定时间才能保证在全部的 sidecar 上生效。对于大型部署，最终生效将花费更长时间，并且可能存在秒级的延迟。