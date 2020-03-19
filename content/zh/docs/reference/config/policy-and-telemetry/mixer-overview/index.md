---
title: Mixer 配置模型
description: 描述 Istio 策略执行和遥测机制的配置模型。
weight: 5
keywords: [policies,telemetry,control,config]
aliases:
    - /zh/docs/concepts/policy-and-control/mixer.html
    - /zh/docs/concepts/policy-and-control/mixer-config.html
    - /zh/docs/concepts/policy-and-control/attributes.html
    - /zh/docs/concepts/policies-and-telemetry/overview/
    - /zh/docs/concepts/policies-and-telemetry/config/
---

Istio 提供了一种灵活的模型来强制执行授权策略并为网格中的服务收集遥测数据。

基础架构后端旨在提供用于构建服务的支持功能。它们包括访问控制系统，遥测捕获系统，配额执行系统，计费系统等。传统上，服务直接与这些后端系统集成，进行强耦合，并引入特定的语义和用法选项。

Istio 提供了统一抽象，使 Istio 可以与一组开放式基础架构后端进行交互。这样做是为了向操作员提供丰富而深入的控制，同时又不给服务开发人员带来负担。Istio 旨在更改各层之间的边界，以降低系统复杂性，从服务代码中消除策略逻辑并将控制权交给操作者。

Mixer 是 Istio 的组件，负责提供策略控制和遥测收集：

{{< image width="55%" link="./topology-without-cache.svg" caption="Mixer Topology" >}}

在每个请求执行前提条件检查之前，以及在每个请求报告遥测之后，Envoy sidecar 都会在逻辑上调用 Mixer。
Sidecar 具有本地缓存，因此大部分的前提检查可以在缓存中执行。此外，sidecar 缓冲传出遥测，使其较少的调用 Mixer。

总体而言，Mixer 提供：

* **Backend Abstraction**。Mixer 将 Istio 的其余部分和各个基础架构后端的实现细节隔离开来。

* **Intermediation**。Mixer 使操作员可以对网格和基础架构后端之间的所有交互进行精细控制。

策略实施和遥测收集完全由配置驱动。默认情况下，策略检查是禁用的，从而避免了需要通过 Mixer 策略组件的情况。有关更多信息，请参考[安装选项](/zh/docs/reference/config/installation-options/)。

## 适配器{#adapters}

Mixer 是高度模块化和可扩展的组件。它的主要功能之一是抽象出不同的策略和遥测后端系统的细节，
使 Istio 的其余部分可以不关注这些后端。

Mixer 处理不同基础架构后端的灵活性来自其通用插件模型。
每个插件都被称为 *适配器* ，它们允许 Mixer 与提供基础功能（例如日志记录、监视、配额、ACL 检查等）的不同基础架构后端进行交互。运行时使用的适配器的确切集合是通过配置确定的，可以轻松扩展以针对新的或定制的基础架构后端。

{{< image width="80%" link="./adapters.svg"
    alt="Showing Mixer with adapters."
    caption="Mixer and its Adapters"
    >}}

了解有关[适配器支持](/zh/docs/reference/config/policy-and-telemetry/adapters/)的更多信息。

## 属性{#attributes}

属性是 Istio 策略和遥测功能的基本概念。
属性是一小部分数据，用来描述特定服务请求或请求所需环境的单一特性。例如，属性可以指定特定请求的大小、操作的响应代码、请求来自的 IP 地址等。

每个属性都有一个名称和一个类型。类型定义属性保存的数据类型。例如，具有 `STRING` 类型的属性代表它有一个文本值，或者具有 `INT64` 类型的属性表示它具有 64 位整数值。

以下是一些示例属性及其关联值：

{{< text plain >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: [192 168 0 1]
destination.service.name: example
{{< /text >}}

Mixer 本质上是一种属性处理器。Envoy sidecar 为每个请求调用 Mixer，为 Mixer 提供一组属性，描述请求和请求所需环境。根据其配置和给予的特定属性集，Mixer 生成对各种基础架构后端的调用。

{{< image width="60%" link="./machine.svg" caption="Attribute Machine" >}}

### 属性词汇表{#attribute-vocabulary}

给定的 Istio deployment 具有它了解的固定属性词汇表。该特定词汇表由 deployment 中使用的一组属性生成器确定。尽管专用的 Mixer 适配器也可以生成属性，但 Istio 中主要的属性生成器是 Envoy。

了解有关 [Istio 中大多数部署可用的通用基准属性集](/zh/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)的更多信息。

### 属性表达式{#attribute-expressions}

当配置[实例](#instances)时需要使用使用属性表达式。
这是一个使用表达式的示例：

{{< text yaml >}}
destination_service: destination.service.host
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

冒号右侧的序列是属性表达的最简单形式。前两个仅由属性名称组成。`response_code` 标签由 `response.code` 属性分配值。

这是一个条件表达式的示例：

{{< text yaml >}}
destination_version: destination.labels["version"] | "unknown"
{{< /text >}}

通过上述操作，`destination_version` 标签被分配的值为 `destination.labels ["version"]`。但是，如果属性不存在，将使用 `"unknown"` 值。

有关更多信息，请参阅[属性表达式](/zh/docs/reference/config/policy-and-telemetry/expression-language/)页面。

## 配置模型{#configuration-model}

Istio 的策略和遥测功能通过通用模型进行配置，该模型旨在使操作员可以控制授权策略和遥测收集的各个方面。我们关注于保持模型简单，同时又可以按比例控制 Istio 的许多功能。

控制策略和遥测功能涉及配置三种类型的资源：

* 配置一组 *handlers* ，用来确定正在使用的适配器集及其运行方式。如 handler 配置的示例：为 Statsd 后端提供带有 IP 地址的 `statsd` 适配器。

* 配置一组 *instances* ，用来描述如何将请求属性映射到适配器输入中。
Instances 代表一个或多个适配器将在其上操作的数据块。例如。操作员可以从如 `destination.service.host` 和 `response.code` 属性中生成 `requestcount` 指标实例。

* 配置一组 *rules* ，用来描述何时调用特定的适配器以及给定某个 instance。
Rules 由 *match* 表达式和 *actions* 组成。该匹配表达式控制何时调用适配器，而 action 确定提供适配器的实例集。例如，rule 可能会将生成的 `requestcount` 指标实例发送到 `statsd` 适配器。

配置是基于 *adapters* 和 *templates* ：

* **Adapters** 封装了 Mixer 与特定基础架构后端交互所需的逻辑。

* **Templates** 定义用于指定从属性到适配器输入的请求映射的架构。
给定的适配器可以支持任意数量的模板。

### Handlers{#handlers}

适配器封装了 Mixer 与特定的外部基础结构后端例如 [Prometheus](https://prometheus.io) 或 [Stackdriver](https://cloud.google.com/logging) 交互所需的逻辑。
_handler_ 是负责保存适配器所需的配置状态的资源。例如，一个日志适配器可能需要日志收集后端的 IP 地址和端口。

这是一个示例，显示了如何为适配器创建 handler。`listchecker` 适配器对照列表检查输入值。
如果将适配器配置为白名单，则在列表中找到输入值时，它将返回成功。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: staticversion
  namespace: istio-system
spec:
  compiledAdapter: listchecker
  params:
    providerUrl: http://white_list_registry/
    blacklist: false
{{< /text >}}

`params` 中的数据模式取决于所配置的特定适配器。

某些适配器实现的功能不局限于将 Mixer 连接到后端。
例如，`prometheus` 适配器使用指标并以可配置的方式将它们整合为分布式或计数器。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: handler
metadata:
  name: promhandler
  namespace: istio-system
spec:
  compiledAdapter: prometheus
  params:
    metrics:
    - name: request_count
      instance_name: requestcount.instance.istio-system
      kind: COUNTER
      label_names:
      - destination_service
      - destination_version
      - response_code
    - name: request_duration
      instance_name: requestduration.instance.istio-system
      kind: DISTRIBUTION
      label_names:
      - destination_service
      - destination_version
      - response_code
      buckets:
        explicit_buckets:
          bounds: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
{{< /text >}}

每个适配器定义自己的特定格式的配置数据。了解更多有关[全部适配器及其特定的配置格式](/zh/docs/reference/config/policy-and-telemetry/adapters/)的信息。

### Instances{#instances}

Instance 配置指定了请求属性到适配器输入的映射。
以下是一个指标 instance 配置的示例，用来生成 `requestduration` 指标。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: instance
metadata:
  name: requestduration
  namespace: istio-system
spec:
  compiledTemplate: metric
  params:
    value: response.duration | "0ms"
    dimensions:
      destination_service: destination.service.host | "unknown"
      destination_version: destination.labels["version"] | "unknown"
      response_code: response.code | 200
    monitored_resource_type: '"UNSPECIFIED"'
{{< /text >}}

请注意，需要在映射中指定了处理程序配置中期望的所有情况。
模板定义了各个实例的特定必需内容。了解更多关于[模板及其特定的配置格式](/zh/docs/reference/config/policy-and-telemetry/templates/)的信息。

### Rules{#rules}

Rules 指定何时使用特定 instance 调用特定 handler。
考虑一个示例，如果目标服务是 `service1` 并且 `x-user` 请求标头具有特定值，您希望把 `requestduration` 指标传递给 `prometheus` 处理程序。

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: promhttp
  namespace: istio-system
spec:
  match: destination.service.host == "service1.ns.svc.cluster.local" && request.headers["x-user"] == "user1"
  actions:
  - handler: promhandler
    instances: [ requestduration ]
{{< /text >}}

Rule 包含 `match` 条件表达式和条件为 true 时要执行的 action 的列表。
action 指定要传递给 handler 的 instance 列表。
规则必须使用 handler 和 instance 的标准名称。
如果 rule、handlers、instances 都在同一命名空间中,
命名空间后缀可以从标准名称中删除，如 `promhandler` 所见。
