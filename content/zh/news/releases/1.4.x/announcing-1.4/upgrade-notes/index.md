---
title: 升级说明
description: 升级到 Istio 1.4 的相关重要变化。
weight: 20
---

此页面描述了当你从 Istio 1.3 升级到 1.4 时需要注意的一些变化。这里我们主要说明在哪我们有意的取消了向后兼容。
同时我们也会说明哪些向后兼容被保留后并可能会产生一些不同于 Istio 1.3 的奇怪行为。

## 流量管理{#traffic-management}

### 443 端口的 HTTP 服务{#http-services-on-port-four-four-three}

`http`类型的服务将不再允许使用 443 端口，这个改动是为了保护协议不与外部的 HTTPS 服务所冲突。

如果你依赖这个行为，那么有下面一些选项：

* 把应用替换为其他端口。
* 把协议类型从 `http` 替换为 `tcp`。
* 给 Pilot deployment 指定环境变量 `PILOT_BLOCK_HTTP_ON_443=false`。注意：这会在未来的发布中移除。

查看 [Protocol Selection](/zh/docs/ops/configuration/traffic-management/protocol-selection/) 获取更多关于指定协议端口的信息。

### 正则引擎变化{#regex-engine-changes}

为了防止过大的正则表达式消耗过多的资源，Envoy 选择了一个新的正则表达式引擎 [`re2`](https://github.com/google/re2) ，这之前用的是 `std::regex`。这两个引擎有着很明显的语法差异，尤其是，现在的正则字段被限制在 100 bytes 以内。

如果你依赖了旧正则表达式引擎的某个特定的行为，你可以通过给 Pilot deployment 指定环境变量 `PILOT_ENABLE_UNSAFE_REGEX=true` 来避免这个变化。注意：这会在未来的发布中移除。

## 配置管理{#configuration-management}

我们已经在 Istio 资源 的 Kubernetes schema 中介绍过 OpenAPI V3 [Custom Resource Definitions (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，此 schema 描述 Istio 资源并且确保你创建和修改的 Istio 资源能够结构化并且保持正确。

如果配置的某个或者多个字段是 unknown 或者错误的类型，那么当你创建或者修改 Istio 资源的时候 Kubernetes API server 会拒绝。这个特性，`CustomResourceValidation` 是 Kubernetes 1.9+ 版本的默认选项。需要注意的是如果某个之前已经存在的配置并且没有被修改过那么他们 __不会__ 受到影响。

为了帮助你升级，这里有一些你可以参照的步骤：

* 升级 Istio 之后，用 `kubectl apply --dry-run` 来跑一遍你的 Istio 配置，这样你就可以知道这些配置对于 API server 来说是不是 unknown 或者无效的字段。（`DryRun` 特性是 Kubernetes 1.13+ 版本开始的默认选项）
* 查看 [reference documentation](/zh/docs/reference/config/) 来确认修正字段名和数据类型。
* 另外，为了能够结构化验证，你也可以使用 `istioctl x analyze` 来帮助检查到你的 Istio 配置的潜在问题。参考 [here](/zh/docs/ops/diagnostic-tools/istioctl-analyze/) 获取更多细节。

如果你想忽略验证错误，当你创建或者修改 Istio 资源的时候可以给 `kubectl` 添加 `--validate=false` 参数。由于这会导致错误的配置，我们非常不推荐这么做。
