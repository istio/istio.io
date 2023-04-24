---
title: 使用 MeshConfig 和 Pod 注释配置跟踪
description: 如何使用 MeshConfig 和 Pod 注释配置跟踪选项。
weight: 11
keywords: [telemetry,tracing]
aliases:
 - /zh/docs/tasks/observability/distributed-tracing/configurability/
 - /zh/docs/tasks/observability/distributed-tracing/configurability/mesh-and-proxy-config/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
status: Beta
---

{{< tip >}}
鼓励用户使用 [Telemetry API](/zh/docs/tasks/observability/telemetry/) 来跟踪配置。
{{</ tip >}}

Istio 提供了配置高级跟踪选项的能力，例如采样率和向报告的跨度添加自定义标记。
采样是一个 beta 特性，但是添加自定义标签和跟踪标签长度会考虑在本版本中开发。

## 开始之前{#before-you-begin}

1. 确保您的应用程序按照 [here](/zh/docs/tasks/observability/distributed-tracing/overview/)所述传输追踪标头。

1. 遵循位于 [Integrations](/zh/docs/ops/integrations/) 下的追踪安装指南，
   根据您喜欢的追踪后端安装适当的插件和配置您的 Istio 代理以将追踪发送到追踪部署。

## 可用的跟踪配置{#available-tracing-configurations}

您可以在 Istio 中配置以下跟踪选项：

1. 将选择用于跟踪生成的请求百分比的随机采样率。

1. 请求路径的最大长度，之后路径将被截断报告。这对于限制跟踪数据存储特别有用，如果您在入口网关收集跟踪。

1. 在spans中添加自定义标签。这些标签可以基于静态文字添加请求标头中的值、环境值或字段。
   这可以用来在特定于您的环境的跨度中注入其他信息。

有两种方法可以配置跟踪选项：

1. 全局通过 `MeshConfig` 选项。

1. 用于工作负载特定定制的每个 pod 注释。

{{< warning >}}
为了使新的跟踪配置对其中任何一个生效，您需要重新启动注入 Istio 代理的 pod 的选项。
{{< /warning >}}

{{< warning >}}
为跟踪配置而添加的任何 pod 注释都会覆盖全局设置。为了保留任何全局设置，
你应该将它们从全局网格配置复制到 Pod 注释，并进行特定于工作负载的定制。
特别是要确保注释中始终提供跟踪后端地址，以确保正确地报告工作负载的跟踪。
{{< /warning >}}

## 安装{#installation}

使用这些特性为在您的环境中管理跟踪提供了新的可能性。

在本例中，我们将对所有跟踪进行采样，并添加一个名为 `clusterID` 的标记，使用
`ISTIO_META_CLUSTER_ID` 环境变量注入到您的 Pod。只使用该值的前 256 个字符。

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 100.0
        max_path_tag_length: 256
        custom_tags:
          clusterID:
          environment:
            name: ISTIO_META_CLUSTER_ID
EOF
$ istioctl install -f ./tracing.yaml
{{< /text >}}

### 使用 MeshConfig 进行跟踪设置{#using-mesh-config-for-trace-settings}

所有跟踪选项都可以通过 `MeshConfig` 全局配置。
为了简化配置，建议创建一个可以传递给 `istioctl install -f` 命令的 YAML 文件。

{{< text yaml >}}
cat <<'EOF' > tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 10
        custom_tags:
          my_tag_header:
            header:
              name: host
EOF
{{< /text >}}

### 使用 `proxy.istio.io/config` 跟踪设置的注释 {#using-proxy-istio-io-config-annotation-for-trace-settings}

您可以添加 `proxy.istio.io/config` 注释到您的 Pod 元数据规范，以覆盖任何网格范围的跟踪设置。
例如，要修改 Istio 附带的 `sleep` 部署，你需要在 `samples/sleep/sleep.yaml` 中添加以下内容:

{{< text yaml >}}
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
            sampling: 10
            custom_tags:
              my_tag_header:
                header:
                  name: host
    spec:
      ...
{{< /text >}}

## 自定义跟踪采样 {#customizing-trace-sampling}

采样率选项可用于控制向跟踪系统报告的请求的百分比。这应该根据网格中的通信量和想要收集的跟踪数据量进行配置。
默认值为 1%。

{{< warning >}}
以前，推荐的方法是在网格设置期间更改 `values.pilot.traceSampling` 设置，或在 pilot 或
istiod 部署中更改 `PILOT_TRACE_SAMPLE` 环境变量。

虽然这种改变抽样的方法仍然有效，但强烈建议改用以下方法
{{< /warning >}}

要将默认随机抽样修改为50，请在 `tracing.yaml` 文件中添加以下选项。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        sampling: 50
{{< /text >}}

采样率应在 0.0 到 100.0 的范围内，精度为0.01。
例如，要跟踪每 10000 个请求中的 5 个，使用 0.05 作为这里的值。

## 定制跟踪标签{#customizing-tracing-tags}

可以根据文字、环境变量和客户端请求标头向跨度添加自定义标记，以便在跨度中提供特定于您的环境的额外信息。

{{< warning >}}
可以添加的自定义标记的数量没有限制，但是标记名称必须是唯一的。
{{< /warning >}}

您可以使用下面三个受支持的选项中的任何一个来定制标记。

1.  Literal 表示添加到每个 span 的静态值。

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_literal:
                literal:
                  value: <VALUE>
    {{< /text >}}

1.  在从工作负载代理环境变量填充自定义标记的值时，可以使用环境变量。

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_env:
                environment:
                  name: <ENV_VARIABLE_NAME>
                  defaultValue: <VALUE>      # optional
    {{< /text >}}

    {{< warning >}}
    为了添加基于环境变量的自定义标记，您必须修改根 Istio 系统命名空间中的
    `istio-sidecar-injector` ConfigMap
    {{< /warning >}}

1.  客户端请求头选项可用于填充来自传入客户端请求头的标记值。

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        enableTracing: true
        defaultConfig:
          tracing:
            custom_tags:
              my_tag_header:
                header:
                  name: <CLIENT-HEADER>
                  defaultValue: <VALUE>      # optional
    {{< /text >}}

## 自定义跟踪标签长度 {#customizing-tracing-tag-length}

默认情况下，`HttpUrl` span 标记中包含的请求路径的最大长度是 256。
要修改此最大长度，请将以下内容添加到您的 `tracing.yaml` 文件。

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
      tracing:
        max_path_tag_length: <VALUE>
{{< /text >}}
