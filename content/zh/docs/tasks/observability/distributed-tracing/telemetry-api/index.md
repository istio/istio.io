---
title: 使用 Telemetry API 配置链路追踪
description: 如何使用 Telemetry API 配置链路追踪。
weight: 8
keywords: [telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio 提供了配置高级链路追踪选项的功能，例如采样率和向已采集的 span 中添加自定义标签。
本任务将向您展示如何使用 Telemetry API 自定义链路追踪选项。

## 开始之前  {#before-you-begin}

1. 请确保您的应用程序按照[这里](/zh/docs/tasks/observability/distributed-tracing/overview/)所描述的方式配置链路追踪的标头。

1. 请根据您首选的追踪后端，根据[集成](/zh/docs/ops/integrations/)追踪安装指南安装适当的插件,
   并配置您的 Istio 代理将链路追踪信息发送到链路追踪部署服务端。

## 安装  {#installation}

在此示例中，我们将发送跟踪信息到[`链路追踪系统 zipkin`](/zh/docs/ops/integrations/zipkin/)，
请确保已安装它：

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # 禁用 MeshConfig 链路追踪选项
    extensionProviders:
    # 添加 zipkin 提供商
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### 启用服务网格的链路追踪  {#enable-tracing-for-mesh}

通过以下配置启用链路追踪：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
EOF
{{< /text >}}

## 自定义链路追踪采样率  {#customizing-trace-sampling}

采样率选项可用于控制向链路追踪系统报告的请求百分比，
应根据服务网格中的流量和您想要收集的链路追踪数据量来配置此选项，
默认采样率为 1%。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
    - providers:
        - name: "zipkin"
      randomSamplingPercentage: 100.00
EOF
{{< /text >}}

## 自定义链路追踪标签  {#customizing-tracing-tags}

可以基于文本、环境变量和客户端请求标头向 span 中添加自定义标签，以在与环境相关的 span
中提供额外的信息。

{{< warning >}}
添加自定义标签的数量没有限制，但标签名称必须唯一。
{{< /warning >}}

您可以使用以下三种方式来添加自定义标签。

1.  literal 选项可以将一个静态的值添加到每个 span 中。

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
            - name: "zipkin"
        randomSamplingPercentage: 100.00
        customTags:
          "provider":
            literal:
              value: "zipkin"
    {{< /text >}}

1.  环境变量可以用于从工作负载代理环境中自定义标签。

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
            - name: "zipkin"
          randomSamplingPercentage: 100.00
          customTags:
            "cluster_id":
              environment:
                name: ISTIO_META_CLUSTER_ID
                defaultValue: Kubernetes # 可选
    {{< /text >}}

    {{< warning >}}
    为了基于环境变量添加自定义标签，您必须修改根 Istio 系统命名空间中的 `istio-sidecar-injector`
    的 ConfigMap。
    {{< /warning >}}

1.  客户端请求头选项可用于从传入的客户端请求头中添加标签。

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: mesh-default
      namespace: istio-system
    spec:
      tracing:
        - providers:
            - name: "zipkin"
          randomSamplingPercentage: 100.00
          custom_tags:
            my_tag_header:
              header:
                name: <CLIENT-HEADER>
                defaultValue: <VALUE>      # 可选
    {{< /text >}}

## 自定义链路追踪标签长度  {#customizing-tracing-tag-length}

默认情况下，`HttpUrl` 的 span 标签的请求最大长度为 256。要修改此最大长度，
请将以下内容添加到您的 `tracing.yaml` 配置文件中。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # 通过 MeshConfig 禁用链路追踪选项
    extensionProviders:
    # 添加 zipkin 提供商
    - name: zipkin
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
{{< /text >}}

## 验证结果  {#verify-the-results}

您可以使用 [Zipkin 界面](/zh/docs/tasks/observability/distributed-tracing/zipkin/)来验证结果。
