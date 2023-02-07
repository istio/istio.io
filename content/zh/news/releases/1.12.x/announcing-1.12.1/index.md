---
title: Istio 1.12.1 发布公告
linktitle: 1.12.1
subtitle: 补丁发布
description: Istio 1.12.1 补丁发布。
publishdate: 2021-12-07
release: 1.12.1
aliases:
    - /zh/news/announcing-1.12.1
---

此版本包含错误修复，以提高稳健性。本版本说明描述了 Istio 1.12.0 和 Istio 1.12.1 之间的不同之处。

{{< relnote >}}

## 改变{#changes}

- **新增** 新增了 istiod 部署对于 `values.pilot.nodeSelector` 参数的遵循。
  ([问题 #36110](https://github.com/istio/istio/issues/36110))

- **新增** 新增了一个选项，当使用多集群 secret 时，通过在 Istiod 中配置 `PILOT_INSECURE_MULTICLUSTER_KUBECONFIG_OPTIONS` 环境变量来禁用多个非标准的 kubeconfig 身份验证方法。默认情况下，该选项被配置为允许所有方法；未来的版本将默认限制这一点。

- **修复** 修复了 `--duration` 标志永远不会在 `istioctl bug-report` 命令中使用的问题。

- **修复** 修复了在 `istioctl bug-report` 中使用标签导致错误的问题。
  ([问题 #36103](https://github.com/istio/istio/issues/36103))

- **修复** 修复了 `DeploymentConfig`/`ReplicationController` 工作负载名称无法正常工作的问题。

- **修复** 修复了错误报告中可能会省略一些控制平面消息的问题。

- **修复** 修复了 webhook 分析器在 `NamespaceSelector` 字段为空时，抛出 nil 指针错误的问题。

- **修复** 修复了 k8s 1.21+ 以上版本的 `CronJob` 工作负载未正确填充固定名称指标标签的问题。
  ([问题 #35563](https://github.com/istio/istio/issues/35563))

- **修复** 修复了带有任何补丁上下文的 `EnvoyFilter` 会跳过在网关处添加新集群和监听器的问题。

- **修复** 修复了 `EnvoyFilter` 补丁在 `virtualOutbound-blackhole` 上可能导致内存泄漏的问题。
