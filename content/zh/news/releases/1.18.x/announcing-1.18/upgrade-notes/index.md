---
title: Istio 1.18 升级说明
description: 升级到 Istio 1.18.0 时要考虑的重要变更。
weight: 20
publishdate: 2023-06-07
---

当您从 Istio 1.17.x 升级到 Istio 1.18.0 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio `1.17.x` 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio `1.17.x` 用户意料的新特性变更。

## 代理并发变更 {#proxy-concurrency-changes}

在之前，代理运行工作线程数量的 `concurrency` 设置在 Sidecar
和不同网关安装机制之间的配置并不一致。尽管具有 CPU 限制设定，
该并发设置也会被网关所处主机上物理核心的数量而影响，从而引起性能下降以及资源使用增加问题。

在此版本中，不同部署类型中的并发配置已经进行调整并保持一致。
新逻辑将使用 `ProxyConfig.Concurrency` 设置（可以在整个网格范围或各个 Pod 中进行配置），
如果使用此设置，则会根据分配给容器的 CPU 限制进行并发性设置。例如，CPU 限制为 `2500m`
会将并发设置为 3。

在此版本之前，虽然 Sidecar 遵循此逻辑，但有时会错误地识别 CPU 限制。
而网关则完全不会根据此逻辑自动进行并发设置。

如果要保留始终利用所有 CPU 核心的旧网关机制，可以在每个网关上使用
`proxy.istio.io/config: concurrency: 0` 设置。
但是，建议避免这种不设置 CPU 限制的行为。

## Gateway API 自动部署变更 {#gateway-api-automated-deployment-changes}

仅当您使用 [Gateway API 自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)功能时，
此变更才会对您产生影响。请注意，这仅适用于 Kubernetes Gateway API，
不适用于 Istio `Gateway`。您可以使用以下命令检查您是否正在使用该功能：

{{< text bash >}}
$ kubectl get gateways.gateway.networking.k8s.io -ojson | jq -r '.items[] | select(.spec.gatewayClassName == "istio") | select((.spec.addresses | length) == 0) | "Found managed gateway: " + .metadata.namespace + "/" + .metadata.name'
Found managed gateway: default/gateway
{{< /text >}}

如果您看到“Found managed gateway”信息，则您可能会受到此变更的影响。

在 Istio 1.18 版之前，托管网关通过创建一个最小的 Deployment
配置的形式工作，该 Deployment 在运行时通过 Pod 注入进行完全填充。
如果要升级网关，用户需要重启 Pod 来触发重新的注入操作。

在 Istio 1.18 版中，该行为已变更为创建一个不再依赖于注入的完整 Deployment。
因此，**网关将在其修订版本变更时通过滚动重启进行更新**。

此外，使用此功能的用户必须在采用 Istio 1.18 版之前将其控制平面更新到
Istio 1.16.5+ 或 1.17.3+ 版本。否则可能会产生对相同资源的写入冲突问题。
