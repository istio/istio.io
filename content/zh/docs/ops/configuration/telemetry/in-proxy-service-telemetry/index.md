---
title: 不使用 Mixer 生成 Istio 指标 [试验性的]
description: 怎样使用代理生成服务级别的指标。
weight: 20
aliases:
  - /zh/docs/ops/telemetry/in-proxy-service-telemetry
---

{{< boilerplate experimental-feature-warning >}}

Istio 1.3 对直接在 Envoy 代理中生成服务级别的 HTTP 指标添加了试验性支持。这个特性让你可以在没有 Mixer 的情况下使用 Istio 提供的工具监控你的服务网格。

在代理中生成的服务级别指标代替了如下所示的当前在 Mixer 中生成的 HTTP 指标：

- `istio_requests_total`
- `istio_request_duration_seconds`
- `istio_request_size`

## 在 Envoy 中启用服务级别指标生成功能{#enable-service-level-metrics-generation-in-envoy}

要直接在 Envoy 代理中生成服务级别的指标，请按照下列步骤操作：

1.  为了阻止生成重复的遥测指标，请禁用网格中的 `istio-telemetry`：

    {{< text bash >}}
    $ istioctl manifest apply --set values.mixer.telemetry.enabled=false,values.mixer.policy.enabled=false
    {{< /text >}}

    {{< tip >}}
    或者，你可以在你的 [网格配置](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) 中注释掉 `mixerCheckServer` 和 `mixerReportServer`。
    {{< /tip >}}

1. 为了生成服务级别的指标，代理必须交换 {{< gloss >}}workload{{< /gloss >}} 元数据。有一个自定义的过滤器可以来处理元数据交换。请使用如下命令来启用元数据交换过滤器：

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/{{< source_branch_name >}}/extensions/stats/testdata/istio/metadata-exchange_filter.yaml
    {{< /text >}}

1. 为了最终生成服务级别的指标，你必须应用一个自定义的统计过滤器。

    {{< text bash >}}
    $ kubectl -n istio-system apply -f https://raw.githubusercontent.com/istio/proxy/{{< source_branch_name >}}/extensions/stats/testdata/istio/stats_filter.yaml
    {{< /text >}}

1. 打开 **Istio Mesh** Grafana 面板。可以验证在没有任何请求经过 Istio Mixer 的情况下仍然显示和之前一样的遥测指标。

## 和基于 Mixer 生成遥测指标的区别{#differences-with-mixer-based-generation}

在 Istio 1.3 版本，代理生成和基于 Mixer 生成服务级别的指标存在一些细微的差别。在代理生成和基于 Mixer 生成服务级别的指标有相同完整的特性之前，我们不会考虑功能的稳定性。

在那之前，请注意如下差别：

- `istio_request_duration_seconds` 时延指标有一个新的名字：`istio_request_duration_milliseconds`。新的指标度量单位使用毫秒代替秒。我们更新了 Grafana 面板来应对这些变化。
- `istio_request_duration_milliseconds` 指标在代理中使用更多细粒度的 buckets，以提高时延报告的准确性。

## 性能影响{#performance-impact}

{{< warning >}}

因为目前的工作是试验性的，我们主要关注的是建立基础性的功能。基于我们最初的试验，我们已经确定了几个基础的性能优化方向，希望能持续提高性能以及在开发时这个特性的可扩展性。

我们不考虑将这个特性提升到 **Beta** 或者 **Stable** [状态](/zh/about/feature-stages/#feature-phase-definitions)，直到我们完成性能和可扩展性的提升以及评估。

你的网格的性能依赖于你的配置。要了解更多，请看我们的 [性能最佳实践帖](/zh/blog/2019/performance-best-practices/)。

{{< /warning >}}

下面是目前为止我们做的测试评估：

- 在 `istio-proxy` 容器中所有的过滤器一起使用比运行 Mixer 过滤器减少了 10% 的 CPU 资源。
- 和不配置遥测过滤器的 Envoy 代理相比，新增加的过滤器会导致在 1000 rps 时增加约 5ms P90 的时延。
- 如果你只使用 `istio-telemetry` 服务来生成服务级别的指标，你可以关闭 `istio-telemetry` 服务。这样网格中每 1000 rps 流量可以为你节省约 0.5 vCPU，并且可以在收集 [标准指标](/zh/docs/reference/config/policy-and-telemetry/metrics/) 时将 Istio 消耗的 CPU 减半。

## 已知的限制{#known-limitations}

- 我们只对通过 Prometheus 导出指标提供支持。
- 我们不支持生成 TCP 指标。
- 我们提供不基于代理生成的指标的自定义或配置。
