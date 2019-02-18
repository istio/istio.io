---
title: 使用 Google Kubernetes Engine 快速开始
description: 如何使用 Google Kubernetes Engine (GKE) 快速搭建 Istio 服务。
weight: 11
keywords: [kubernetes,gke,google]
---

快速开始操作指南，使用 [Google Cloud Deployment Manager](https://cloud.google.com/deployment-manager/)，在 [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/)（GKE）上安装和运行 Istio。

这个快速开始创建了一个新的 GKE [zonal cluster](https://cloud.google.com/kubernetes-engine/versioning-and-upgrades#available_versions)，安装当前版本的 Istio 并部署 [Bookinfo](/zh/docs/examples/bookinfo/) 样例应用。在 [Kubernetes 安装 Istio 指南](/zh/docs/setup/kubernetes/quick-start/) 的基础上，使用 Deployment Manager 为 Kubernetes Engine 提供一个自动的细化步骤。

## 前置条件

- 本样例需要一个有效的，并且打开了账单功能的 Google Cloud Platform 项目。如果你还没有 GCP 账户，你可以注册一个300美金的[免费试用](https://cloud.google.com/free/)账户。

- 确认为你的项目打开了 [Google Kubernetes Engine API](https://console.cloud.google.com/apis/library/container.googleapis.com/)（并能通过导航条中的 “APIs &amp; Services” -> “Dashboard” 找到）。如果你没有看到 “API enabled”，那么你可能需要点击 “Enable this API” 按钮来开启 API。

- 你必须安装和配置 [`gcloud` command line tool](https://cloud.google.com/sdk/docs/) 并安装 `kubectl` 组件（`gcloud components install kubectl`）。如果你不想在你的电脑上安装 `gcloud` 客户端，你可以通过 [Google Cloud Shell](https://cloud.google.com/shell/docs/) 使用 `gcloud` 来完成同样的事情。

- {{< warning_icon >}} 你必须设置你的默认计算服务账户来包括以下内容：

    - `roles/container.admin`  (Kubernetes Engine Admin)
    - `Editor`  (默认)

为了设置以上内容，如下图所示，在 [Cloud Console](https://console.cloud.google.com/iam-admin/iam/project) 上导航到 **IAM** 章节，并找到你的形如 `projectNumber-compute@developer.gserviceaccount.com` 的默认 GCE/GKE 服务账号。服务账号默认应该仅是 **Editor** 角色。然后在这个账户的 **Roles** 下拉列表中，找到 **Kubernetes Engine** 组，并选择 **Kubernetes Engine Admin** 角色。你的账户将会变成**多重身份**。

{{< image link="/docs/setup/kubernetes/quick-start-gke/dm_gcp_iam.png" caption="GKE-IAM Service" >}}

然后添加 `Kubernetes Engine Admin` 角色:

{{< image width="70%" link="/docs/setup/kubernetes/quick-start-gke/dm_gcp_iam_role.png" caption="GKE-IAM Role" >}}

## 安装

### 启动 Deployment Manager

1. 一旦你的账户和项目启用，点击下面的链接，打开 Deployment Manager。

    [Istio GKE Deployment Manager](https://accounts.google.com/signin/v2/identifier?service=cloudconsole&continue=https://console.cloud.google.com/launcher/config?templateurl={{< github_file >}}/install/gcp/deployment_manager/istio-cluster.jinja&followup=https://console.cloud.google.com/launcher/config?templateurl={{< github_file >}}/install/gcp/deployment_manager/istio-cluster.jinja&flowName=GlifWebSignIn&flowEntry=ServiceLogin)

    就像其他教程中的“如何访问已安装的功能”一样，我们也建议保留默认设置。工具会默认创建一个特殊设置的 GKE alpha cluster，然后安装 Istio [控制平面](/zh/docs/concepts/what-is-istio/#架构)、
    [Bookinfo](/zh/docs/examples/bookinfo/) 样例应用、
    [Grafana](/zh/docs/tasks/telemetry/using-istio-dashboard/) 、
    [Prometheus](/zh/docs/tasks/telemetry/querying-metrics/) 和
    [追踪](/zh/docs/tasks/telemetry/distributed-tracing/) 。
    接下来你可以了解一下怎样访问所有这些功能。脚本只在 `default` 的命名空间中启用 Istio 自动注入。

1.  点击 **Deploy**:

    {{< image link="/docs/setup/kubernetes/quick-start-gke/dm_launcher.png" caption="GKE-Istio Launcher" >}}

等 Istio 完全部署好。注意这会消耗5分钟左右。

### 引导 `gcloud`

部署完成后，在你安装好的 `gcloud` 的工作站里，完成以下事项：

1.  为你刚刚创建的 cluster 引导 `kubectl`，并确认 cluster 在运行中，并且 Istio 是启用状态。

    {{< text bash >}}
    $ gcloud container clusters list
    NAME           LOCATION       MASTER_VERSION  MASTER_IP      MACHINE_TYPE   NODE_VERSION  NUM_NODES  STATUS
    istio-cluster  us-central1-a  1.9.7-gke.1     35.232.222.60  n1-standard-2  1.9.7-gke.1   4          RUNNING
    {{< /text >}}

    这里，这个集群的名字是 `istio-cluster`。

1.  接下来为这个集群获取授权

    {{< text bash >}}
    $ gcloud container clusters get-credentials istio-cluster --zone=us-central1-a
    {{< /text >}}

## 验证安装

验证 Istio 已经安装在它自己的命名空间中

{{< text bash >}}
$ kubectl get deployments,ing -n istio-system
NAME                              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/grafana                    1         1         1            1           4m
deploy/istio-citadel              1         1         1            1           4m
deploy/istio-egressgateway        1         1         1            1           4m
deploy/istio-ingress              1         1         1            1           4m
deploy/istio-ingressgateway       1         1         1            1           4m
deploy/istio-pilot                1         1         1            1           4m
deploy/istio-policy               1         1         1            1           4m
deploy/istio-sidecar-injector     1         1         1            1           4m
deploy/istio-statsd-prom-bridge   1         1         1            1           4m
deploy/istio-telemetry            1         1         1            1           4m
deploy/prometheus                 1         1         1            1           4m
{{< /text >}}

现在确认 Bookinfo 样例应用也已经安装好：

{{< text bash >}}
$ kubectl get deployments,ing
NAME                    DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deploy/details-v1       1         1         1            1           7m
deploy/productpage-v1   1         1         1            1           7m
deploy/ratings-v1       1         1         1            1           7m
deploy/reviews-v1       1         1         1            1           7m
deploy/reviews-v2       1         1         1            1           7m
deploy/reviews-v3       1         1         1            1           7m
{{< /text >}}

现在获取 `istio-ingress` 的 IP：

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   10.59.251.109   35.194.26.85   80:31380/TCP,443:31390/TCP,31400:31400/TCP   6m
{{< /text >}}

记录下已经给 Bookinfo product page 指定好的 IP 和端口。（例子中是 `35.194.26.85:80`）

你也可以在 [Cloud Console](https://console.cloud.google.com/kubernetes/workload) 中的 **Kubernetes Engine -> Workloads** 章节找到这些：

{{< image width="70%" link="/docs/setup/kubernetes/quick-start-gke/dm_kubernetes_workloads.png" caption="GKE-Workloads"  >}}

### 访问 Bookinfo 样例

1.  为 Bookinfo 的外网 IP 创建一个环境变量：

    {{< text bash >}}
    $ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ echo $GATEWAY_URL
    {{< /text >}}

1.  确认一下你可以访问 Bookinfo `http://${GATEWAY_URL}/productpage`:

    {{< image link="/docs/setup/kubernetes/quick-start-gke/dm_bookinfo.png" caption="Bookinfo" >}}

1.  现在可以给它制造点流量：

    {{< text bash >}}
    $ for i in {1..100}; do curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage; done
    {{< /text >}}

## 验证已经安装的 Istio 插件

当你验证了 Istio 控制平面和样例应用正常工作后，尝试访问一下已经安装好的 Istio 插件。

如果你使用 Cloud Shell 而不是已经安装好的 `gcloud` 客户端，你可以使用 [Web Preview](https://cloud.google.com/shell/docs/using-web-preview#previewing_the_application) 功能来进行端口转发和代理。比如，你要用 Cloud Shell 访问 Grafana，那你需要把 `kubectl` 的端口映射从 3000:3000 改成 8080:3000。你可以通过 Web Preview 代理的 8080 到 8084 这些端口，同时预览其他4个控制台。

### Grafana

建立一个 Grafana 通道：

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000 &
{{< /text >}}

然后访问

{{< text plain >}}
http://localhost:3000/dashboard/db/istio-dashboard
{{< /text >}}

你应该可以看到一些你之前发送的请求的统计信息。

{{< image link="/docs/setup/kubernetes/quick-start-gke/dm_grafana.png" caption="Grafana" >}}

更多关于 Grafana 插件的细节，请点击[关于 Grafana 插件](/zh/docs/tasks/telemetry/using-istio-dashboard/#关于-grafana-插件)。

### Prometheus

Prometheus 是和 Grafana 一起安装好的。你可以使用控制台查看如下的 Istio 和应用指标：

{{< text bash >}}
$ kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}') 9090:9090 &
{{< /text >}}

在下面地址可以查看控制台：

{{< text plain >}}
http://localhost:9090/graph
{{< /text >}}

{{< image link="/docs/setup/kubernetes/quick-start-gke/dm_prometheus.png" caption="Prometheus" >}}

更多关于 Prometheus 插件的细节，请点击[关于 Prometheus 插件](/zh/docs/tasks/telemetry/querying-metrics/#关于-prometheus-的附加组件)。

## 追踪

建立一个 Zipkin 通道：

{{< text bash >}}
$ kubectl port-forward -n istio-system $(kubectl get pod -n istio-system -l app=jaeger -o jsonpath='{.items[0].metadata.name}') 16686:16686 &
{{< /text >}}

你就可以在 [http://localhost:16686](http://localhost:16686) 查看之前的追踪统计信息

{{< image link="/docs/setup/kubernetes/quick-start-gke/dm-tracing.png" caption="Tracing Dashboard" >}}

更多关于追踪的细节，请点击[了解一下发生了什么](/zh/docs/tasks/telemetry/distributed-tracing/overview/#understanding-what-happened)。

## 卸载

1. 在 [https://console.cloud.google.com/deployments](https://console.cloud.google.com/deployments) 找到 Cloud Console 的 Deployments 章节。

1. 选择 `deployment` 并点击 **Delete**。

1. Deployment Manager 将会删除所有已经部署的 GKE 组件。但是，有一些元素会被保留，比如 `Ingress` 和 `LoadBalancers`。你可以通过再次进入 cloud console 的 [**Network Services** -> **Load balancing**](https://console.cloud.google.com/net-services/loadbalancing/loadBalancers/list) 来删除这些组件。
