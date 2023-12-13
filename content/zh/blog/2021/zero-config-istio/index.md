---
title: "零配置 Istio"
description: 了解 Istio 带来的好处，即使不使用任何配置。
publishdate: 2021-02-25
attribution: "John Howard (Google)"
---

当新用户第一次遇到 Istio 时，他们有时会被它所暴露的庞大功能集所淹没。不幸的是，这会给人一种印象，即 Istio 过于复杂，不适合小型团队或集群。

然而，关于 Istio 的一个重要部分是，它旨在为用户带来开箱即用的价值，而无需任何配置。这使用户能够以最少的努力获得 Istio 的大部分好处。 对于一些要求简单的用户，自定义配置可能根本不需要。其他人将能够在他们更舒适且需要时逐步添加 Istio 配置，例如添加入口路由、微调网络设置或锁定安全策略。

## 入门 {#getting-started}

要开始使用，请查看我们的 [入门（getting started）](/zh/docs/setup/getting-started/) 文档，您可以在其中学习如何安装 Istio。如果您已经熟悉，您可以简单地运行 `istioctl install`。

接下来，我们将探索 Istio 为我们提供的所有好处，无需对应用程序代码进行任何配置或更改。

## 安全 {#security}

Istio 自动为网格中 pod 之间的流量启用 [mutual TLS](/zh/docs/concepts/security/#mutual-tls-authentication)。这使应用程序能够放弃复杂的 TLS 配置和证书管理，并将所有传输层安全性卸载到 sidecar。

熟悉自动 TLS 后，您可以选择 [仅允许 mTLS 流量（allow only mTLS traffic）](/zh/docs/tasks/security/authentication/mtls-migration/)，或配置自定义 [授权策略（authorization policies）](/zh/docs/tasks/security/authorization/) 满足您的需求。

## 可观测性 {#observability}

Istio 自动为网格中的所有服务通信生成详细的遥测数据。这种遥测提供了服务行为的可观测性，使运营商能够对其应用程序进行故障排除、维护和优化——而不会给服务开发人员带来任何额外的负担。通过 Istio，运维人员可以全面了解受监控的服务如何与其他服务以及 Istio 组件本身进行交互。

所有这些功能都是由 Istio 添加的，无需任何配置。也可以与 Prometheus、Grafana、Jaeger、Zipkin 和 Kiali 等工具[集成（Integrations）](/zh/docs/ops/integrations/)使用。

有关 Istio 提供的可观测性的更多信息，请查看[可观测性概述（observability overview）](/zh/docs/concepts/observability/)。

## 流量管理 {#traffic-management}

虽然 Kubernetes 提供了许多网络功能，例如服务发现和 DNS，但这是在第 4 层完成的，这可能会产生意想不到的低效率。例如，在一个简单的 HTTP 应用程序向具有 3 个副本的服务发送流量时，我们可以看到负载不平衡：

{{< text bash >}}
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
{{< /text >}}

这里的问题是 Kubernetes 将在建立连接时确定发送到的后端，并且同一连接上的所有未来请求都将发送到同一个后端。在我们的示例中，我们的前 5 个请求都发送到 `echo-cb96f8d94-2ssll`，而我们的下一组（使用新连接）都发送到 `echo-cb96f8d94-879sn`。我们的第三个实例从未收到任何请求。

使用 Istio，会自动检测 HTTP 流量（包括 HTTP/2 和 gRPC），并且我们的服务将根据 _request_ 而不是根据 _connection_ 自动进行负载均衡：

{{< text bash >}}
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-wf4xk
Hostname=echo-cb96f8d94-rpfqz
Hostname=echo-cb96f8d94-cgmxr
Hostname=echo-cb96f8d94-wf4xk
Hostname=echo-cb96f8d94-rpfqz
Hostname=echo-cb96f8d94-cgmxr
{{< /text >}}

在这里，我们可以看到我们的请求是[轮询（round-robin）](/zh/docs/concepts/traffic-management#load-balancing-options)在所有后端之间进行负载均衡的。

除了这些默认设置之外，Istio 还提供了[各种流量管理设置](/zh/docs/concepts/traffic-management/)的自定义设置，包括超时、重试等等。
