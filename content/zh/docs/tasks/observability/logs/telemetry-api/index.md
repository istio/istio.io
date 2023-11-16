---
title: 使用 Telemetry API 配置访问日志
description: 此任务向您演示如何使用 Telemetry API 配置 Envoy 代理来发送访问日志。
weight: 10
keywords: [telemetry,logs]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Telemetry API 如今在 Istio 中作为核心 API 已经有一段时间了。
之前用户必须在 Istio 的 `MeshConfig` 中配置 Telemetry。

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## 安装  {#installation}

在本例中，我们将发送日志到 [Grafana Loki](https://grafana.com/oss/loki/)，确保它已被安装。

{{< text syntax=bash snip_id=install_loki >}}
$ istioctl install -f @samples/open-telemetry/loki/iop.yaml@ --skip-confirmation
$ kubectl apply -f @samples/addons/loki.yaml@ -n istio-system
$ kubectl apply -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
{{< /text >}}

## Telemetry API 入门  {#get-started-with-telemetry-api}

1. 启用访问日志记录

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n istio-system -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: mesh-logging-default
    spec:
      accessLogging:
      - providers:
        - name: otel
    EOF
    {{< /text >}}

    这个示例使用内置的 `envoy` 访问日志提供程序，我们除了默认设置外没有进行任何其他配置。

1. 禁用特定工作负载的访问日志

    您可以使用以下配置禁用 `sleep` 服务的访问日志：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: disable-sleep-logging
      namespace: default
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        disabled: true
    EOF
    {{< /text >}}

1. 通过工作负载模式过滤访问日志

    您可以使用以下配置禁用 `httpbin` 服务的入站访问日志：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: disable-httpbin-logging
    spec:
      selector:
        matchLabels:
          app: httpbin
      accessLogging:
      - providers:
        - name: otel
        match:
          mode: SERVER
        disabled: true
    EOF
    {{< /text >}}

1. 通过 CEL 表达式过滤访问日志

    只有响应码大于等于 500 时，以下配置才显示访问日志：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-sleep-logging
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: response.code >= 500
    EOF
    {{< /text >}}

1. 通过 CEL 表达式设置默认的过滤访问日志

    只有响应码大于等于 400 或请求转到 BlackHoleCluster 或 PassthroughCluster 时，
    以下配置才显示访问日志（注意 `xds.cluster_name` 仅可用于 Istio 1.16.2 及更高版本）：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: default-exception-logging
      namespace: istio-system
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "response.code >= 400 || xds.cluster_name == 'BlackHoleCluster' ||  xds.cluster_name == 'PassthroughCluster' "

    EOF
    {{< /text >}}

1. 使用 CEL 表达式过滤健康检查访问日志

    仅当日志不是由 Amazon Route 53 健康检查服务所生成时，以下配置才显示访问日志。
    注意：`request.useragent` 专用于 HTTP 流量，因此为了避免破坏 TCP 流量，
    我们需要检查该字段是否存在。有关更多信息，请参阅
    [CEL 类型检查](https://kubernetes.io/docs/reference/using-api/cel/#type-checking)

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-health-check-logging
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "!has(request.useragent) || !(request.useragent.startsWith("Amazon-Route53-Health-Check-Service"))"
    EOF
    {{< /text >}}

    有关更多信息，请参阅[使用赋值表达式](/zh/docs/tasks/observability/metrics/customize-metrics/#use-expressions-for-values)。

## 使用 OpenTelemetry 提供程序  {#work-with-otel-provider}

Istio 支持使用 [OpenTelemetry](https://opentelemetry.io/) 协议发送访问日志，
如[此处](/zh/docs/tasks/observability/logs/otel-provider)所述。

## 清理  {#cleanup}

1.  移除所有 Telemetry API：

    {{< text bash >}}
    $ kubectl delete telemetry --all -A
    {{< /text >}}

1.  移除 `loki`：

    {{< text bash >}}
    $ kubectl delete -f @samples/addons/loki.yaml@ -n istio-system
    $ kubectl delete -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
    {{< /text >}}

1.  从集群中卸载 Istio：

    {{< text bash >}}
    $ istioctl uninstall --purge --skip-confirmation
    {{< /text >}}
