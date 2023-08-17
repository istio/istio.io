---
title: Istio 1.14.4 发布公告
linktitle: 1.14.4
subtitle: 补丁发布
description: Istio 1.14.4 补丁发布。
publishdate: 2022-09-12
release: 1.14.4
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.14.3 和 Istio 1.14.4 之间的不同之处。

{{< relnote >}}

## 变更  {#changes}

- **新增** Istio [健康检查](/zh/docs/ops/configuration/mesh/app-health-check/)新增对 `ALPN` 协商的支持，新增镜像 `Kubelet` 功能的支持。这允许 `HTTPS` 类型的探针使用 `HTTP2`。若要回滚为先前始终使用 `HTTP/1.1` 的行为，您可以设置 `ISTIO_ENABLE_HTTP2_PROBING=false` 变量。

- **新增** 重新恢复了 1.14 版本中移除的 `PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES` 特性。在使用场景未明确且没有添加更持久的 API 之前，此特性将持续存在。

- **修复** 修复了为日志格式使用 `JSON` 进行编码时 `%REQ_WITHOUT_QUERY(X?:Y):Z%` 命令 Operator 不起作用的问题。([Issue #39271](https://github.com/istio/istio/issues/39271))

- **修复** 修复了工作负载实例更新期间 Istio 未更新 `STRICT_DNS` 集群中端点列表的问题。 ([Issue #39505](https://github.com/istio/istio/issues/39505))

- **修复** 修复了使用 `exportTo` 到特定的命名空间时会出现 `ConflictingMeshGatewayVirtualServiceHosts` (`IST0109`) 消息的问题。 ([Issue #39634](https://github.com/istio/istio/issues/39634))

- **修复** 修复了 `istioctl analyze` 启动时会出现无效警告消息的问题。

- **修复** 修复了在主机网络上非注入的 Pod 会因为 `istioctl analyze` 出现 `IST0103` 警告的问题。

- **修复** 修复了在相同主机的 Gateway 中指定 `Bind` 时未正确生成监听器的问题。 ([Issue #40268](https://github.com/istio/istio/issues/40268))

- **修复** 修复了当 `values.pilot.replicaCount` 设置为其默认值时 `istioctl install` 未显示一条警告消息的问题。([Issue #40246](https://github.com/istio/istio/issues/40246))

- **修复** 修复了一个服务在指定或不指定虚拟服务超时时间时会不正确地设置超时时间的问题。([Issue #40299](https://github.com/istio/istio/issues/40299))

- **修复** 修复了防止 Istio Ingress/Egress 网关匹配任何节点的问题。([Issue #40378](https://github.com/istio/istio/issues/40378))

- **修复** 修复了 `ProxyConfig` 重载可能会意外应用到其他工作负载的问题。([Issue #40445](https://github.com/istio/istio/issues/40445))

- **修复** 修复了 TCP 之后创建时会造成 TLS `ServiceEntries` 有时不起作用的问题。

- **修复** 修复了更新服务条目的主机名称时可能出现内存泄漏的问题。
