---
title: 升级说明
description: 升级到 Istio 1.4 时需要考虑的重要变化。
weight: 20
---

本页描述了当您将 Istio 1.3 升级到 1.4 后需要关注的变化。
在这里，我们详细介绍了有意破坏向后兼容性的情况。
我们还提到了保留向后兼容性但引入了新行为的情况，这对于熟悉 Istio 1.3 的使用和操作的人来说是令人惊讶的。

## 流量管理{#traffic-management}

### 端口 443 上的 HTTP 服务{#http-services-on-port-four-four-three}

端口 443 上不再允许使用 `http` 类型的服务。
此更改是为了防止与外部 HTTPS 服务发生协议冲突。

如果您依赖此行为，下面有几种选择：

* 将应用改到另外一个端口。
* 将协议类型从 `http` 改为 `tcp`
* 为 Pilot deployment 指定环境变量 `PILOT_BLOCK_HTTP_ON_443=false`。注意：将来的版本可能会移除这个环境变量。

有关指定端口协议的更多信息，请参见[协议选择](/zh/docs/ops/traffic-management/protocol-selection/)。

### 正则表达式引擎修改{#regex-engine-changes}

为防止大型正则表达式占用过多资源，Envoy 已迁移到基于 [`re2`](https://github.com/google/re2) 的新正则表达式引擎。
以前，使用的是 `std::regex`。
这两个引擎的语法可能略有不同；特别是，正则表达式字段现在限制为 100 个字节。

如果您依赖于旧正则表达式引擎的特定行为，您可以通过将环境变量 `PILOT_ENABLE_UNSAFE_REGEX=true` 添加到 Pilot deployment 中来选择退出此更改。
注意：该环境变量将在以后的版本中删除。

## 配置管理{#configuration-management}

我们在 Istio 资源的 Kubernetes [自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)中引入了 OpenAPI v3 模式。
这些模式描述了 Istio 资源，并有助于确保您创建和修改的 Istio 资源在结构上是正确的。

如果您配置中的一个或多个字段未知或类型错误，那么当您创建或修改 Istio 资源时，Kubernetes API 服务器将会拒绝它们。
对于 Kubernetes 1.9+ 集群，此功能 `CustomResourceValidation` 默认处于启用状态。
请注意，如果 Kubernetes 中的现有配置保持不变，则不会受到影响。

为了帮助您进行升级，您可以采取以下步骤：

* 升级 Istio 之后，使用 `kubectl apply --dry-run` 运行您的 Istio 配置，以便您能够知道 API 服务器是否可以接受它们以及 API 服务器的任何可能的未知或无效字段。（默认情况下，Kubernetes 1.13+ 集群的 `DryRun` 功能处于打开状态。）
* 使用[参考文档](/zh/docs/reference/config/)来确认和更正字段名称和数据类型。
* 除了结构验证之外，您还可以使用 `istioctl x analyze` 来帮助您检测 Istio 配置的其他潜在问题。更多详细信息，请参阅[此处](/zh/docs/ops/diagnostic-tools/istioctl-analyze/)。

如果您选择忽略验证错误，您可以在创建或修改 Istio 资源时，在您的 `kubectl` 命令中添加 `--validate=false`。
但是，我们强烈建议您不要这样做，因为它会引入错误的配置。
