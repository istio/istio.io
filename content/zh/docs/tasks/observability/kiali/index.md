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

作为此任务的一部分，您将安装 [Kiali](https://www.kiali.io) 附加组件，并使用基于 Web 的图形用户界面来查看网格和 Istio 配置对象的服务图。
最后，您使用 Kiali Public API 返回的 JSON 数据生成图形数据。

{{< idea >}}
这个任务并不包括 Kiali 提供的所有特性。要了解它所支持的全部功能，请查看 [Kiali 官网](http://kiali.io/docs/features/)。
{{< /idea >}}

此任务始终将 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序作为示例。
此任务假设 Bookinfo 应用程序安装在 `bookinfo` 命名空间中。

## 开始之前{#before-you-begin}

遵循 [Kiali 安装](/zh/docs/ops/integrations/kiali/#installation)文档将 Kiali 部署到您的集群中。

## 生成服务图{#generating-a-graph}

1. 要验证服务是否在您的集群中运行，请运行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1. 要确定 Bookinfo URL，请按照说明确定 [Bookinfo ingress `GATEWAY_URL`](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)。

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

1. 登录后立即显示的 **Overview** 页面中查看网格的概述。**Overview** 页面显示了网格中具有服务的所有命名空间。以下屏幕截图显示了类似的页面：

    {{< image width="75%" link="./kiali-overview.png" caption="Example Overview" >}}

1. 要查看命名空间图，请点击 Bookinfo 命名空间卡中的 `bookinfo` 图标。图形图标位于命名空间卡的左下角，看起来像是一组相连的圈子，页面类似于：

    {{< image width="75%" link="./kiali-graph.png" caption="Example Graph" >}}

1. 这个图表示一段时间内流过服务网格的流量。该图使用 Istio 遥测而生成。

1. 要查看度量标准摘要，请选择图中的任何节点或边，以便在右侧的 summary details 面板中显示其度量的详细信息。

1. 要使用不同的图形类型查看服务网格，请从 **Graph Type** 下拉菜单中选择一种图形类型。有几种图形类型可供选择：**App**、**Versioned App**、**Workload**、**Service**。

    * **App** 图形类型将一个应用程序的所有版本聚合到一个图形节点中。以下示例显示了一个单独的 **reviews** 节点，它代表了评论应用程序的三个版本。

        {{< image width="75%" link="./kiali-app.png" caption="Example App Graph" >}}

    * **Versioned App** 图类型显示每个应用程序版本的节点，但是特定应用程序的所有版本都组合在一起。
        下面的示例显示 **reviews** 组框，其中包含三个节点，这些节点代表了评论应用程序的三个版本。

        {{< image width="75%" link="./kiali-versionedapp.png" caption="Example Versioned App Graph" >}}

    * **Workload** 图类型显示了服务网格中每个工作负载的节点。
        这种图类型不需要您使用 `app` 和 `version` 标签，因此，如果您选择在组件上不使用这些标签，这是您将使用的图形类型。

        {{< image width="70%" link="./kiali-workload.png" caption="Example Workload Graph" >}}

    * **Service** 图类型显示网格中每个服务的节点，但从图中排除所有应用程序和工作负载。

        {{< image width="70%" link="./kiali-service-graph.png" caption="Example Service Graph" >}}

## 检查 Istio 配置{#examining-Istio-configuration}

1. 要检查有关 Istio 配置的详细信息，请点击左侧菜单栏上的 **Applications**、**Workloads** 和 **Services** 菜单图标。
    以下屏幕截图显示了 Bookinfo 应用程序信息：

    {{< image width="80%" link="./kiali-services.png" caption="Example Details" >}}

## 流量转移{#traffic-shifting}

您可以使用 Kiali 流量转移向导来定义特定百分比的请求流量以路由到两个或多个工作负载。

1. 查看 `bookinfo` 图的 **Versioned app graph**。

    * 确保已启用 **Traffic Distribution Edge Label** 的 **Display** 选项，以查看路由到每个工作负载的流量百分比。

    * 确保已经已启用 **Show Service Nodes** 的 **Display** 选项，以在图中查看服务节点。

    {{< image width="80%" link="./kiali-wiz0-graph-options.png" caption="Bookinfo Graph Options" >}}

1. 通过点击 `ratings` 服务 (三角形) 节点，将关注点放在 `bookinfo` 图内的 `ratings` 服务上。
    注意，`ratings` 服务流量平均分配给两个 `ratings` 服务 `v1` 和 `v2`（每台服务被路由 50％ 的请求）。

    {{< image width="80%" link="./kiali-wiz1-graph-ratings-percent.png" caption="Graph Showing Percentage of Traffic" >}}

1. 点击侧面板上的 **ratings** 链接进入 `ratings` 服务的详情视图。这也可以通过右键点击 `ratings` 服务节点并从上下文菜单中选择 `Details` 来完成。

1. 从 **Action** 下拉菜单中，选择 **Traffic Shifting** 以流量转移向导。

    {{< image width="80%" link="./kiali-wiz2-ratings-service-action-menu.png" caption="Service Actions Menu" >}}

1. 拖动滑块以指定要路由到每个服务的流量百分比。
    对于 `ratings-v1`，将其设置为 10％；对于 `ratings-v2` ，请将其设置为 90％。

    {{< image width="80%" link="./kiali-wiz3-traffic-shifting-wizard.png" caption="Weighted Routing Wizard" >}}

1. 点击 **Preview** 按钮以查看将由向导生成的 YAML。

    {{< image width="80%" link="./kiali-wiz3b-traffic-shifting-wizard-preview.png" caption="Routing Wizard Preview" >}}

1. 点击 **Create** 按钮以确认应用新的流量设置。

1. 点击左侧导航栏中的 **Graph** 以返回到 `bookinfo` 图表。注意现在 `ratings` 服务节点带有 `virtual service` 图标。

1. 发送请求到 `bookinfo` 应用程序。例如，要每秒发送一个请求，如果您的系统上装有 `watch`，则可以执行以下命令：

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1. 几分钟后，您会注意到流量百分比将反映新的流量路由，从而确认您的新流量路由已成功将所有流量请求的 90％ 路由到 `ratings-v2`。

    {{< image width="80%" link="./kiali-wiz4-traffic-shifting-90-10.png" caption="90% Ratings Traffic Routed to ratings-v2" >}}

## 验证 Istio 配置{#validating-Istio-configuration}

Kiali 可以验证您的 Istio 资源，以确保它们遵循正确的约定和语义。根据错误配置的严重程度，在 Istio 资源的配置中检测到的任何问题都可以标记为错误或警告。有关 Kiali 执行的所有验证检查的列表，请参考 [Kiali Validation 页面](https://kiali.io/docs/features/validations/)。

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

    {{< image width="80%" link="./kiali-validate1-list.png" caption="Services List Showing Invalid Configuration" >}}

1. 点击 **Name** 列中的 **details** 链接，以导航到服务详细信息视图。

1. 将鼠标悬停在错误图标上可以显示描述错误的提示。

    {{< image width="80%" link="./kiali-validate2-errormsg.png" caption="Service Details Describing the Invalid Configuration" >}}

1. 将端口名称改回 `http` 以更正配置，并将 `bookinfo` 返回其正常状态。

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
    {{< /text >}}

    {{< image width="80%" link="./kiali-validate3-ok.png" caption="Service Details Showing Valid Configuration" >}}

## 查看并编辑 Istio YAML 文件配置{#viewing-and-editing-Istio-configuration-YAML}

Kiali 提供了一个 YAML 编辑器，用于查看和编辑 Istio 配置资源。当检测到错误的配置时，YAML 编辑器还将提供验证消息。

1. 在 `bookinfo` VirtualService 中引入一个错误。

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway-invalid"}]'
    {{< /text >}}

1. 点击左侧导航栏上的 `Istio Config` 以导航到 Istio 配置列表。

1. 如果尚未选择，请从 **Namespace** 下拉菜单中选择 `bookinfo`。

1. 请注意错误消息以及错误警告图标，它们会警告您一些配置问题。

    {{< image width="80%" link="./kiali-istioconfig0-errormsgs.png" caption="Istio Config List Incorrect Configuration" >}}

1. 在 `bookinfo` 行的  **Configuration** 列中点击错误图标，导航到 `bookinfo` 虚拟服务视图。

1. 预先选中 **YAML** 页签。请注意验证检查通知已关联的行颜色会突出显示且具有特别的图标。

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml1.png" caption="YAML Editor Showing Validation Notifications" >}}

1. 将鼠标悬停在红色图标上可以查看工具提示消息，该消息提示您验证检查触发了错误。
    有关错误起因和解决方法的更多详细信息，请在 [Kiali Validation 页面](https://kiali.io/docs/features/validations/)上查找验证错误消息。

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml3.png" caption="YAML Editor Showing Error Tool Tip" >}}

1. 将虚拟服务 `bookinfo` 重置为其原始状态。

    {{< text bash >}}
    $ kubectl patch vs bookinfo -n bookinfo --type json -p '[{"op":"replace","path":"/spec/gateways/0", "value":"bookinfo-gateway"}]'
    {{< /text >}}

## 更多特性{#additional-features}

除了本文所述的查看特性外，Kiali 还有许多特性，例如[集成 Jaeger 跟踪](https://kiali.io/docs/features/tracing/)。

有关这些更多特性的详细信息，请参阅 [Kiali 文档](https://kiali.io/docs/features/)。

若想深度探索 Kiali，建议演练一遍 [Kiali 教程](https://kiali.io/docs/tutorials/)。

## 清理{#cleanup}

如果您不计划任何后续任务，请从集群中删除 Bookinfo 示例应用程序和 Kiali。

1. 要删除 Bookinfo 应用程序，请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)说明。

1. 要从 Kubernetes 环境中删除 Kiali：

{{< text bash >}}
$ kubectl delete -f {{< github_file >}}/samples/addons/kiali.yaml
{{< /text >}}
