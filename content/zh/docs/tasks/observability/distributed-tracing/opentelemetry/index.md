---
title: OpenTelemetry
description: 了解如何配置代理将 OpenTelemetry 链路发送至 Collector。
weight: 10
keywords: [telemetry,tracing,opentelemetry,span,port-forwarding]
aliases:
 - /zh/docs/tasks/telemetry/distributed-tracing/opentelemetry/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

完成此任务后，无论您使用什么语言、框架或平台来构建应用程序，
您都将了解如何让您的应用程序接入
[OpenTelemetry](https://www.opentelemetry.io/) 的链路追踪。

此任务使用 [Bookinfo](/zh/docs/examples/bookinfo/)
作为示例应用程序，并使用
[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) 作为链路接收器。

要了解 Istio 如何处理链路追踪，请访问此任务的[概述](../overview/)。

## 部署 OpenTelemetry Collector {#deploy-the-opentelemetry-collector}

{{< boilerplate start-otel-collector-service >}}

## 安装 {#installation}

所有链路追踪选项都可以通过 `MeshConfig` 进行全局配置。
为了简化配置，建议创建一个 YAML 文件，
您可以将其传递到 `istioctl install -f` 命令。

## 选择 Exporter {#choosing-the-exporter}

Istio 可以被配置为通过 gRPC 或 HTTP 导出
[OpenTelemetry Protocol（OTLP）](https://opentelemetry.io/docs/specs/otel/protocol/)链路。
一次只能配置一个 Exporter（gRPC 或 HTTP）。

### 通过 gRPC 导出 {#exporting-via-grpc}

在此示例中，链路将通过 OTLP/gRPC 导出到 OpenTelemetry Collector。
该示例还启用了[环境资源检测器](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables)。
环境检测器将环境变量 `OTEL_RESOURCE_ATTRIBUTES`
中的属性添加到导出的 OpenTelemetry 资源中。

{{< text syntax=bash snip_id=none >}}
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

### 通过 HTTP 导出 {#exporting-via-http}

在此示例中，链路将通过 OTLP/HTTP 导出到 OpenTelemetry Collector。
该示例还启用了[环境资源检测器](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables)。
环境检测器将环境变量 `OTEL_RESOURCE_ATTRIBUTES` 中的属性添加到导出的 OpenTelemetry 资源中。

{{< text syntax=bash snip_id=install_otlp_http >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4318
        service: opentelemetry-collector.observability.svc.cluster.local
        http:
          path: "/v1/traces"
          timeout: 5s
          headers:
            - name: "custom-header"
              value: "custom value"
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

## 通过 Telemetry API 启用网格链路追踪 {#enable-tracing-for-mesh-via-telemetry-api}

通过应用以下配置启用链路：

{{< text syntax=bash snip_id=enable_telemetry >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 100
    customTags:
      "my-attribute":
        literal:
          value: "default-value"
EOF
{{< /text >}}

## 部署 Bookinfo 应用程序 {#deploy-the-bookinfo-application}

部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application)
示例应用程序。

## 使用 Bookinfo 示例生成链路 {#generating-traces-using-the-bookinfo-sample}

1.  当 Bookinfo 应用程序启动并运行时，
    访问 `http://$GATEWAY_URL/productpage` 一次或多次以生成链路信息。

    {{< boilerplate trace-generation >}}

1.  在示例中使用的 OpenTelemetry Collector 被配置为将链路导出到控制台。
    如果您使用示例中的 Collector 配置，则可以通过查看 Collector
    日志来验证链路是否已到达。它应该包含类似以下内容：

    {{< text syntax=yaml snip_id=none >}}
    Resource SchemaURL:
    Resource labels:
          -> service.name: STRING(productpage.default)
    ScopeSpans #0
    ScopeSpans SchemaURL:
    InstrumentationScope
    Span #0
        Trace ID       : 79fb7b59c1c3a518750a5d6dad7cd2d1
        Parent ID      : 0cf792b061f0ad51
        ID             : 2dff26f3b4d6d20f
        Name           : egress reviews:9080
        Kind           : SPAN_KIND_CLIENT
        Start time     : 2024-01-30 15:57:58.588041 +0000 UTC
        End time       : 2024-01-30 15:57:59.451116 +0000 UTC
        Status code    : STATUS_CODE_UNSET
        Status message :
    Attributes:
          -> node_id: STRING(sidecar~10.244.0.8~productpage-v1-564d4686f-t6s4m.default~default.svc.cluster.local)
          -> zone: STRING()
          -> guid:x-request-id: STRING(da543297-0dd6-998b-bd29-fdb184134c8c)
          -> http.url: STRING(http://reviews:9080/reviews/0)
          -> http.method: STRING(GET)
          -> downstream_cluster: STRING(-)
          -> user_agent: STRING(curl/7.74.0)
          -> http.protocol: STRING(HTTP/1.1)
          -> peer.address: STRING(10.244.0.8)
          -> request_size: STRING(0)
          -> response_size: STRING(441)
          -> component: STRING(proxy)
          -> upstream_cluster: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> upstream_cluster.name: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> http.status_code: STRING(200)
          -> response_flags: STRING(-)
          -> istio.namespace: STRING(default)
          -> istio.canonical_service: STRING(productpage)
          -> istio.mesh_id: STRING(cluster.local)
          -> istio.canonical_revision: STRING(v1)
          -> istio.cluster_id: STRING(Kubernetes)
          -> my-attribute: STRING(default-value)
    {{< /text >}}

## 清理 {#cleanup}

1.  删除 Telemetry 资源：

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  使用 Ctrl+C 或以下命令来删除可能仍在运行的任何 `istioctl` 进程：

    {{< text syntax=bash snip_id=none >}}
    $ killall istioctl
    {{< /text >}}

1.  卸载 OpenTelemetry Collector：

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

1.  如果您不打算探索任何后续任务，
    请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明来关闭应用程序。
