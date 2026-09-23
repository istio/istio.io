---
title: 配置链路采样
description: 了解有关如何在代理上配置链路采样的不同方法。
weight: 4
keywords: [sampling,telemetry,tracing,opentelemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio 提供了多种配置链路采样的方法。
在此页面中，您将学习并了解所有配置采样的不同方式。

## 开始之前 {#before-you-begin}

1.  确保您的应用程序按照[此处](/zh/docs/tasks/observability/distributed-tracing/overview/)描述的方式传播链路追踪标头。

## 可用的链路采样配置 {#available-trace-sampling-configurations}

1.  百分比采样器：选择用于链路生成的请求百分比的随机采样率。

1.  自定义 OpenTelemetry 采样器：自定义采样器实现，必须与 `OpenTelemetryTracingProvider` 进行配对。

### 百分比采样器 {#percentage-sampler}

{{< boilerplate telemetry-tracing-tips >}}

随机采样率百分比使用指定的百分比值来选择要采样的请求。

采样率应在 0.0 至 100.0 范围内，精度为 0.01。
例如，要跟踪每 10000 个请求中的 5 个请求，请使用 0.05 作为此处的值。

您可以通过三种方式配置随机采样率：

#### Telemetry API {#telemetry-api}

可以在各种范围内配置采样：网格范围、命名空间或工作负载，从而提供极大的灵活性。
要了解更多信息，请参阅 [Telemetry API](/zh/docs/tasks/observability/telemetry/) 文档。

安装 Istio 时无需在 `defaultConfig` 中设置 `sampling`：

{{< text syntax=bash snip_id=install_without_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

通过 Telemetry API 启用链路追踪提供程序并设置 `randomSamplingPercentage`：

{{< text syntax=bash snip_id=enable_telemetry_with_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
   name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 10
EOF
{{< /text >}}

#### 实用 `MeshConfig` {#using-meshconfig}

随机百分比采样可以通过 `MeshConfig` 进行全局配置。

{{< text syntax=bash snip_id=install_default_sampling >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

然后，通过 Telemetry API 启用链路追踪提供程序。
请注意，我们在这里不设置 `randomSamplingPercentage`。

{{< text syntax=bash snip_id=enable_telemetry_no_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - providers:
    - name: otel-tracing
EOF
{{< /text >}}

#### 使用 `proxy.istio.io/config` 注解 {#using-the-proxy.istio.io/config-annotation}

您可以将 `proxy.istio.io/config` 注解添加到 Pod 元数据规范中，
以覆盖任何网格范围的采样设置。

例如，要覆盖上面的网格范围的采样，您可以将以下内容添加到 Pod 清单中：

{{< text syntax=yaml snip_id=none >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: curl
spec:
  ...
  template:
    metadata:
      ...
      annotations:
        ...
        proxy.istio.io/config: |
          tracing:
            sampling: 20
    spec:
      ...
{{< /text >}}

### 自定义 OpenTelemetry 采样器 {#custom-opentelemetry-sampler}

OpenTelemetry 规范定义了 [Sampler API](https://opentelemetry.io/docs/specs/otel/trace/sdk/#sampler)。
Sampler API 支持构建自定义采样器，该采样器可以执行更智能、更高效的采样决策，
例如 [Probability Sampling（概率采样）](https://opentelemetry.io/docs/specs/otel/trace/tracestate-probability-sampling-experimental/)。

然后，此类采样器可以与
[`OpenTelemetryTracingProvider`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider) 配对。

{{< quote >}}
驻留在代理中的采样器实现，
可以在 [Envoy OpenTelemetry Samplers](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers) 中找到。
{{< /quote >}}

当前在 Istio 中的自定义采样器配置：

- [Dynatrace 采样器](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)

自定义采样器通过 `MeshConfig` 进行配置。以下是配置 Dynatrace 采样器的示例：

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 443
        service: abc.live.dynatrace.com/api/v2/otlp
        http:
          path: "/api/v2/otlp/v1/traces"
          timeout: 10s
          headers:
            - name: "Authorization"
              value: "Api-Token dt0c01."
        dynatrace_sampler:
          tenant: "abc"
          cluster_id: 123
{{< /text >}}

### 优先顺序 {#order-of-precedence}

通过多种配置采样的方法，了解每种方法的优先顺序非常重要。

使用随机百分比采样器时，优先顺序为：

<table><tr><td>Telemetry API > Pod 注解 > <code>MeshConfig</code> </td></tr></table>

这意味着，如果在上述所有内容中都定义了一个值，
则 Telemetry API 中的值就是被选定的值。

配置自定义 OpenTelemetry 采样器时，优先顺序为：

<table><tr><td>自定义 OTel 采样器 > （Telemetry API | Pod 注解 | <code>MeshConfig</code>）</td></tr></table>

这意味着，如果配置了自定义 OpenTelemetry 采样器，它将覆盖所有其他方法。
此外，随机百分比值设置为 `100` 并且无法更改。这很重要，
因为自定义采样器需要接收 100% 的 Span 才能正确执行其决策。

## 部署 OpenTelemetry 收集器 {#deploy-the0-opentelemetry-collector}

{{< boilerplate start-otel-collector-service >}}

## 部署 Bookinfo 应用程序 {#deploy-the-bookinfo-application}

部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## 使用 Bookinfo 示例生成链路 {#generating-traces-using-the-bookinfo-sample}

1.  当 Bookinfo 应用程序启动并运行时，
    访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成链路信息。

    {{< boilerplate trace-generation >}}

## 清理 {#cleanup}

1.  删除 Telemetry 资源：

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  使用 control-C 或下面命令删除可能仍在运行的任何 `istioctl` 进程：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

1.  卸载 OpenTelemetry Collector：

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}
