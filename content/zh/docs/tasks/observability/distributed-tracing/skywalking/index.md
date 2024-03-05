---
title: Apache SkyWalking
description: 学习如何配置代理将链路追踪请求发送到 Apache SkyWalking。
weight: 10
keywords: [telemetry,tracing,skywalking,span,port-forwarding]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

完成本任务之后，您将明白如何使用 [Apache SkyWalking](https://skywalking.apache.org)
追踪应用，这与用于构建应用的语言、框架或平台无关。

本任务将使用 [Bookinfo](/zh/docs/examples/bookinfo/) 作为示例应用。

若要学习 Istio 如何处理跟踪，请查阅[分布式链路追踪概述](../overview/)一节。

## 配置链路追踪  {#configure-tracing}

如果您使用了 `IstioOperator` CR 来安装 Istio，请将以下字段添加到您的配置：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultProviders:
      tracing:
      - "skywalking"
    enableTracing: true
    extensionProviders:
    - name: "skywalking"
      skywalking:
        service: tracing.istio-system.svc.cluster.local
        port: 11800
{{< /text >}}

采用此配置来安装 Istio 时，将使用 SkyWalking Agent 作为默认的追踪器，
链路数据会被发送到 SkyWalking 后端。

在默认的配置文件中，采样率为 1%，
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

## 部署 SkyWalking 采集器  {#deploy-skywalking-collector}

遵循 [SkyWalking 安装](/zh/docs/ops/integrations/skywalking/#installation)文档将
SkyWalking 部署到集群中。

## 部署 Bookinfo 应用  {#deploy-bookinfo-app}

部署 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用。

## 访问仪表板  {#accessing-dashboard}

[远程访问遥测插件](/zh/docs/tasks/observability/gateways)详细说明了如何配置通过
Gateway 访问 Istio 插件。

对于测试（和临时访问），您也可以使用端口转发。
假设您已将 SkyWalking 部署到 `istio-system` 命名空间，使用以下命令：

{{< text bash >}}
$ istioctl dashboard skywalking
{{< /text >}}

## 使用 Bookinfo 示例生成链路  {#generating-tarces-using-bookinfo}

1.  当 Bookinfo 应用启动且运行时，访问一次或多次 `http://$GATEWAY_URL/productpage` 以生成链路信息：

    {{< boilerplate trace-generation >}}

1.  从 "General Service" 面板中，您可以看到服务列表：

    {{< image link="./istio-service-list-skywalking.png" caption="Service List" >}}

1.  在主要内容中选择 `Trace` 页签。您可以在左侧栏中看到链路列表，在右面板中看到链路详情：

    {{< image link="./istio-tracing-list-skywalking.png" caption="Trace View" >}}

1.  链路由一组 span 组成，每个 span 对应在执行 `/productpage` 期间调用的一个 Bookinfo 服务，
    或对应 `istio-ingressgateway` 这种内部 Istio 组件。

## 探索 SkyWalking 官方的演示应用  {#explore-skywalking-official-demo-app}

在本教程中，我们使用 [Bookinfo](/zh/docs/examples/bookinfo/#deploying-the-application) 示例应用。
在这个示例应用中，没有安装到服务的 SkyWalking 代理，所有链路均由 Sidecar 代理生成。

如果您想探索有关 [SkyWalking 语言代理](https://skywalking.apache.org/docs/#Agent)的更多信息，
SkyWalking 团队也提供了集成语言代理的[演示应用](http://github.com/apache/skywalking-showcase)，
您可以从中了解到更详细的链路以及其他语言代理特定的特性，例如配置文件分析。

## 清理  {#cleanup}

1.  使用 Ctrl-C 或以下命令移除可能仍在运行的所有 `istioctl` 进程：

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1.  如果您未计划探索后续的任务，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)指示说明，
    以关闭该应用。
