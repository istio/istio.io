---
title: 网格可视化
description: 此任务向您展示如何在 Istio 网格中可视化服务。
weight: 49
keywords: [telemetry,visualization]
aliases:
 - /zh/docs/tasks/telemetry/kiali/
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

此任务向您展示如何可视化 Istio 网格的不同方面。

作为此任务的一部分，您将安装 [Kiali](https://www.kiali.io) 插件，
并使用基于 Web 的图形用户界面来查看网格和 Istio 配置对象的服务图。

{{< idea >}}
这个任务并不包括 Kiali 提供的所有特性。要了解它所支持的全部功能，
请查看 [Kiali 官网](http://kiali.io/docs/features/)。
{{< /idea >}}

此任务始终将 [Bookinfo](/zh/docs/examples/bookinfo/) 样例应用程序作为示例。
此任务假设 Bookinfo 应用程序安装在 `bookinfo` 命名空间中。

## 开始之前 {#before-you-begin}

跟随 [Kiali 安装](/zh/docs/ops/integrations/kiali/#installation)文档将 Kiali 部署到您的集群中。

## 生成服务图 {#generating-a-graph}

1. 要验证服务在您的集群中运行，请运行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1. 要确定 Bookinfo URL，请按照说明确定
   [Bookinfo ingress `GATEWAY_URL`](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)。

1. 要将流量发送到网格，您有三种选择：

    * 在浏览器中访问 `http://$GATEWAY_URL/productpage`

    * 多次使用以下命令：

        {{< text bash >}}
        $ curl http://$GATEWAY_URL/productpage
        {{< /text >}}

    * 如果您在系统中安装了 `watch` 命令，请通过以下方式连续发送请求：

        {{< text bash >}}
        $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
        {{< /text >}}

1. 要打开 Kiali UI，请在您的 Kubernetes 环境中执行以下命令：

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1. 在登录后立即显示的 **Overview** 页面中，查看网格的概述。
   **Overview** 页面显示了网格中具有服务的所有命名空间。以下屏幕截图显示了类似的页面：

    {{< image width="75%"
        link="./kiali-overview.png"
        caption="Overview 示例"
        >}}

1. 要查看命名空间的图形，请选择 Bookinfo 命名空间卡片中的 `Graph` 菜单项。
   kebab 菜单位于卡片右上方，看起来像 3 个竖点。
   点击它可以看到所有可用的菜单项。看起来如下图所示：

    {{< image width="75%"
        link="./kiali-graph.png"
        caption="Graph 示例"
        >}}

1. 这个图形表示一段时间内流过服务网格的流量。此图形使用 Istio 遥测生成。

1. 要查看指标摘要，请选择图形中的任意节点或任意边，以便在右侧的 summary details 面板中显示其指标的详情。

1. 要使用不同的图形类型查看服务网格，请从 **Graph Type** 下拉菜单中选择一种图形类型。
   有几种图形类型可供选择：**App**、**Versioned App**、**Workload**、**Service**。

    * **App** 图形类型将一个应用程序的所有版本聚合到一个图形节点中。
      以下示例显示了一个单独的 **reviews** 节点，它代表了 reviews 应用程序的三个版本。

        {{< image width="75%"
            link="./kiali-app.png"
            caption="应用程序图形示例"
            >}}

    * **Versioned App** 图形类型显示每个应用程序版本的节点，但是特定应用程序的所有版本都组合在一起。
        下面的示例显示 **reviews** 组框，其中包含三个节点，这些节点代表了 reviews 应用程序的三个版本。

        {{< image width="75%"
            link="./kiali-versionedapp.png"
            caption="带版本的应用程序图形示例"
            >}}

    * **Workload** 图形类型显示了服务网格中每个工作负载的节点。
        这种图形类型不需要您使用 `app` 和 `version` 标签，因此，
        如果您选择在组件上不使用这些标签，这是您将使用的图形类型。

        {{< image width="70%"
            link="./kiali-workload.png"
            caption="工作负载图形示例"
            >}}

    * **Service** 图形类型显示您网格中高级聚合的服务流量。

        {{< image width="70%"
        link="./kiali-service-graph.png"
        caption="服务图示例"
        >}}

## 检查 Istio 配置 {#examining-Istio-configuration}

1. 要检查有关 Istio 配置的详情，请点击左侧菜单栏上的 **Applications**、**Workloads** 和 **Services** 菜单项。
    以下屏幕截图显示了 Bookinfo 应用程序信息：

    {{< image width="80%"
        link="./kiali-services.png"
        caption="详情示例"
        >}}

## 流量转移 {#traffic-shifting}

您可以使用 Kiali 流量转移向导来定义特定百分比的请求流量以路由到两个或多个工作负载。

1. 查看 `bookinfo` 图的 **Versioned app graph**。

    * 确保已启用 **Traffic Distribution Edge Label** 的 **Display** 选项，以查看路由到每个工作负载的流量百分比。

    * 确保已经已启用 **Show Service Nodes** 的 **Display** 选项，以在图中查看服务节点。

    {{< image width="80%"
        link="./kiali-wiz0-graph-options.png"
        caption="Bookinfo 图形选项"
        >}}

1. 通过点击 `ratings` 服务（三角形）节点，将关注点放在 `bookinfo` 图内的 `ratings` 服务上。
    注意，`ratings` 服务流量平均分配给两个 `ratings` 服务 `v1` 和 `v2`（每台服务被路由 50％ 的请求）。

    {{< image width="80%"
        link="./kiali-wiz1-graph-ratings-percent.png"
        caption="显示流量百分比的图形"
        >}}

1. 点击侧面板上的 **ratings** 链接进入 `ratings` 服务的详情视图。
   这也可以通过右键点击 `ratings` 服务节点并从上下文菜单中选择 `Details` 来完成。

1. 从 **Action** 下拉菜单中，选择 **Traffic Shifting** 以流量转移向导。

    {{< image width="80%"
        link="./kiali-wiz2-ratings-service-action-menu.png"
        caption="服务的操作菜单"
        >}}

1. 拖动滑块以指定要路由到每个服务的流量百分比。
    对于 `ratings-v1`，将其设置为 10％；对于 `ratings-v2`，请将其设置为 90％。

    {{< image width="80%"
        link="./kiali-wiz3-traffic-shifting-wizard.png"
        caption="带权重的路由向导"
        >}}

1. 点击 **Preview** 按钮以查看将由向导生成的 YAML。

    {{< image width="80%"
        link="./kiali-wiz3b-traffic-shifting-wizard-preview.png"
        caption="路由向导预览"
        >}}

1. 点击 **Create** 按钮以确认应用新的流量设置。

1. 点击左侧导航栏中的 **Graph** 以返回到 `bookinfo` 图表。注意现在 `ratings` 服务节点带有 `virtual service` 图标。

1. 发送请求到 `bookinfo` 应用程序。例如，要每秒发送一个请求，如果您的系统上装有 `watch`，则可以执行以下命令：

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1. 几分钟后，您会注意到流量百分比将反映新的流量路由，
   从而确认您的新流量路由已成功将所有流量请求的 90％ 路由到 `ratings-v2`。

    {{< image width="80%"
        link="./kiali-wiz4-traffic-shifting-90-10.png"
        caption="90% Ratings 流量路由到 ratings-v2"
        >}}

## 验证 Istio 配置 {#validating-Istio-configuration}

Kiali 可以验证您的 Istio 资源，以确保它们遵循正确的约定和语义。
根据错误配置的严重程度，在 Istio 资源的配置中检测到的任何问题都可以标记为错误或警告。
有关 Kiali 执行的所有验证检查的列表，请参考 [Kiali Validation 页面](https://kiali.io/docs/features/validations/)。

{{< idea >}}
Istio 提供了 `istioctl analyze`，它使您能够以在 CI 管道中使用的方式执行类似的分析。这两种方法可以互为补充。
{{< /idea >}}

强制对服务端口名称进行无效配置，以查看 Kiali 如何报告验证错误。

1. 将 `details` 服务的端口名从 `http` 更改为 `foo`：

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"foo"}]'
    {{< /text >}}

1. 通过点击左侧导航栏上的 **Services**，导航到 **Services** 列表。

1. 如果尚未选择，请从 **Namespace** 下拉菜单中选择 `bookinfo`。

1. 注意在 `details` 行的 **Configuration** 列中显示的错误图标。

    {{< image width="80%"
        link="./kiali-validate1-list.png"
        caption="显示无效配置的服务列表"
        >}}

1. 点击 **Name** 列中的 **details** 链接，以导航到服务详情视图。

1. 将鼠标悬停在错误图标上可以显示描述错误的提示。

    {{< image width="80%"
        link="./kiali-validate2-errormsg.png"
        caption="描述无效配置的服务详情"
        >}}

1. 将端口名称改回 `http` 以更正配置，并将 `bookinfo` 返回其正常状态。

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
    {{< /text >}}

    {{< image width="80%"
        link="./kiali-validate3-ok.png"
        caption="显示无效配置的服务详情"
        >}}

## 查看并编辑 Istio YAML 文件配置 {#viewing-and-editing-Istio-configuration-YAML}

Kiali 提供了一个 YAML 编辑器，用于查看和编辑 Istio 配置资源。当检测到错误的配置时，YAML 编辑器还将提供验证消息。

1. 在 `bookinfo` VirtualService 中引入一个错误。

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway-invalid"}]'
    {{< /text >}}

1. 点击左侧导航栏上的 `Istio Config` 以导航到 Istio 配置列表。

1. 如果尚未选择，请从 **Namespace** 下拉菜单中选择 `bookinfo`。

1. 请注意错误消息以及错误警告图标，它们会警告您一些配置问题。

    {{< image width="80%"
        link="./kiali-istioconfig0-errormsgs.png"
        caption="Istio Config 列出不正确的配置"
        >}}

1. 在 `bookinfo` 行的  **Configuration** 列中点击错误图标，导航到 `bookinfo` 虚拟服务视图。

1. 预先选中 **YAML** 页签。请注意验证检查通知已关联的行颜色会突出显示且具有特别的图标。

    {{< image width="80%"
        link="./kiali-istioconfig3-details-yaml1.png"
        caption="YAML 编辑器显示校验通知"
        >}}

1. 将鼠标悬停在红色图标上可以查看工具提示消息，该消息提示您验证检查触发了错误。
    有关错误起因和解决方法的更多详细信息，请在 [Kiali Validation 页面](https://kiali.io/docs/features/validations/)上查找验证错误消息。

    {{< image width="80%"
        link="./kiali-istioconfig3-details-yaml3.png"
        caption="YAML 编辑器显示错误工具提示"
        >}}

1. 将虚拟服务 `bookinfo` 重置为其原始状态。

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway"}]'
    {{< /text >}}

## 更多特性 {#additional-features}

除了本文所述的查看特性外，Kiali 还有许多特性，例如[集成 Jaeger 跟踪](https://kiali.io/docs/features/tracing/)。

有关这些更多特性的详细信息，请参阅 [Kiali 文档](https://kiali.io/docs/features/)。

若想深度探索 Kiali，建议演练一遍 [Kiali 教程](https://kiali.io/docs/tutorials/)。

## 清理 {#cleanup}

如果您不计划任何后续任务，请从集群中删除 Bookinfo 示例应用程序和 Kiali。

1. 要删除 Bookinfo 应用程序，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明。

1. 要从 Kubernetes 环境中删除 Kiali：

    {{< text bash >}}
    $ kubectl delete -f {{< github_file >}}/samples/addons/kiali.yaml
    {{< /text >}}
