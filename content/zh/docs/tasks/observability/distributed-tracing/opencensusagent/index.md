---
title: OpenCensus Agent
description: 学习如何配置代理将 OpenCensus 格式化的 span 发送到 OpenTelemetry Collector。
weight: 10
keywords: [telemetry,tracing,opencensus,opentelemetry,span]
aliases:
    - /zh/docs/tasks/opencensusagent-tracing.html
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

完成本任务之后，您将明白如何使用 OpenCensus Agent 跟踪应用，
如何将这些链路导出到 OpenTelemetry Collector，
以及如何使用 OpenTelemetry Collector 将这些 span 导出到 Jaeger。

若要学习 Istio 如何处理链路，请查阅本任务的[概述](../overview)。

{{< boilerplate before-you-begin-egress >}}

* 在集群中安装 [Jaeger](/zh/docs/ops/integrations/jaeger/#installation)。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 样例应用。

## 配置跟踪{#configure-tracing}

如果您使用了 `IstioOperator` CR 来安装 Istio，请添加以下字段到您的配置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
    meshConfig:
        defaultProviders:
            tracing:
            - "opencensus"
        enableTracing: true
        extensionProviders:
        - name: "opencensus"
          opencensus:
              service: "opentelemetry-collector.istio-system.svc.cluster.local"
              port: 55678
              context:
              - W3C_TRACE_CONTEXT
{{< /text >}}

采用此配置时，OpenCensus Agent 作为默认的跟踪器来安装 Istio。链路数据将被发送到 OpenTelemetry 后端。

默认情况下，Istio 的 OpenCensus Agent 跟踪将尝试读写 4 种链路头：

* B3
* gRPC 的二进制链路头
* [W3C Trace Context](https://www.w3.org/TR/trace-context/)
* 和云链路上下文（Cloud Trace Context）。

如果您提供多个值，代理将尝试以指定的顺序读取链路头，使用第一个成功解析的头并写入所有头。
这允许使用不同头的服务之间具有互操作性，例如在同一个链路中，一个服务传播 B3 头，
一个服务传播 W3C Trace Context 头。 在本例中，我们仅使用 W3C Trace Context。

在默认的配置文件中，采样率为 1%。
使用 [Telemetry API](/zh/docs/tasks/observability/telemetry/) 将其提高到 100%：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - randomSamplingPercentage: 100.00
EOF
{{< /text >}}

## 部署 OpenTelemetry Collector{#deploy-otel-collector}

OpenTelemetry Collector 支持默认将链路导出到核心分发中的[几个后端](https://github.com/open-telemetry/opentelemetry-collector/blob/master/exporter/README.md#general-information)。
其他后端可用于 OpenTelemetry Collector 的[贡献分发](https://github.com/open-telemetry/opentelemetry-collector-contrib)中。

部署并配置 Collector 以接收和导出 span 到 Jaeger 实例：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
data:
  config: |
    receivers:
      opencensus:
        endpoint: 0.0.0.0:55678
    processors:
      memory_limiter:
        limit_mib: 100
        spike_limit_mib: 10
        check_interval: 5s
    exporters:
      zipkin:
        # Export via zipkin for easy querying
        endpoint: http://zipkin.istio-system.svc:9411/api/v2/spans
      logging:
        loglevel: debug
    extensions:
      health_check:
        port: 13133
    service:
      extensions:
      - health_check
      pipelines:
        traces:
          receivers:
          - opencensus
          processors:
          - memory_limiter
          exporters:
          - zipkin
          - logging
---
apiVersion: v1
kind: Service
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  type: ClusterIP
  selector:
    app: opentelemetry-collector
  ports:
    - name: grpc-opencensus
      port: 55678
      protocol: TCP
      targetPort: 55678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: opentelemetry-collector
  namespace: istio-system
  labels:
    app: opentelemetry-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opentelemetry-collector
  template:
    metadata:
      labels:
        app: opentelemetry-collector
    spec:
      containers:
        - name: opentelemetry-collector
          image: "otel/opentelemetry-collector:0.49.0"
          imagePullPolicy: IfNotPresent
          command:
            - "/otelcol"
            - "--config=/conf/config.yaml"
          ports:
            - name: grpc-opencensus
              containerPort: 55678
              protocol: TCP
          volumeMounts:
            - name: opentelemetry-collector-config
              mountPath: /conf
          readinessProbe:
            httpGet:
              path: /
              port: 13133
          resources:
            requests:
              cpu: 40m
              memory: 100Mi
      volumes:
        - name: opentelemetry-collector-config
          configMap:
            name: opentelemetry-collector
            items:
              - key: config
                path: config.yaml
EOF
{{< /text >}}

## 访问仪表板{#accessing-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways)详细说明了如何配置通过 Gateway 访问 Istio 插件。

对于测试（和临时访问），您也可以使用端口转发。
使用以下命令，假设您已将 Jaeger 部署到 `istio-system` 命名空间：

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## 使用 Bookinfo 样例生成链路{#generating-tarces-using-bookinfo}

1.  当 Bookinfo 应用启动且运行时，访问一次或多次 `http://$GATEWAY_URL/productpage` 以生成链路信息。

    {{< boilerplate trace-generation >}}

1.  从仪表板的左侧窗格中，从 **Service** 下拉列表中选择 `productpage.default` 并点击 **Find Traces**：

    {{< image link="./istio-tracing-list.png" caption="Tracing Dashboard" >}}

1.  点击顶部最近的链路，查看与 `/productpage` 最近请求对应的详情：

    {{< image link="./istio-tracing-details.png" caption="Detailed Trace View" >}}

1.  链路由一组 span 组成，每个 span 对应在执行 `/productpage` 期间调用的一个 Bookinfo 服务，
    或对应 `istio-ingressgateway` 这种内部 Istio 组件。

由于您还在 OpenTelemetry Collector 中配置了日志记录导出器，因此您也可以在日志中看到链路：

{{< text bash >}}
$ kubectl -n istio-system logs deploy/opentelemetry-collector
{{< /text >}}

## 清理{#cleanup}

1.  使用 Ctrl-C 或以下命令移除可能仍在运行的所有 `istioctl` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  如果您未计划探索后续的任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)指示说明，
    以关闭该应用。

1.  移除 `Jaeger` 插件：

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/addons/jaeger.yaml
    {{< /text >}}

1.  移除 `OpenTelemetry Collector`:

    {{< text bash >}}
    $ kubectl delete -n istio-system cm opentelemetry-collector
    $ kubectl delete -n istio-system svc opentelemetry-collector
    $ kubectl delete -n istio-system deploy opentelemetry-collector
    {{< /text >}}

1.  在您的 Istio 安装配置中移除 `meshConfig.extensionProviders` 和 `meshConfig.defaultProviders` 设置，或将其设置为 `""`。

1.  移除遥测资源：

    {{< text bash >}}
    $ kubectl delete telemetries.telemetry.istio.io -n istio-system mesh-default
    {{< /text >}}
