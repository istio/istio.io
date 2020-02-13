---
title: 创建服务账号 Secret
description: 描述 Citadel 如何确定是否创建服务账号 secret。
weight: 30
---

当 Citadel 实例注意到命名空间中创建了 `ServiceAccount` 时，它必须决定是否应该为该 `ServiceAccount` 生成 `istio.io/key-and-cert` secret。
为了做出决定，Citadel 考虑三个输入（请注意：单个集群中可以部署多个 Citadel 实例，并且以下定位规则应用于每个实例）：

1. `ca.istio.io/env` 命名空间标签：*字符串值* 包含所需 Citadel 实例的命名空间的标签

1. `ca.istio.io/override` 命名空间标签：*布尔值* 覆盖所有其他配置，并强制所有 Citadel 实例定位或忽略命名空间的标签

1. [`enableNamespacesByDefault` 安全配置](/zh/docs/reference/config/installation-options/#security-options)：如果在 `ServiceAccount` 的命名空间上找不到标签，则为默认行为

根据这三个值，其决策过程与 [`Sidecar Injection Webhook`](/zh/docs/ops/configuration/mesh/injection-concepts/) 的过程类似。具体行为是：

- 如果 `ca.istio.io/override` 存在并且为 `true`，则为工作负载生成密钥/证书 secret。

- 否则，如果 `ca.istio.io/override` 存在并且为 `false`，则不为工作负载生成密钥/证书 secret。

- 否则，如果服务账号所在命名空间上定义了 `ca.istio.io/env: "ns-foo"` 标签，则命名空间 `ns-foo` 中的 Citadel 实例将被用于为 `ServiceAccount` 的命名空间中的工作负载生成密钥/证书 secret。

- 否则，就在安装时将 `enableNamespacesByDefault` 设置为 `true`。如果它是 `true`，默认的 Citadel 实例将被用于为 `ServiceAccount` 的命名空间中的工作负载生成密钥/证书 secret。

- 否则，将不会为 `ServiceAccount` 的命名空间创建 secret。

下面的真值表体现了该逻辑：

| `ca.istio.io/override` 值 | `ca.istio.io/env` 匹配 | `enableNamespacesByDefault` 配置 | 是否为工作负载创建 secret |
|------------------------------|-------------------------|-------------------------------------------|-------------------------|
|`true` | yes | `true` | yes |
|`true` | yes | `false` | yes |
|`true` | no | `true` | yes |
|`true` | no | `false` | yes |
|`true` | 未设置 | `true` | yes |
|`true` | 未设置 | `false` | yes |
|`false` | yes | `true` | no |
|`false` | yes | `false` | no |
|`false` | no | `true` | no |
|`false` | no | `false` | no |
|`false` | 未设置 | `true` | no |
|`false` | 未设置 | `false` | no |
|未设置| yes | `true` | yes |
|未设置| yes | `false` | yes |
|未设置| no | `true` | no |
|未设置| no | `false` | no |
|未设置| 未设置 | `true` | yes |
|未设置| 未设置 | `false` | no |

{{< idea >}}
当命名空间从 *禁用* 过渡到 *启用* 时，Citadel 将为该命名空间中的所有 `ServiceAccounts` 生成 secret。而从 *启用* 过渡到 *禁用* 时，Citadel 却不会删除命名空间中已经生成的 secret，直到更新了根证书为止。
{{< /idea >}}
