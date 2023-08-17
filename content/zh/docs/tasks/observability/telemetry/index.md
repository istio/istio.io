---
title: Telemetry API
description: 本任务向您演示如何配置 Telemetry API。
weight: 0
keywords: [telemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Alpha
---

{{< boilerplate alpha >}}

Istio 提供 [Telemetry API](/zh/docs/reference/config/telemetry/)，
能够灵活地配置[指标](/zh/docs/tasks/observability/metrics/)、
[访问日志](/zh/docs/tasks/observability/logs/)和[追踪](/zh/docs/tasks/observability/distributed-tracing/)。

## 使用 API {#using-api}

### 作用域、继承和覆盖  {#scope-inheritance-and-overrides}

在 Istio 配置层次结构中，Telemetry API 资源从父级资源中继承配置：

1.  根配置命名空间（例如 `istio-system`）
1.  本地命名空间（不带工作负载 `selector` 的作用于命名空间的资源）
1.  工作负载（带有工作负载 `selector` 的作用于命名空间的资源）

`istio-system` 这类根配置命名空间中的 Telemetry API 资源提供了网格范围的默认行为。
根配置命名空间中的所有工作负载特定选择算符都将被忽略/拒绝。
在根配置命名空间中定义多个网格范围的 Telemetry API 资源是无效的。

通过将新的 `Telemetry` 资源应用到（不带工作负载选择算符的）目标命名空间中，
可以针对网格范围的配置达成特定于命名空间的覆盖。命名空间配置中指定的所有字段都将完全覆盖
（根配置命名空间中的）父级配置中的字段。

**使用工作负载选择算符** 将新的 Telemetry 资源应用到目标命名空间中，可以实现特定于工作负载的覆盖。

### 工作负载选择  {#workload-selection}

命名空间内的单个工作负载通过 [`selector`](/zh/docs/reference/config/type/workload-selector/#WorkloadSelector)
进行选择，这允许基于标签选择工作负载。

使用 `selector` 让两个不同的 `Telemetry` 资源选择相同的工作负载是无效的。
同样在未指定 `selector` 时在一个命名空间中设定两个不同的 `Telemetry` 资源也是无效的。

### 提供程序选择  {#provider-selection}

Telemetry API 使用提供程序的概念表明要使用的集成协议或类型。
可以在 [`MeshConfig`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)
中配置提供程序。

`MeshConfig` 中的提供程序配置示例设置如下：

{{< text yaml >}}
data:
  mesh: |-
      extensionProviders: # The following content defines two example tracing providers.
      - name: "localtrace"
        zipkin:
          service: "zipkin.istio-system.svc.cluster.local"
          port: 9411
          maxTagLength: 56
      - name: "cloudtrace"
        stackdriver:
          maxTagLength: 256
{{< /text >}}

为了方便，Istio 默认设置随附了几个开箱即用的提供程序：

| 提供程序名称 | 功能                    |
| ------------- | -------------------------------- |
| `prometheus`  | 指标                          |
| `stackdriver` | 指标、追踪、访问日志 |
| `envoy`       | 访问日志                   |

此外，还可以设置[默认的提供程序](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-DefaultProviders)，
便于在 `Telemetry` 资源未指定提供程序时将使用这个默认的提供程序。

{{< tip >}}
如果您正使用 [Sidecar](/zh/docs/reference/config/networking/sidecar/) 配置，
不要忘记添加提供程序的服务。
{{< /tip >}}

{{< tip >}}
提供程序不支持 `$(HOST_IP)`。如果您正以代理（agent）模式运行收集器，
您可以使用[服务内部流量策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service-traffic-policy/#using-service-internal-traffic-policy)，
并将 `InternalTrafficPolicy` 设置为 `Local` 以获得更好的性能。
{{< /tip >}}

## 示例  {#examples}

### 配置网格范围的行为  {#configuring-mesh-wide-behavior}

Telemetry API 资源从网格的根配置命名空间（通常是 `istio-system`）中进行继承。
要配置网格范围的行为，可以在根配置命名空间中添加新的（或编辑现有的）`Telemetry` 资源。

以下是上一节中使用提供程序配置的示例配置：

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: localtrace
    customTags:
      foo:
        literal:
          value: bar
    randomSamplingPercentage: 100
{{< /text >}}

此配置覆盖源于 `MeshConfig` 的默认提供程序，将网格默认设置为 `localtrace` 提供程序。
它还将网格范围的抽样百分比设置为 `100`，配置一个标记以名称 `foo` 和赋值 `bar` 添加到所有链路 span。

### 配置作用于命名空间的追踪行为  {#configuring-namespace-scoped-tracing-behavior}

要定制个别命名空间的行为，添加 `Telemetry` 资源到目标命名空间。
命名空间资源中指定的所有字段将完全覆盖从配置层次结构中继承的字段配置。
例如：

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: namespace-override
  namespace: myapp
spec:
  tracing:
  - customTags:
      userId:
        header:
          name: userId
          defaultValue: unknown
{{< /text >}}

当用先前网格范围的示例配置部署到网格中时，这将造成 `myapp` 命名空间中的追踪行为，
将链路 span 发送到 `localtrace` 提供程序并随机以 `100%` 的比率选择追踪请求，
但这会使用名称 `userId` 和 `userId` 请求头中获取的值为每个 span 设置自定义标记。
重要的是，在 `myapp` 命名空间中将不会使用来自父级配置的 `foo: bar` 标记。
自定义标记行为将完全覆盖 `mesh-default.istio-system` 资源中配置的行为。

{{< tip >}}
`Telemetry` 资源中的所有配置将完全覆盖配置层次结构中其父级资源的配置。这包括提供程序选择。
{{< /tip >}}

### 配置特定于工作负载的行为  {#configuring-workload-specific-behavior}

要定制个别工作负载的行为，添加 `Telemetry` 资源到目标命名空间并使用 `selector`。
特定工作负载资源中指定的所有字段将完全覆盖从配置层次结构中继承的字段配置。

例如：

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: workload-override
  namespace: myapp
spec:
  selector:
    matchLabels:
      service.istio.io/canonical-name: frontend
  tracing:
  - disableSpanReporting: true
{{< /text >}}

这种情况下，对于 `myapp` 命名空间中的 `frontend` 工作负载，追踪将被禁用。
Istio 仍将转发追踪头，但没有 span 将被报告给配置的追踪提供程序。

{{< tip >}}
让带有工作负载选择算符的两个 `Telemetry` 资源选择相同的工作负载是无效的。
这种情况下，此行为属于未定义的状态。
{{< /tip >}}
