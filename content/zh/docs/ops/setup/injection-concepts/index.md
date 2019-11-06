---
title: Sidecar自动注入
description: 介绍Istio是如何通过Kubernetes的webhooks机制来实现Sidecar自动注入
weight: 5
aliases:
    - /help/ops/setup/injection

---

Sidecar 自动注入机制提供了代理注入 Sidecar 到用户创建 pod 的能力；

它的原理是在 pod 创建的时候，通过 `MutatingWebhook` 机制添加 sidecar 的容器 (containers) 和卷 (volumes) 信息到每个 pod 的模板里；

用户可以通过 webhooks 命名空间选择器 (`namespaceSelector`) 机制来限定需要启动自动注入的范围，也可以通过注解的方式针对每个 pod 来单独启用和禁用自动注入功能。 

Sidecar 是否会被自动注入取决于下面3条配置和2条安全规则：

配置：

- webhooks 命名空间选择器 (webhooks `namespaceSelector`)
- 默认的注入策略（default `policy`）
- pod 级别的通过注解定义的注入策略，会覆盖默认策略 (per-pod override annotation)

安全规则:

- sidecar 默认不能被注入到 `kube-system` 和 `kube-public` 这两个命名空间
- sidecar 不能被注入到使用 `host network` 网络的pod里

下面这表是基于上述的三种配置在不考虑安全规则的情况下枚举是否能够注入sidecar的情况：

| 是否匹配命名空间选择器 | 是否开启默认注入策略 | Pod是否存在注解覆盖注入策略 | 是否会注入? |
| ---------------------- | -------------------- | --------------------------- | ----------- |
| 是                     | 开启                 | 是 (默认)                   | 是          |
| 是                     | 开启                 | 否                         | 否          |
| 是                     | 关闭                 | 是                         | 是          |
| 是                     | 关闭                 | 否 (默认)                   | 否          |
| 否                     | 开启                 | 是 (默认)                   | 否          |
| 否                     | 开启                 | 否                         | 否          |
| 否                     | 关闭                 | 是                         | 否          |
| 否                     | 关闭                 | 否 (默认)                   | 否          |
