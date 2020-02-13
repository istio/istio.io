---
title: 升级说明
description: 运维人员在升级至 Istio 1.2 版本前必须理解的的重要变化。
weight: 20
---

本页描述了您在从 Istio 1.1.x 升级至 1.2.x 版本时的注意事项。这里我们详细描述了向后不兼容的情况。同时介绍那些向后兼容但引入了新行为的情况，这对于熟悉 Istio 1.1 使用和操作的人来说可能令人惊讶。

## 安装与升级{#installation-and-upgrade}

{{< tip >}}
Mixer 的配置模型得以简化。面向适配器、面向模板的定制资源支持在 1.2 中默认被删除，并会在 1.3 中完全删除。请迁移到新的配置模型。
{{< /tip >}}

为简化配置模型、提高 Mixer 与 Kubernetes 一起使用时的性能以及在各种 Kubernetes 环境中的可靠性，大部分 Mixer CRD 被删除。

以下 CRD 保留：

| 定制资源定义名称 | 目的 |
| --- | --- |
| `adapter`| Istio 扩展声明规范 |
| `attributemanifest` | Istio 扩展声明规范 |
| `template` | Istio 扩展声明规范 |
| `handler` | Istio 扩展声明规范 |
| `rule` | Istio 扩展声明规范 |
| `instance` | Istio 扩展声明规范 |

如果您在使用已被删除的 Mixer 配置模式，在升级 Helm chart 时需设置以下 Helm 标志:
`--set mixer.templates.useTemplateCRDs=true --set mixer.adapters.useAdapterCRDs=true`
