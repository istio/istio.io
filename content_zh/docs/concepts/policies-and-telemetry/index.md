---
title: 策略与遥测
description: 描述策略实施和遥测机制。
weight: 40
keywords: [policies,telemetry,control,config]
aliases:
    - /docs/concepts/policy-and-control/mixer.html
    - /docs/concepts/policy-and-control/mixer-config.html
    - /docs/concepts/policy-and-control/attributes.html
---

Istio 提供灵活的模型来执行授权策略，并为网格中的服务收集遥测数据。

基础设施后端旨在提供用于构建服务的支持功能。它们包括访问控制系统，遥测捕获系统，配额执行系统，计费系统等等。服务传统上直接与这些后端系统集成，创建硬耦合，还有沾染特定的语义和使用选项。

Istio 提供统一抽象，使得 Istio 可以与一组开放式基础设施后端进行交互。这样做是为了给运维提供丰富而深入的控制，同时不给服务开发人员带来负担。Istio 旨在改变层与层之间的边界，以减少系统复杂性，消除服务代码中的策略逻辑并将控制权交给运维。

Mixer 是负责提供策略控制和遥测收集的 Istio 组件：

{{< image width="75%" ratio="49.26%"
    link="/docs/concepts/policies-and-telemetry/topology-without-cache.svg"
    caption="Mixer 拓扑"
    >}}

在每次请求执行先决条件检查之前以及在每次报告遥测请求之后，Envoy sidecar 在逻辑上调用 Mixer。

该 sidecar 具有本地缓存​，从而可以在缓存中执行相对较大比例的前提条件检查。此外，sidecar 缓冲出站遥测，使其实际上不需要经常调用 Mixer。

在高层上，Mixer 提供：

- **后端抽象**。Mixer 隔离 Istio 的其余部分和各个基础设施后端的实现细节。
- **中介**。Mixer 允许运维对网格和基础设施后端之间的所有交互进行细化控制。

除了这些纯粹的功能方面，Mixer 还具有如下所述的可靠性和可扩展性优势。

策略执行和遥测收集完全由配置驱动。可以完全禁用这些功能，并免除在 Istio 部署中运行 Mixer 组件的必要性。

## 适配器

Mixer 是高度模块化和可扩展的组件。他的一个关键功能就是把不同后端的策略和遥测收集系统的细节抽象出来，使得 Istio 的其余部分对这些后端不知情。

Mixer 处理不同基础设施后端的灵活性是通过使用通用插件模型实现的。每个插件都被称为 **Adapter**，Mixer通过它们与不同的基础设施后端连接，这些后端可提供核心功能，例如日志、监控、配额、ACL 检查等。通过配置能够决定在运行时使用的确切的适配器套件，并且可以轻松扩展到新的或定制的基础设施后端。

{{< image width="35%" ratio="138%"
    link="/docs/concepts/policies-and-telemetry/adapters.svg"
    alt="显示 Mixer 及其适配器"
    caption="Mixer 及其适配器"
    >}}

## 可靠性和延迟

Mixer 是一种高度可用的组件，其设计有助于提高整体可用性并减少网格中服务的平均延迟。其设计的关键方面带来以下好处：

- **无状态**。Mixer 是无状态的，因为它不管理任何自己的持久化存储。
- **硬化**。Mixer 本身被设计成高度可靠的组件。设计目标是为任何单独的 Mixer 实例实现 > 99.999％ 的正常运行时间。
- **缓存和缓冲**。Mixer 被设计为累积大量瞬态短暂状态。

位于网格中每个服务实例旁边的sidecar代理必须在内存消耗方面节约，这限制了本地缓存和缓冲的可能数量。然而，Mixer独立运行，可以使用相当大的缓存和输出缓冲区。因此，Mixer可用作Sidecar的高度扩展且高度可用的二级缓存。

{{< image width="75%" ratio="65.89%"
    link="/docs/concepts/policies-and-telemetry/topology-with-cache.svg"
    caption="Mixer 拓扑"
    >}}

由于 Mixer 的预期可用性远高于大多数基础设施后端（通常这些可用性可能达到 99.9％）。Mixer的本地缓存和缓冲不仅有助于减少延迟，而且即使在后端无响应时也能继续运行，从而有助于屏蔽基础设施后端故障。

最后，Mixer 的缓存和缓冲有助于减少对后端的调用频率，并且有时可以减少发送到后端的数据量（通过本地聚合）。这些都可以减少某些情况下的运维费用。

## 属性

属性是 Istio 策略和遥测功能中的基本概念。属性是用于描述特定服务请求或请求环境的属性的一小段数据。例如，属性可以指定特定请求的大小、操作的响应代码、请求来自的 IP 地址等。

每个属性都有一个名称和一个类型。该类型定义了该属性所持有的数据的种类。例如，属性可以具有 `STRING` 类型，这意味着它具有文本值，或者可以具有 `INT64` 类型，指示它具有 64 位整数值。

以下是一些具有相关值的示例属性：

{{< text plain >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.service: example
{{< /text >}}

Mixer 是 Istio 中用于实现策略和遥测功能的组件。Mixer 本质上是一个属性处理机。每个经过 Envoy sidecar 的请求都会调用 Mixer，为 Mixer 提供一组描述请求和请求周围环境的属性。基于 Envoy sidecar 的配置和给定的特定属性集，Mixer 会调用各种基础设施后端。

{{< image width="60%" ratio="42.60%"
    link="/docs/concepts/policies-and-telemetry/machine.svg"
    caption="属性机"
    >}}

### 属性词汇

给定的 Istio 部署中具有其可理解的一组固定的属性词汇表。具体词汇表由部署中使用的一组属性生成器确定。Istio 中的主要属性生产者是 Envoy，但专用的 Mixer 适配器也可以生成属性。

[这里](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)定义了大多数 Istio 部署中可用的通用基准属性集。

### 属性表达式

配置实例时使用属性表达式。在前面的例子中您已经看到了一些简单的属性表达式：

{{< text yaml >}}
destination_service: destination.service
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

冒号右侧的序列是属性表达式的最简单形式。前两行只包括了属性名称。`response_code` 标签的内容来自于 `request.code` 属性。

以下是条件表达式的示例：

{{< text yaml >}}
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

上面的表达式里，`destination_version` 标签被赋值为 `destination.labels["version"]`，如果 `destination.labels["version"]` 为空，则使用 `"unknown"` 代替。

有关详细信息，请参阅[属性表达式引用](/docs/reference/config/policy-and-telemetry/expression-language/)。

## 配置模型

控制策略和遥测功能涉及配置三种类型的资源：

- 配置一组处理程序，用于确定正在使用的适配器组及其操作方式。处理程序配置的一个例子：为 Statsd 后端提供带有 IP 地址的 `statsd` 适配器。
- 配置一组*实例* ，描述如何将请求属性映射到适配器输入。实例表示一个或多个适配器将操作的大量数据。例如，运维人员可能决定从诸如 `destination.service` 和 `response.code` 之类的属性中生成 `requestcount` metric 实例。
- 配置一组规则，这些规则描述了何时调用特定适配器及哪些实例。规则包含 *match* 表达式和 *action* 。匹配表达式控制何时调用适配器，而动作决定了要提供给适配器的一组实例。例如，规则可能会将生成的 `requestcount`  metric 实例发送到 `statsd` 适配器。

配置基于*适配器* 和*模板* ：

- **适配器** 封装了 Mixer 和特定基础设施后端之间的接口。
- **模板** 定义了从特定请求的属性到适配器输入的映射关系。一个适配器可以支持任意数量的模板。

## 处理器（Handler）

适配器封装了 Mixer 和特定外部基础设施后端进行交互的必要接口，例如 [Prometheus](https://prometheus.io/) 或者 [Stackdriver](https://cloud.google.com/logging)。各种适配器都需要参数配置才能工作。例如日志适配器可能需要 IP 地址和端口来进行日志的输出。

这里的例子配置了一个类型为 `listchecker` 的适配器。`listchecker` 适配器使用一个列表来检查输入。如果配置的是白名单模式且输入值存在于列表之中，就会返回成功的结果。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: listchecker
metadata:
  name: staticversion
  namespace: istio-system
spec:
  providerUrl: http://white_list_registry/
  blacklist: false
{{< /text >}}

`{metadata.name}.{kind}.{metadata.namespace}` 是 Handler 的完全限定名。上面定义的对象的 FQDN 就是 `staticversion.listchecker.istio-system`，他必须是唯一的。`spec` 中的数据结构则依赖于对应的适配器的要求。

有些适配器实现的功能就不仅仅是把 Mixer 和后端连接起来。例如 `prometheus` 适配器消费指标并以可配置的方式将它们聚合成分布或计数器。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: prometheus
metadata:
  name: handler
  namespace: istio-system
spec:
  metrics:

- name: request_count
  instance_name: requestcount.metric.istio-system
  kind: COUNTER
  label_names:
  - destination_service
  - destination_version
  - response_code
- name: request_duration
  instance_name: requestduration.metric.istio-system
  kind: DISTRIBUTION
  label_names:
  - destination_service
  - destination_version
  - response_code
    buckets:
    explicit_buckets:
      bounds: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
    {{< /text >}}

每个适配器都定义了自己格式的配置数据。适配器及其配置的详尽列表可以在[这里](/docs/reference/config/policy-and-telemetry/adapters/)找到。

## 实例（Instance）

配置实例将请求中的属性映射成为适配器的输入。下面的例子，是一个 metric 实例的配置，用于生成 `requestduration` metric。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: metric
metadata:
  name: requestduration
  namespace: istio-system
spec:
  value: response.duration | "0ms"
  dimensions:
    destination_service: destination.service | "unknown"
    destination_version: destination.labels["version"] | "unknown"
    response_code: response.code | 200
  monitored_resource_type: '"UNSPECIFIED"'
{{< /text >}}

注意 Handler 配置中需要的所有维度都定义在这一映射之中。每个模板都有自己格式的配置数据。完整的模板及其特定配置格式可以在[这里](/docs/reference/config/policy-and-telemetry/templates/)查阅。

## 规则（Rule）

规则用于指定使用特定实例配置调用某一 Handler 的时机。比如我们想要把 `service1` 服务中，请求头中带有 `x-user` 的请求的 `requestduration` 指标发送给 Prometheus Handler。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: promhttp
  namespace: istio-system
spec:
  match: destination.service == "service1.ns.svc.cluster.local" && request.headers["x-user"] == "user1"
  actions:
- handler: handler.prometheus
  instances:
  - requestduration.metric.istio-system
{{< /text >}}

规则中包含有一个 `match` 元素，用于前置检查，如果检查通过则会执行动作列表。动作中包含了一个实例列表，这个列表将会分发给 Handler。规则必须使用 Handler 和实例的完全限定名。如果规则、Handler 以及实例全都在同一个命名空间，命名空间后缀就可以在 FQDN 中省略，例如 `handler.prometheus`。
