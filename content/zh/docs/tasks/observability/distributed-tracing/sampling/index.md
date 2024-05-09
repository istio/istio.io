---
title: 链路采样
description: Learn the different approaches on how to configure trace sampling on the proxies.Learn the different approaches on how to configure trace sampling on the proxies.
weight: 10
keywords: [sampling,telemetry,tracing,opentelemetry]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio provides multiple ways to configure trace sampling. In this page you will learn and understand all the different ways sampling can be configured.
Istio 提供了多种配置跟踪采样的方法。
在此页面中，您将学习并了解配置采样的所有不同方式。

## Before you begin
## 开始之前 {#before-you-begin}

1.  Ensure that your applications propagate tracing headers as described [here](/docs/tasks/observability/distributed-tracing/overview/).
1. 确保您的应用程序按照[此处](/zh/docs/tasks/observability/distributed-tracing/overview/)的描述传播链路追踪标头。

## Available trace sampling configurations
## 可用的链路采样配置 {#available-trace-sampling-configurations}

1.  Percentage Sampler: A random sampling rate for percentage of requests that will be selected for trace generation.
1. 百分比采样器：选择用于跟踪生成的请求百分比的随机采样率。

1.  Custom OpenTelemetry Sampler: A custom sampler implementation, that must be paired with the `OpenTelemetryTracingProvider`.
1. 自定义 OpenTelemetry Sampler：自定义采样器实现，必须与“OpenTelemetryTracingProvider”配对。

1.  Deploy the OpenTelemetry Collector
1.部署OpenTelemetry收集器

    {{< boilerplate start-otel-collector-service >}}

### Percentage Sampler
### 百分比采样器 {#percentage-sampler}

{{< boilerplate telemetry-tracing-tips >}}

The random sampling rate percentage uses the specified percentage value to pick which requests to sample.
随机采样率百分比使用指定的百分比值来选择要采样的请求。

The sampling rate should be in the range of 0.0 to 100.0 with a precision of 0.01. For example, to trace 5 requests out of every 10000, use 0.05 as the value here.
采样率应在 0.0 至 100.0 范围内，精度为 0.01。 例如，要跟踪每 10000 个请求中的 5 个请求，请使用 0.05 作为此处的值。

There are three ways you can configure the random sampling rate:
您可以通过三种方式配置随机采样率：

#### Globally via `MeshConfig`
#### 通过 `MeshConfig` 进行全局配置 {#globally-via-meshconfig}

Random percentage sampling can be configured globally via `MeshConfig`.
随机百分比采样可以通过“MeshConfig”进行全局配置。

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

Then enable the tracing provider via Telemetry API. Note we don't set `randomSamplingPercentage` here.
然后通过 Telemetry API 启用跟踪提供程序。 请注意，我们在这里不设置“randomSamplingPercentage”。

{{< text syntax=bash snip_id=enable_telemetry_no_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
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

#### Pod annotation `proxy.istio.io/config`
#### Pod 注释 `proxy.istio.io/config` {#pod-annotation-proxy.istio.io/config}

You can add the `proxy.istio.io/config` annotation to your Pod metadata specification to override any mesh-wide sampling settings.
您可以将 `proxy.istio.io/config` 注释添加到 Pod 元数据规范中，以覆盖任何网格范围的采样设置。

For instance, to override the mesh-wide sampling above, you would add the following to your pod manifest:
例如，要覆盖上面的网格范围采样，您可以将以下内容添加到 pod 清单中：

{{< text syntax=yaml snip_id=none >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
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

#### Telemetry API
#### 遥测 API {#telemetry-api}

The random percentage sampler can also be configured via the Telemetry API. Via the Telemetry API, sampling can be configured on various scopes: mesh-wide, namespace or workload, offering great flexibility. To learn more, please see the [Telemetry API](/docs/tasks/observability/telemetry/) documentation.
随机百分比采样器也可以通过遥测 API 进行配置。 通过遥测 API，可以在各种范围内配置采样：网格范围、命名空间或工作负载，提供了极大的灵活性。 要了解更多信息，请参阅[遥测 API](/docs/tasks/observability/telemetry/) 文档。

Install Istio without setting `sampling` inside `defaultConfig`:
安装 Istio，而不在“defaultConfig”中设置“sampling”：

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

Then enable the tracing provider via Telemetry API and set the `randomSamplingPercentage`.
然后通过 Telemetry API 启用跟踪提供程序并设置“randomSamplingPercentage”。

{{< text syntax=bash snip_id=enable_telemetry_with_sampling >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
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

### Custom OpenTelemetry Sampler
### 自定义 OpenTelemetry 采样器 {#custom-opentelemetry-sampler}

The OpenTelemetry specification defines the [Sampler API](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.31.0/specification/trace/sdk.md#sampler). The Sampler API enables building a custom sampler that can perform more intelligent and efficient sampling decisions, such as [Probability Sampling](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.31.0/specification/trace/tracestate-probability-sampling.md).
OpenTelemetry 规范定义了 [Sampler API](https://github.com/open-telemetry/opentelemetry-specation/blob/v1.31.0/specification/trace/sdk.md#sampler)。 Sampler API 支持构建自定义采样器，该采样器可以执行更智能、更高效的采样决策，例如[概率采样](https://github.com/open-telemetry/opentelemetry-specification/blob/v1.31.0/specification/trace /tracestate-probability-sampling.md）。

Such samplers can then be paired with the [`OpenTelemetryTracingProvider`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider).
然后，此类采样器可以与 OpenTelemetryTracingProvider 配对。

{{< quote >}}
The sampler implementation resides in the proxy and can be found in [Envoy OpenTelemetry Samplers](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers).
采样器实现驻留在代理中，可以在 [Envoy OpenTelemetry Samplers](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/opentelemetry/samplers#opentelemetry-samplers) 中找到 。
{{< /quote >}}

Current custom sampler configurations in Istio:
Istio 中当前的自定义采样器配置：

- [Dynatrace Sampler](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)
- [Dynatrace 采样器](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-OpenTelemetryTracingProvider-DynatraceSampler)

Custom samplers are configured via `Meshconfig`. Here is an example of configuring the Dynatrace sampler:
自定义采样器通过“Meshconfig”进行配置。 以下是配置 Dynatrace 采样器的示例：

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

## Order of precedence
## 优先顺序 {#order-of-precedence}

With multiple ways of configuring sampling, it is important to understand the order of precedence of each method.
通过多种配置采样的方法，了解每种方法的优先顺序非常重要。

When using the random percentage sampler the order of precedence is:
使用随机百分比采样器时，优先顺序为：

`Telemetry API` > `Pod Annotation` > `MeshConfig`.
`遥测 API` > `Pod 注释` > `MeshConfig`。

That means, if a value is defined in all of the above, the value on the `Telemetry API` is the one selected.
这意味着，如果在上述所有内容中定义了一个值，则“遥测 API”上的值就是所选的值。

When a custom OpenTelemetry sampler is configured, the order of precedence is:
配置自定义 OpenTelemetry 采样器时，优先顺序为：

`Custom OTel Sampler` > (`Telemetry API` | `Pod Annotation` | `MeshConfig`)
`自定义 OTel 采样器` > (`遥测 API` | `Pod 注释` | `MeshConfig`)

That means, if a custom OpenTelemetry sampler is configured, it overrides all the others methods. Additionally, the random percentage value is set to `100` and cannot be changed. This is important because the custom sampler needs to receive 100% of spans to be able to properly perform its decision.
这意味着，如果配置了自定义 OpenTelemetry 采样器，它将覆盖所有其他方法。 此外，随机百分比值设置为“100”且无法更改。 这很重要，因为自定义采样器需要接收 100% 的跨度才能正确执行其决策。

## Deploy the Bookinfo Application
## 部署 Bookinfo 应用程序 {#deploy-the-bookinfo-application}

Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.
部署 [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) 示例应用程序。

## Generating traces using the Bookinfo sample
## 使用 Bookinfo 示例生成跟踪 {#generating-traces-using-the-bookinfo-sample}

1.  When the Bookinfo application is up and running, access `http://$GATEWAY_URL/productpage` one or more times to generate trace information.
1. 当 Bookinfo 应用程序启动并运行时，访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成跟踪信息。

    {{< boilerplate trace-generation >}}

## Cleanup
## 清理 {#cleanup}

1.  Remove the Telemetry resource:
1. 删除遥测资源：

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  Remove any `istioctl` processes that may still be running using control-C or:
1. 使用 control-C 删除可能仍在运行的任何 `istioctl` 进程，或者：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}

1.  Uninstall the OpenTelemetry Collector:
1.卸载OpenTelemetry Collector：

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}
