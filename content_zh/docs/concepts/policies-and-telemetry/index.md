---
title: 策略与遥测
description: 描述策略实施和遥测机制。
weight: 40
keywords: [policies,telemetry,control,config]
---

Istio 提供灵活的模型来执行授权策略，并为网格中的服务收集遥测数据。

基础设施后端旨在提供用于构建服务的支持功能。它们包括访问控制系统、遥测捕获系统、配额执行系统以及计费系统等等。服务传统上直接与这些后端系统集成，创建硬耦合，还有沾染特定的语义和使用选项。

Istio 提供统一抽象，使得 Istio 可以与一组开放式基础设施后端进行交互。这样做是为了给运维提供丰富而深入的控制，同时不给服务开发人员带来负担。Istio 旨在改变层与层之间的边界，以减少系统复杂性，消除服务代码中的策略逻辑并将控制权交给运维。

Mixer 是负责提供策略控制和遥测收集的 Istio 组件：

{{< image width="75%" link="topology-without-cache.svg" caption="Mixer 拓扑" >}}

在每次请求执行先决条件检查之前以及在每次报告遥测请求之后，Envoy sidecar 在逻辑上调用 Mixer。
该 Sidecar 具有本地缓存​，从而可以在缓存中执行相对较大比例的前提条件检查。此外，sidecar 缓冲出站遥测，使其实际上不需要经常调用 Mixer。

在高层上，Mixer 提供：

- **后端抽象**。Mixer 隔离 Istio 的其余部分和各个基础设施后端的实现细节。
- **中介**。Mixer 允许运维对网格和基础设施后端之间的所有交互进行细化控制。

除了这些纯粹的功能方面，Mixer 还具有如下所述的[可靠性和可扩展性](#可靠性和延迟)方面的优势。

策略执行和遥测收集完全由配置驱动。可以[完全禁用这些功能](/zh/docs/setup/kubernetes/install/helm/)，并免除在 Istio 部署中运行 Mixer 组件的必要性。

## 适配器

Mixer 是高度模块化和可扩展的组件。它的一个关键功能就是把不同后端的策略和遥测收集系统的细节进行抽象，完成 Istio 其余部分和这些后端的隔离。

Mixer 处理不同基础设施后端的灵活性是通过使用通用插件模型实现的。每个插件都被称为 **Adapter**，Mixer 通过它们与不同的基础设施后端连接，这些后端可提供核心功能，例如日志、监控、配额、ACL 检查等。通过配置能够决定在运行时使用的确切的适配器套件，并且可以轻松扩展到新的或定制的基础设施后端。

{{< image width="35%" link="adapters.svg"
    alt="显示 Mixer 及其适配器"
    caption="Mixer 及其适配器"
    >}}

获取更多[适配器支持范围](/zh/docs/reference/config/policy-and-telemetry/adapters/)方面的内容。

## 可靠性和延迟

Mixer 是一个高可用的组件，其设计有助于提高整体可用性并减少网格中服务的平均延迟。其设计的关键方面带来以下好处：

- **无状态**。Mixer 是无状态的，因为它不管理任何自己的持久化存储。
- **加固**。Mixer 本身被设计成高度可靠的组件。设计目标是为任何单独的 Mixer 实例实现 > 99.999％ 的正常运行时间。
- **缓存和缓冲**。Mixer 被设计为累积大量瞬态短暂状态。

网格中每个服务都会有对应的 Sidecar 代理在运行，因此在内存消耗方面，Sidecar 必须厉行节约，这就限制了本地缓存和缓冲的可能数量。然而，独立运行 的 Mixer 可以使用相当大的缓存和输出缓冲区。因此，Mixer 可用作 Sidecar 的高度扩展且高度可用的二级缓存。

{{< image width="75%" link="topology-with-cache.svg"  caption="Mixer 拓扑" >}}

由于 Mixer 的预期可用性远高于大多数基础设施后端（通常这些可用性可能达到 99.9％）。Mixer 的本地缓存和缓冲不仅有助于减少延迟，而且即使在后端无响应时也能继续运行，从而有助于屏蔽基础设施后端故障。

最后，Mixer 的缓存和缓冲有助于减少对后端的调用频率，并且有时可以减少发送到后端的数据量（通过本地聚合）。这些都可以减少某些情况下的运维费用。

## 属性

属性是 Istio 策略和遥测功能中的基本概念。属性是用于描述特定服务请求或请求环境的属性的一小段数据。例如，属性可以被赋值为特定请求的大小、操作的响应代码、请求来自的 IP 地址等。

每个属性都有一个名称和一个类型。该类型定义了该属性所持有的数据的种类。例如，属性可以是 `STRING` 类型，这意味着它的值是文本类型；或者可以是 `INT64` 类型，指示它的值是 64 位整数。

以下是一些具有相关值的示例属性：

{{< text plain >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.service: example
{{< /text >}}

Mixer 本质上是一个属性处理机。每个经过 Envoy sidecar 的请求都会调用 Mixer，为 Mixer 提供一组描述请求和请求周围环境的属性。基于 Envoy sidecar 的配置和给定的特定属性集，Mixer 会调用各种基础设施后端。

{{< image width="60%" link="machine.svg" caption="属性机" >}}

### 属性词汇

给定的 Istio 部署中具有其可理解的一组固定的属性词汇表。具体词汇表由部署中使用的一组属性生成器确定。Istio 中的主要属性生产者是 Envoy，但专用的 Mixer 适配器也可以生成属性。

[这里](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)定义了大多数 Istio 部署中可用的通用基准属性集。

### 属性表达式

配置 [Instance](/zh/docs/concepts/policies-and-telemetry/#实例-instance) 时要使用属性表达式。下面是一些简单的属性表达式示例：

{{< text yaml >}}
destination_service: destination.service
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

冒号右侧的序列是属性表达式的最简单形式。前两行只包括了属性名称。`response_code` 标签的内容来自于 `response.code` 属性。

以下是条件表达式的示例：

{{< text yaml >}}
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

上面的表达式里，`destination_version` 标签被赋值为 `destination.labels["version"]`，如果 `destination.labels["version"]` 为空，则使用 `"unknown"` 代替。

有关详细信息，请阅读[属性表达式参考](/zh/docs/reference/config/policy-and-telemetry/expression-language/)。

## 配置模型

Istio 通过一个通用模型进行策略和遥测功能的配置，目的是让运维人员能够控制授权策略和遥测收集的方方面面。在保持模型简单的同时，还提供了足以控制 Istio 各项功能的强大能力。

策略和遥控功能的控制能力包含了三种类型资源的配置：

- 配置一组**处理器（Handler）**，用于确定正在使用的适配器组及其操作方式。处理器配置的一个例子如：为 Statsd 后端提供带有 IP 地址的 `statsd` 适配器。
- 配置一组**实例（Instance）**，描述如何将请求属性映射到适配器输入。实例表示一个或多个适配器将操作的各种数据。例如，运维人员可能决定从诸如 `destination.service` 和 `response.code` 之类的属性中生成 `requestcount` 指标的实例。
- 配置一组**规则（Rule）**，这些规则描述了何时调用特定适配器及哪些实例。规则包含 `match` 表达式和 `action`。`match` 表达式控制何时调用适配器，而 `action` 决定了要提供给适配器的一组实例。例如，规则可能会将生成的 `requestcount` 实例发送到 `statsd` 适配器。

配置基于**适配器**和**模板（Template）** ：

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

有些适配器实现的功能就不仅仅是把 Mixer 和后端连接起来。例如 `prometheus` 适配器采集指标并以可配置的方式将它们聚合成分布或计数器。

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

每个适配器都定义了自己格式的配置数据。适配器及其配置的详尽列表可以在[这里](/zh/docs/reference/config/policy-and-telemetry/adapters/)找到。

## 实例（Instance）

配置实例将请求中的属性映射成为适配器的输入。下面的例子，是一个 metric 实例的配置，用于生成 `requestduration` 指标。

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

注意 Handler 配置中需要的所有维度都定义在这一映射之中。每个模板都有自己格式的配置数据。完整的模板及其特定配置格式可以在[这里](/zh/docs/reference/config/policy-and-telemetry/templates/)查阅。

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

规则中包含有一个 `match` 元素，用于前置检查，如果检查通过则会执行 `action` 列表。`action` 中包含了一个实例列表，这个列表将会分发给 Handler。规则必须使用 Handler 和实例的完全限定名。如果规则、Handler 以及实例全都在同一个命名空间，命名空间后缀就可以在 FQDN 中省略，例如 `handler.prometheus`。
