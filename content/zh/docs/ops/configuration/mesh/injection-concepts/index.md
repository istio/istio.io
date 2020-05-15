---
title: Sidecar 自动注入
description: 介绍 Istio 是如何通过 Kubernetes 的 webhooks 机制来实现 Sidecar 自动注入。
weight: 20
aliases:
  - /zh/help/ops/setup/injection
  - /zh/docs/ops/setup/injection-concepts
---

Sidecar 自动注入机制将 sidecar 代理添加到用户创建的 pod。

它使用 `MutatingWebhook` 机制在 pod 创建的时候将 sidecar 的容器和卷添加到每个 pod 的模版里。

用户可以通过 webhooks `namespaceSelector` 机制来限定需要启动自动注入的范围，也可以通过注解的方式针对每个 pod 来单独启用和禁用自动注入功能。

Sidecar 是否会被自动注入取决于下面 3 条配置和 2 条安全规则：

配置：

- webhooks `namespaceSelector`
- 默认策略
- pod 级别的覆盖注解

安全规则:

- sidecar 默认不能被注入到 `kube-system` 和 `kube-public` 这两个 namespace
- sidecar 不能被注入到使用 `host network` 网络的 pod 里

下面的表格展示了基于上述三个配置条件的最终注入状态。上述的安全规则不会被覆盖。

| `namespaceSelector` 匹配   | 默认策略           | Pod 覆盖 `sidecar.istio.io/inject` 注解 | Sidecar 是否注入？ |
|---------------------------|------------------|----------------------------------------|------------------|
| yes                       | enabled          | true (default)                         | yes              |
| yes                       | enabled          | false                                  | no               |
| yes                       | disabled         | true                                   | yes              |
| yes                       | disabled         | false (default)                        | no               |
| no                        | enabled          | true (default)                         | no               |
| no                        | enabled          | false                                  | no               |
| no                        | disabled         | true                                   | no               |
| no                        | disabled         | false (default)                        | no               |
