---
title: Istio 1.20 升级说明
description: 升级到 Istio 1.20 时要考虑的重要变更。
weight: 20
publishdate: 2023-11-14
---

当您从 Istio 1.19.x 升级到 Istio 1.20.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio `1.19.x` 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio `1.19.x` 用户意料的新特性变更。

## 即将到来的 `ExternalName` 支持变更 {#upcoming-externalname-support-changes}

以下信息描述了 `ExternalName` **即将发生**的变更。

在此版本中，默认情况下没有行为变更。但是，如果需要，
您可以尽早明确的选择并采用新行为，以及为即将到来的变更准备环境。

Kubernetes `ExternalName` `Service` 允许用户创建新的 DNS 条目。
例如，您可以创建指向 `example.com` 的 `example` 服务。
这是通过 DNS `CNAME` 重定向实现的。

在 Istio 中，`ExternalName` 的实现历史有着很大的不同。
每个 `ExternalName` 都代表其自身的服务，
与该服务匹配的流量被发送到已配置的 DNS 名称中。

这导致了一些问题：

* Istio 中需要端口，但 Kubernetes 中不需要。
  如果端口没有按照 Istio 的预期进行配置，则可能会导致流量中断，
  尽管它们在没有 Istio 的情况下也能工作。
* 未被声明为 `HTTP` 的端口将会匹配该端口上的**所有**流量，
  从而很容易意外地将端口上的所有流量发送到错误的位置。
* 由于目标 DNS 名称被视为不透明，因此我们无法按预期对其应用 Istio 策略。
  例如，如果外部名称指向另一个集群内服务
  （例如 `example.default.svc.cluster.local`），则 mTLS 也不会被应用。

对 `ExternalName` 的支持进行了重构，用于解决这些问题。
`ExternalName` 现在被简单地视为别名。无论我们在哪里匹配 `Host: <concrete service>`，
我们都会另外匹配 `Host: <external name service>`。
请注意，`ExternalName` DNS 的主要实现是在 Istio 外部的
Kubernetes DNS 实现中处理的，并将保持不变。

如果您将 `ExternalName` 与 Istio 一起使用，请注意以下行为变化：

* 不再需要 `ports` 字段，以匹配 Kubernetes 行为。
  如果设置了该字段，将不会产生任何影响。
* 在 `ExternalName` 服务上匹配的 `VirtualServices` 一般情况下将不再匹配。
  相反，应该将匹配重写为被引用的服务。
* `DestinationRule` 不再适用于 `ExternalName` 服务。
  相反，创建规则通过 `host` 引用服务。

这些变更在此版本中默认处于关闭状态，但在不久的将来将默认开启。
需要尽早选择开启，可以设置 `ENABLE_EXTERNAL_NAME_ALIAS=true` 环境变量。

## Envoy 过滤器排序 {#envoy-filter-ordering}

此更改影响 Envoy 过滤器排序方式的内部实现。
这些按照顺序运行的过滤器是为了实现各类功能。

现在，入站、出站和网关代理模式以及 HTTP 和 TCP 协议的顺序是一致的：

* Metadata Exchange
* CUSTOM Authz
* WASM Authn
* Authn
* WASM Authz
* Authz
* WASM Stats
* Stats
* WASM unspecified

这改变了以下领域：

* 入站 TCP 过滤器现在将 Metadata Exchange 置于 Authn 之前。
* 网关 TCP 过滤器现在将 Stats 放在 Authz 之后，
  将 CUSTOM Authz 放在 Authn 之前。

## `startupProbe` 被默认添加到 Sidecar {#startupProbe-added-to-sidecar-by-default}

Sidecar 容器现在默认启用 `startupProbe`。启动探测仅在 Pod 启动时运行。
启动探测完成后，就绪探测将继续。

通过使用启动探测，我们可以更积极的轮询 Sidecar 直至启动，
而无需在整个 Pod 生命周期中积极轮询。平均而言，
这将 Pod 启动时间缩短了大约一秒。

如果 10 分钟后启动探测仍未通过，Pod 将被终止。
之前，即使 Pod 无限期地无法启动，也永远不会被终止。

如果您不想要该功能，可以将其禁用。但是，您需要相应地调整就绪探测。

启用启动探测时的推荐值（新默认值）：

{{< text yaml >}}
readinessInitialDelaySeconds: 0
readinessPeriodSeconds: 15
readinessFailureThreshold: 4
startupProbe:
enabled: true
failureThreshold: 600
{{< /text >}}

禁用启动探测的建议值（恢复行为以匹配旧的 Istio 版本）：

{{< text yaml >}}
readinessInitialDelaySeconds: 1
readinessPeriodSeconds: 2
readinessFailureThreshold: 30
startupProbe:
enabled: false
{{< /text >}}
