---
title: 网络可视化
description: 此任务向您展示如何在 Istio 网格中可视化服务。
weight: 49
keywords: [telemetry,visualization]
aliases:
 - /zh/docs/tasks/telemetry/kiali/
---

此任务向您展示如何可视化 Istio 网格的不同方面。

作为此任务的一部分，您将安装 [Kiali](https://www.kiali.io) 附加组件，并使用基于 Web 的图形用户界面来查看网格和 Istio 配置对象的服务图。
最后，您使用 Kiali Public API 返回的 JSON 数据生成图形数据。

{{< idea >}}
这个任务并不包括 Kiali 提供的所有特性。要了解它所支持的全部功能，请查看 [Kiali 官网](http://kiali.io/documentation/features/)。
{{< /idea >}}

此任务始终将 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序作为示例。

## 开始之前{#before-you-begin}

{{< tip >}}
以下说明假设您已安装过 `istioctl` 并使用它来安装 Kiali。
不使用 `istioctl` 来安装 Kiali, 请参考 [Kiali 安装说明](https://www.kiali.io/documentation/getting-started/)。
{{< /tip >}}

### 创建 secret{#create-a-secret}

{{< tip >}}
如果您打算按照 [Istio 快速入门](/zh/docs/setup/getting-started/)说明使用 Istio 演示配置文件安装 Kiali，则会为您创建一个默认 secret，用户名为 `admin` ，密码为 `admin`。 因此，您可以跳过此部分。
{{< /tip >}}

在 Istio 命名空间中创建一个 Secret，作为 Kiali 的身份验证凭据。

首先，定义要用作 Kiali 用户名和密码的凭据。

当提示出现时输入 Kiali 用户名：

{{< text bash >}}
$ KIALI_USERNAME=$(read -p 'Kiali Username: ' uval && echo -n $uval | base64)
{{< /text >}}

当提示出现时输入 Kiali 密码：

{{< text bash >}}
$ KIALI_PASSPHRASE=$(read -sp 'Kiali Passphrase: ' pval && echo -n $pval | base64)
{{< /text >}}

如果使用的是 Z Shell `zsh`，请使用以下内容定义凭据：

{{< text bash >}}
$ KIALI_USERNAME=$(read '?Kiali Username: ' uval && echo -n $uval | base64)
$ KIALI_PASSPHRASE=$(read -s "?Kiali Passphrase: " pval && echo -n $pval | base64)
{{< /text >}}

运行以下命令创建 secret：

{{< text bash >}}
$ NAMESPACE=istio-system
$ kubectl create namespace $NAMESPACE
{{< /text >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: kiali
  namespace: $NAMESPACE
  labels:
    app: kiali
type: Opaque
data:
  username: $KIALI_USERNAME
  passphrase: $KIALI_PASSPHRASE
EOF
{{< /text >}}

### 通过 `istioctl` 安装{#install-Via-`istioctl`}

创建 Kiali secret 后，请参照 `istioctl` [安装说明](/zh/docs/setup/install/istioctl/)来安装 Kiali。
例如：

{{< text bash >}}
$ istioctl manifest apply --set values.kiali.enabled=true
{{< /text >}}

{{< idea >}}
该任务不讨论 Jaeger 和 Grafana。 如果已经在集群中安装了它们，并且想了解 Kiali 如何与它们集成，则必须将其他参数传递给 `helm` 命令，例如：

{{< text bash >}}
$ istioctl manifest apply \
    --set values.kiali.enabled=true \
    --set "values.kiali.dashboard.jaegerURL=http://jaeger-query:16686" \
    --set "values.kiali.dashboard.grafanaURL=http://grafana:3000"
{{< /text >}}

{{< /idea >}}

安装 Istio 和 Kiali 后，部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

### 运行在 OpenShift{#running-on-OpenShift}

当 Kiali 在 OpenShift 上运行时，它需要访问一些 OpenShift 特定的资源才能正常运行，
在安装 Kiali 之后，可以使用以下命令完成此操作：

{{< text bash >}}
$ oc patch clusterrole kiali -p '[{"op":"add", "path":"/rules/-", "value":{"apiGroups":["apps.openshift.io"], "resources":["deploymentconfigs"],"verbs": ["get", "list", "watch"]}}]' --type json
$ oc patch clusterrole kiali -p '[{"op":"add", "path":"/rules/-", "value":{"apiGroups":["project.openshift.io"], "resources":["projects"],"verbs": ["get"]}}]' --type json
$ oc patch clusterrole kiali -p '[{"op":"add", "path":"/rules/-", "value":{"apiGroups":["route.openshift.io"], "resources":["routes"],"verbs": ["get"]}}]' --type json
{{< /text >}}

## 生成服务图{#generating-a-service-graph}

1.  要验证服务是否在您的群集中运行，请运行以下命令：

    {{< text bash >}}
    $ kubectl -n istio-system get svc kiali
    {{< /text >}}

1.  要确定 Bookinfo URL，请按照说明确定 [Bookinfo ingress `GATEWAY_URL`](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port).

1.  要将流量发送到网格，您有三种选择

    *   在浏览器中访问 `http://$GATEWAY_URL/productpage`

    *   多次使用以下命令：

        {{< text bash >}}
        $ curl http://$GATEWAY_URL/productpage
        {{< /text >}}

    *   如果您在系统中安装了 `watch` 命令，请通过以下方式连续发送请求：

        {{< text bash >}}
        $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
        {{< /text >}}

1.  要打开 Kiali UI，请在您的 Kubernetes 环境中执行以下命令：

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  要登录 Kiali UI，请到 Kiali 登录界面，然后输入存储在 Kiali secret 中的用户名和密码。

1.  登录后立即显示的 **Overview** 页面中查看网格的概述。**Overview** 页面显示了网格中具有服务的所有名称空间。以下屏幕截图显示了类似的页面：

    {{< image width="75%" link="./kiali-overview.png" caption="Example Overview" >}}

1.  要查看名称空间图，请单击 Bookinfo 名称空间卡中的 `bookinfo` 图标。 图形图标位于名称空间卡的左下角，看起来像是一组相连的圈子，页面类似于：

    {{< image width="75%" link="./kiali-graph.png" caption="Example Graph" >}}

1.  要查看度量标准摘要，请选择图中的任何节点或边，以便在右侧的 summary details 面板中显示其度量的详细信息。

1.  要使用不同的图形类型查看服务网格，请从 **Graph Type** 下拉菜单中选择一种图形类型。有几种图形类型可供选择： **App**, **Versioned App**, **Workload**, **Service**。

    *   **App** 图形类型将一个应用程序的所有版本聚合到一个图形节点中。以下示例显示了一个单独的 **reviews** 节点，它代表了评论应用程序的三个版本。

        {{< image width="75%" link="./kiali-app.png" caption="Example App Graph" >}}

    *   **Versioned App** 图类型显示每个应用程序版本的节点，但是特定应用程序的所有版本都组合在一起。
        下面的示例显示 **reviews** 组框，其中包含三个节点，这些节点代表了评论应用程序的三个版本。

        {{< image width="75%" link="./kiali-versionedapp.png" caption="Example Versioned App Graph" >}}

    *   **Workload** 图类型显示了服务网格中每个工作负载的节点。
        这种图类型不需要您使用 `app` 和 `version` 标签，因此，如果您选择在组件上不使用这些标签， 这是您将使用的图形类型。

        {{< image width="70%" link="./kiali-workload.png" caption="Example Workload Graph" >}}

    *   **Service** 图类型显示网格中每个服务的节点，但从图中排除所有应用程序和工作负载。

        {{< image width="70%" link="./kiali-service-graph.png" caption="Example Service Graph" >}}

## 检查 Istio 配置{#examining-Istio-configuration}

1.  要检查有关 Istio 配置的详细信息，请单击左侧菜单栏上的 **Applications**，**Workloads** 和 **Services** 菜单图标。
    以下屏幕截图显示了 Bookinfo 应用程序信息：

    {{< image width="80%" link="./kiali-services.png" caption="Example Details" >}}

## 创建加权路由{#creating-weighted-routes}

您可以使用 Kiali 加权路由转发来定义特定百分比的请求流量以路由到两个或多个工作负载。

1.  查看 `bookinfo` 图的 **Versioned app graph**。

    *   确保已经在 **Edge Labels** 下拉菜单中选择了 **Requests percentage** ，以查看路由到每个工作负载的流量百分比。

    *   确保已经选中 **Display** 下拉菜单中的 **Service Nodes** 复选框，以便在图中查看服务节点。

    {{< image width="80%" link="./kiali-wiz0-graph-options.png" caption="Bookinfo Graph Options" >}}

1.  通过单击 `ratings` 服务 (triangle) 节点，将关注点放在 `bookinfo` 图内的 `ratings` 服务上。
    注意，`ratings` 服务流量平均分配给两个 `ratings` 服务 `v1` 和 `v2`（每台服务被路由 50％ 的请求）。

    {{< image width="80%" link="./kiali-wiz1-graph-ratings-percent.png" caption="Graph Showing Percentage of Traffic" >}}

1.  点击侧面板上的 **ratings** 链接，进入 `ratings` 服务的服务视图。

1.  从 **Action** 下拉菜单中，选择 **Create Weighted Routing** 以访问加权路由向导。

    {{< image width="80%" link="./kiali-wiz2-ratings-service-action-menu.png" caption="Service Action Menu" >}}

1.  拖动滑块以指定要路由到每个服务的流量百分比。
    对于 `ratings-v1`，将其设置为 10％； 对于 `ratings-v2` ，请将其设置为 90％。

    {{< image width="80%" link="./kiali-wiz3-weighted-routing-wizard.png" caption="Weighted Routing Wizard" >}}

1.  单击 **Create** 按钮以创建新的路由。

1.  点击左侧导航栏中的 **Graph** 以返回到 `bookinfo` 图表。

1.  发送请求到 `bookinfo` 应用程序。例如，要每秒发送一个请求，如果您的系统上装有 `watch`，则可以执行以下命令：

    {{< text bash >}}
    $ watch -n 1 curl -o /dev/null -s -w %{http_code} $GATEWAY_URL/productpage
    {{< /text >}}

1.  几分钟后，您会注意到流量百分比将反映新的流量路由，从而确认您的新流量路由已成功将所有流量请求的 90％ 路由到 `ratings-v2`。

    {{< image width="80%" link="./kiali-wiz4-ratings-weighted-route-90-10.png" caption="90% Ratings Traffic Routed to ratings-v2" >}}

## 验证 Istio 配置{#validating-Istio-configuration}

Kiali 可以验证您的 Istio 资源，以确保它们遵循正确的约定和语义。根据错误配置的严重程度，在 Istio 资源的配置中检测到的任何问题都可以标记为错误或警告。有关 Kiali 执行的所有验证检查的列表，请参考 [Kiali Validations page](http://kiali.io/documentation/validations/)。

{{< idea >}}
Istio 1.4 引入了 `istioctl analyze`，它使您能够以在 CI 管道中使用的方式执行类似的分析。
{{< /idea >}}

强制对服务端口名称进行无效配置，以查看 Kiali 如何报告验证错误。

1.  将 `details` 服务的端口名从 `http` 更改为 `foo`：

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"foo"}]'
    {{< /text >}}

1.  通过单击左侧导航栏上的 **Services**，导航到 **Services** 列表。

1.  如果尚未选择，请从 **Namespace** 下拉菜单中选择 `bookinfo`。

1.  注意在 `details` 行的 **Configuration** 列中显示的错误图标。

    {{< image width="80%" link="./kiali-validate1-list.png" caption="Services List Showing Invalid Configuration" >}}

1.  单击 **Name** 列中的 **details** 链接，以导航到服务详细信息视图。

1.  将鼠标悬停在错误图标上可以显示描述错误的提示。

    {{< image width="80%" link="./kiali-validate2-errormsg.png" caption="Service Details Describing the Invalid Configuration" >}}

1.  将端口名称改回 `http` 以更正配置，并将 `bookinfo` 返回其正常状态。

    {{< text bash >}}
    $ kubectl patch service details -n bookinfo --type json -p '[{"op":"replace","path":"/spec/ports/0/name", "value":"http"}]'
    {{< /text >}}

    {{< image width="80%" link="./kiali-validate3-ok.png" caption="Service Details Showing Valid Configuration" >}}

## 查看并编辑 Istio YAML 文件配置{#viewing-and-editing-Istio-configuration-YAML}

Kiali 提供了一个 YAML 编辑器，用于查看和编辑 Istio 配置资源。当检测到错误的配置时，YAML 编辑器还将提供验证消息。

1.  创建 Bookinfo 目标规则：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
    {{< /text >}}

1.  单击左侧导航栏上的 `Istio Config` 以导航到 Istio 配置列表。

1.  如果尚未选择，请从 **Namespace** 下拉菜单中选择 `bookinfo`。

1.  请注意错误消息以及错误警告图标，它们会警告您一些配置问题。

    {{< image width="80%" link="./kiali-istioconfig0-errormsgs.png" caption="Istio Config List Incorrect Configuration Messages" >}}

1.  将鼠标悬停在 `details` 行的 **Configuration** 列中的错误图标上，以查看其他消息。

    {{< image width="80%" link="./kiali-istioconfig1-tooltip.png" caption="Istio Config List Incorrect Configuration Tool Tips" >}}

1.  单击 **Name** 列中的 **details** 链接，以导航到 `details` 目标规则视图。

1.  请注意消息和图标，它们提醒您一些失败的验证规则。

    {{< image width="80%" link="./kiali-istioconfig2-details-errormsgs.png" caption="Istio Configuration Details View Showing Errors" >}}

1.  单击 **YAML** 选项卡以查看此 Istio 目标规则资源的 YAML。

1.  请注意未通过验证检查的行颜色会突出显示和异常图标。

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml1.png" caption="YAML Editor Showing Validation Errors and Warnings" >}}

1.  将鼠标悬停在黄色图标上可以查看工具提示消息，该消息提示您触发了警告的验证检查。
    有关警告起因和解决方法的更多详细信息，请在 [Kiali Validations page](http://kiali.io/documentation/validations/) 上查找验证警告消息。

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml2.png" caption="YAML Editor Showing Warning Tool Tip" >}}

1.  将鼠标悬停在红色图标上可以查看工具提示消息，该消息提示您触发错误的验证检查。有关错误原因和解决方法的更多详细信息，请在 [Kiali Validations page](http://kiali.io/documentation/validations/) 上查找验证错误消息。

    {{< image width="80%" link="./kiali-istioconfig3-details-yaml3.png" caption="YAML Editor Showing Error Tool Tip" >}}

1.  删除目标规则，使 `bookinfo` 返回其原始状态。

    {{< text bash >}}
    $ kubectl delete -f samples/bookinfo/networking/destination-rule-all.yaml
    {{< /text >}}

## 关于 Kiali Public API{#about-the-Kiali-Public-API}

要生成代表图表和其他指标，运行状况和配置信息的 JSON 文件，您可以访问
[Kiali Public API](https://www.kiali.io/api)。
例如，将浏览器指向 `$KIALI_URL/api/namespaces/graph?namespaces=bookinfo&graphType=app` 以使用 `app` 图形类型获取图形的 JSON 表示形式。

Kiali Public API 建立在 Prometheus 查询之上，并且取决于标准的 Istio 度量配置。
它还会调用 Kubernetes API 以获取有关您的服务的其他详细信息。
为了获得使用 Kiali 的最佳体验，请在应用程序组件上使用元数据标签 `app` 和 `version`。 作为模板，Bookinfo 示例应用程序遵循此约定。

## 清理{#cleanup}

如果您不计划任何后续任务，请从群集中删除 Bookinfo 示例应用程序和 Kiali。

1. 要删除 Bookinfo 应用程序，请参阅 [Bookinfo cleanup](/zh/docs/examples/bookinfo/#cleanup) 说明。

1. 要从 Kubernetes 环境中删除 Kiali，请删除所有带有 `app=kiali` 标签的组件：

{{< text bash >}}
$ kubectl delete all,secrets,sa,configmaps,deployments,ingresses,clusterroles,clusterrolebindings,customresourcedefinitions --selector=app=kiali -n istio-system
{{< /text >}}
