---
title: 配置
description: 概述用于配置 Istio 策略执行和遥测收集功能的关键概念。
weight: 30
keywords: [policies,telemetry,control,config]
aliases:
    - /docs/concepts/policy-and-control/mixer-config.html
    - /docs/concepts/policy-and-control/attributes.html
---

Istio 的策略和遥测功能是通过通用模式进行配置，旨在让运维人员可以控制授权策略和遥测收集的各个方面。重点在于保持模型简单的同时，强大到足以控制 Istio 的大量功能。

## 属性

属性是 Istio 策略和遥测功能的基本概念。属性只有很少的数据，它可以用来描述特定服务请求或请求环境的某个特性。例如，属性可以指定特定请求的大小、操作的响应代码或请求来自的 IP 地址等。

每个属性都有其名称和类型。类型定义该属性所持有的数据的种类。例如，属性可以是 `STRING` 类型，这意味着它具有文本值，或者可以是 `INT64` 类型，指示它具有 64 位整数值。

以下是一些具有相关值的示例属性：

```plain
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.service: example
```

Mixer 是实现策略和遥测功能的 Istio 组件。Mixer 本质上是一个属性处理机器。Envoy sidecar 为每个请求调用 Mixer，为 Mixer 提供一组描述请求和请求周围环境的属性。基于它的配置和给定的特定属性集，Mixer 会调用各种基础设施后端。

{{< image width="60%" ratio="42.60%"
    link="/docs/concepts/policies-and-telemetry/config/machine.svg"
    caption="属性机"
    >}}

### 属性词汇表

给定的 Istio 部署具有固定的它可以理解的属性词汇表。具体词汇表由部署中使用的一组属性生成器确定。 Istio 中的主要属性生成器是 Envoy，但特定的 Mixer Adapter 也可以生成属性。

大多数Istio部署中可用的通用基准属性集在[这里](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)定义。

## 配置模型

控制策略和遥测的功能涉及配置三种类型的资源：

- 配置一组*处理程序*（handler），确定要使用的适配器组及其操作方式。为 statsd 后端提供带有 IP 地址的 `statsd` 适配器是处理程序配置的例子。
- 配置一组*实例*（instance），描述如何将请求属性映射到适配器输入中。实例表示一个或多个适配器将操作的大量数据。例如，运维可能决定从诸如 `destination.service` 和 `response.code` 之类的属性中生成 `requestcount` 度量实例。
- 配置一组*规则*（rule），描述在何时调用特定适配器以及给定哪些实例。规则包含匹配表达式和动作（action）。匹配表达式控制何时调用适配器，而动作（action）决定要供给给适配器的一组实例。例如，规则可能会将生成的 `requestcount` 度量实例发送到 `statsd` 适配器。

配置基于*适配器*和*模板*：

- **适配器**封装了连接 Mixer 与特定基础设施后端所需的逻辑。
- **模板**定义了用于指定从属性到适配器输入的请求映射的模式。给定的适配器可以支持任意数量的模板。

## 处理器（handler）

适配器封装了连接 Mixer 与 [Prometheus](https://prometheus.io/) 或 [Stackdriver](https://cloud.google.com/logging) 等特定外部基础设施后端所需的逻辑。单个适配器通常需要操作参数才能完成工作。例如，日志适配器可能需要日志接收器的 IP 地址和端口。

下面是一个示例，显示如何配置 kind = `listchecker` 的适配器。listchecker 适配器根据列表检查输入值。如果适配器配置为白名单，则在列表中找到输入值时，它将返回成功。

```yaml
apiVersion: config.istio.io/v1alpha2
kind: listchecker
metadata:
  name: staticversion
  namespace: istio-system
spec:
  providerUrl: http://white_list_registry/
  blacklist: false
```

`{metadata.name}.{kind}.{metadata.namespace}` 是处理程序的完全限定名称。上述处理程序的完全限定名称是 `staticversion.listchecker.istio-system`，它必须是唯一的。`spec` 中的数据模式取决于配置的特定适配器。

一些适配器实现了超越将 Mixer 连接到后端的功能。例如，`prometheus` 适配器消费指标并以可配置的方式将它们聚合为分布或计数器。

```yaml
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
```

每个适配器定义其自己的特定格式的配置数据。详细的适配器套件及其特定的配置格式可以在[这里](/docs/reference/config/policy-and-telemetry/adapters/)找到。

## 实例（instance）

实例配置指定从属性到适配器输入的请求映射。以下是生成 `requestduration` 度量的度量实例配置示例。

```yaml
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
```
请注意，映射中指定了 处理程序配置中预期的所有维度都在映射中指定。模板定义各个实例具体要求的内容。详细的模板集及其特定的配置格式可以在[这里](/docs/reference/config/policy-and-telemetry/templates/)找到。

## 规则（rule）

规则指定何时用特定实例调用特定处理程序。考虑一个例子，如果目标服务是 `service1`，并且 `x-user` 请求 header 具有特定值，那么希望向 prometheus 处理程序提供 `requestduration` 指标。

```yaml
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
```
规则包含 `match` 断言表达式和断言为真时执行的动作列表。动作指定要传递给处理程序的实例列表。规则必须使用处理程序和实例的完全限定名称。如果规则，处理程序和实例都在同一个命名空间内，则可以从 `handler.prometheus` 中的完全限定名中删除命名空间后缀。

## 属性表达式

属性表达式在配置实例时使用。在前面的例子中已经看到了一些简单的属性表达式：

```yaml
destination_service: destination.service
response_code: response.code
destination_version: destination.labels["version"] | "unknown"
```
冒号右侧的序列是属性表达式的最简单形式。前两个只包含属性名称。`response_code` 标签被分配了 `request.code` 属性的值。

这是条件表达式的例子：

```yaml
destination_version: destination.labels["version"] | "unknown"
```

如上所述，`destination_version` 标签被分配了 `destination.labels["version"]` 的值。但是，如果该属性不存在，则使用文字 `"unknown"`。

有关详细信息，请参阅[属性表达式参考](/docs/reference/config/policy-and-telemetry/expression-language/)。

## 下一步

- 学习如何[配置遥测收集](/docs/tasks/telemetry/)。
- 学习如何[配置策略执行](/docs/tasks/policy-enforcement/)。
- 学习[支持的适配器](/docs/reference/config/policy-and-telemetry/adapters/)。
- 查阅阐述 [Mixer 之适配器模型](/blog/2017/adapter-model/)的博客。
