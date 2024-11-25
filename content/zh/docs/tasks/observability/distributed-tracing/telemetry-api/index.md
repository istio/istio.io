---
title: 使用 Telemetry API 配置链路追踪
description: 如何使用 Telemetry API 配置链路追踪。
weight: 2
keywords: [telemetry,tracing]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Istio 提供了配置链路追踪选项的功能，例如采样率和向报告的 Span 添加自定义标签。
此任务向您展示如何使用 Telemetry API 自定义链路追踪选项。

## 开始之前 {#before-you-begin}

1. 请确保您的应用程序按照[这里](/zh/docs/tasks/observability/distributed-tracing/overview/)所描述的方式配置链路追踪的标头。

1. 根据您首选的链路追踪后端，
   按照位于[集成](/zh/docs/ops/integrations/)下的链路追踪安装指南安装适当的软件并配置扩展提供程序。

## 安装 {#installation}

在此示例中，我们将链路发送到 [Zipkin](/zh/docs/ops/integrations/zipkin/)。
继续操作之前，请先安装 Zipkin。

### 配置扩展提供程序 {#configure-an-extension-provider}

使用引用 Zipkin 服务的[扩展提供程序](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)安装 Istio：

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # 禁用旧版 MeshConfig 链路追踪选项
    extensionProviders:
    # 添加 zipkin 提供商
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### 启用链路追踪 {#enable-tracing}

通过以下配置启用链路追踪：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
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

### 验证结果 {#verify-the-results}

您可以通过[访问 Zipkin UI](/zh/docs/tasks/observability/distributed-tracing/zipkin/)来验证结果。

## 自定义 {#customization}

### 自定义链路采样 {#customizing-trace-sampling}

采样率选项可用于控制向链路追踪系统报告的请求百分比，
应根据服务网格中的流量和您想要收集的链路追踪数据量来配置此选项，
默认采样率为 1%。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
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

### 自定义链路追踪标签 {#customizing-tracing-tags}

可以基于文本、环境变量和客户端请求标头向 span 中添加自定义标签，以在与环境相关的 span
中提供额外的信息。

{{< warning >}}
添加自定义标签的数量没有限制，但标签名称必须唯一。
{{< /warning >}}

您可以使用以下三种方式来添加自定义标签。

1.  literal 选项可以将一个静态的值添加到每个 span 中。

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
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
    apiVersion: telemetry.istio.io/v1
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
    apiVersion: telemetry.istio.io/v1
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
            my_tag_header:
              header:
                name: <CLIENT-HEADER>
                defaultValue: <VALUE>      # 可选
    {{< /text >}}

### 自定义链路追踪标签长度 {#customizing-tracing-tag-length}

默认情况下，`HttpUrl` 的 span 标签的请求最大长度为 256。要修改此最大长度，
请将以下内容添加到您的 `tracing.yaml` 配置文件中。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing: {} # 通过 MeshConfig 禁用旧版链路追踪选项
    extensionProviders:
    - name: "zipkin"
      zipkin:
        service: zipkin.istio-system.svc.cluster.local
        port: 9411
        maxTagLength: <VALUE>
{{< /text >}}
