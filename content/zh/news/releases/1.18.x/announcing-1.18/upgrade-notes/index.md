---
title: Istio 1.18 升级说明
description: 升级到 Istio 1.18.0 时要考虑的重要变更。
weight: 20
publishdate: 2023-06-07
---

When you upgrade from Istio 1.17.x to Istio 1.18.0, you need to consider the changes on this page.
当您从 Istio 1.17.x 升级到 Istio 1.18.0 时，您需要考虑本页所述的变更。
These notes detail the changes which purposefully break backwards compatibility with Istio `1.17.x.`
这些说明详述了故意破坏 Istio `1.17.x` 向后兼容性的一些变更。
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
Changes are only included if the new behavior would be unexpected to a user of Istio `1.17.x.`
仅当新特性对 Istio `1.17.x` 的用户来说在意料之外时，才会包含这些变更。

## Proxy Concurrency changes
## 代理并发更改

Previously, the proxy `concurrency` setting, which configures how many worker threads the proxy runs, was inconsistently configured between sidecars and different gateway installation mechanisms. This often led to gateways running with concurrency based on the number of physical cores on the host machine, despite having CPU limits, leading to decreased performance and increased resource usage.
以前，配置代理运行多少个工作线程的代理“并发”设置在 sidecar 和不同的网关安装机制之间配置不一致。 尽管有 CPU 限制，这通常会导致网关根据主机上物理内核的数量并发运行，从而导致性能下降和资源使用增加。

In this release, concurrency configuration has been tweaked to be consistent across deployment types. The new logic will use the `ProxyConfig.Concurrency` setting (which can be configured mesh wide or per-pod), if set, and otherwise set concurrency based on the CPU limit allocated to the container.  For example, a limit of `2500m` would set concurrency to 3.
在此版本中，并发配置已经过调整以在不同部署类型之间保持一致。 新逻辑将使用“ProxyConfig.Concurrency”设置（可以在网格范围内或每个 pod 中配置），如果已设置，则根据分配给容器的 CPU 限制设置并发性。 例如，“2500m”的限制会将并发设置为 3。

Prior to this release, sidecars followed this logic, but sometimes incorrectly determined the CPU limit. Gateways would never automatically adapt based on concurrency settings.
在此版本之前，sidecar 遵循此逻辑，但有时会错误地确定 CPU 限制。 网关永远不会根据并发设置自动适应。

To retain the old gateway behavior of always utilizing all cores, `proxy.istio.io/config: concurrency: 0` can be set on each gateway.  However, it is recommended to instead unset CPU limits if this is desired.
为了保留始终利用所有核心的旧网关行为，可以在每个网关上设置 proxy.istio.io/config: concurrency: 0 。 但是，如果需要，建议取消设置 CPU 限制。

## Gateway API Automated Deployment changes
## 网关 API 自动部署更改

This change impacts you only if you use [Gateway API Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment). Note that this only applies to the Kubernetes Gateway API, not the Istio `Gateway`. You can check if you are using this feature with the following command:
仅当您使用 [Gateway API 自动部署](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) 时，此更改才会对您产生影响。 请注意，这仅适用于 Kubernetes Gateway API，不适用于 Istio `Gateway`。 您可以使用以下命令检查您是否正在使用此功能：

    {{< text bash >}}
    $ kubectl get gateways.gateway.networking.k8s.io -ojson | jq -r '.items[] | select(.spec.gatewayClassName == "istio") | select((.spec.addresses | length) == 0) | "Found managed gateway: " + .metadata.namespace + "/" + .metadata.name'
    Found managed gateway: default/gateway
    {{< /text >}}

If you see "Found managed gateway", you may be impacted by this change.
如果您看到“找到托管网关”，则您可能会受到此更改的影响。

Prior to Istio 1.18, the managed gateway worked by creating a minimal Deployment configuration which was fully populated at runtime with Pod injection. To upgrade gateways, users would restart the Pods to trigger a re-injection.
在 Istio 1.18 之前，托管网关通过创建一个最小的 Deployment 配置来工作，该配置在运行时通过 Pod 注入完全填充。 要升级网关，用户将重启 Pod 以触发重新注入。

In Istio 1.18, this has changed to create a fully rendered Deployment and no longer rely on injection. As a result, *Gateways will be updated, via a rolling restart, when their revision changes*.
在 Istio 1.18 中，这已更改为创建一个完全呈现的 Deployment，不再依赖于注入。 因此，*网关将在其修订版更改时通过滚动重启进行更新*。

Additionally, users using this feature must update their control plane to Istio 1.16.5+ or 1.17.3+ before adopting Istio 1.18. Failure to do so may lead to conflicting writes to the same resources.
此外，使用此功能的用户必须在采用 Istio 1.18 之前将其控制平面更新到 Istio 1.16.5+ 或 1.17.3+。 如果不这样做，可能会导致对相同资源的写入冲突。
