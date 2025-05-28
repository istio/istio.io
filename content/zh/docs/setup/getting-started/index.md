---
title: 入门
description: 快速、轻松地尝试 Istio 特性。
weight: 5
aliases:
    - /zh/docs/setup/additional-setup/getting-started/
    - /zh/latest/docs/setup/additional-setup/getting-started/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
test: yes
owner: istio/wg-environments-maintainers
---

{{< tip >}}
想要探索 Istio 的 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}？
访问 [Ambient 模式入门](/zh/docs/ambient/getting-started) 指南！
{{< /tip >}}

本指南帮您快速评估 Istio。如果您已经熟悉 Istio，
或对安装其他配置类型或高级[部署模型](/zh/docs/ops/deployment/deployment-models/)感兴趣，
请参阅[我们应该采用哪种 Istio 安装方法？](/zh/about/faq/#install-method-selection) 的 FAQ 页面。

您需要一个 Kubernetes 集群才能继续。如果您没有集群，
则可以使用 [kind](/zh/docs/setup/platform-setup/kind)
或任何其他[受支持的 Kubernetes 平台](/zh/docs/setup/platform-setup)。

请按照以下步骤开始使用 Istio：

1. [下载并安装 Istio](#download)
1. [安装 Kubernetes Gateway API CRD](#gateway-api)
1. [部署示例应用](#bookinfo)
1. [对外开放应用](#ip)
1. [查看仪表板](#dashboard)

## 下载 Istio {#download}

1.  转到 [Istio 发布]({{< istio_release_url >}})页面，下载适用于您操作系统的安装文件，
    或[自动下载并获取最新版本](/zh/docs/setup/additional-setup/download-istio-release)（Linux 或 macOS）：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  转到 Istio 包目录。例如，如果包是 `istio-{{< istio_full_version >}}`：

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录包含：

    - `samples/` 目录下的示例应用
    - `bin/` 目录下的 [`istioctl`](/zh/docs/reference/commands/istioctl) 客户端可执行文件。

1.  将 `istioctl` 客户端添加到路径（Linux 或 macOS）：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## 安装 Istio {#install}

在本指南中，我们使用 `demo` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)。
选择它是为了拥有一组适合测试的默认设置，但还有其他配置文件可用于生产、
性能测试或 [OpenShift](/zh/docs/setup/platform-setup/openshift/)。

与 [Istio Gateway](/zh/docs/concepts/traffic-management/#gateways) 不同，
创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/) 时，
默认情况下还会[部署网关代理服务器](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)。
由于不会使用它们，因此我们禁用通常作为 `demo`
配置文件的一部分安装的默认 Istio Gateway 服务的部署。

1. 使用 `demo` 配置文件安装 Istio，无需任何 Gateway：

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Installation complete
    Made this installation the default for injection and validation.
    {{< /text >}}

1.  给命名空间添加标签，指示 Istio 在部署应用的时候，自动注入 Envoy Sidecar 代理：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## 安装 Kubernetes Gateway API CRD {#gateway-api}

Kubernetes Gateway API CRD 在大多数 Kubernetes 集群上不会默认安装，
因此请确保在使用 Gateway API 之前已安装它们。

1. 如果 Gateway API CRD 尚不存在，请安装它们：

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
    { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

## 部署示例应用 {#bookinfo}

您已将 Istio 配置为将 Sidecar 容器注入到您在 `default` 命名空间中部署的任何应用程序中。

1.  部署 [`Bookinfo` 示例应用](/zh/docs/examples/bookinfo/)：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    service/details created
    serviceaccount/bookinfo-details created
    deployment.apps/details-v1 created
    service/ratings created
    serviceaccount/bookinfo-ratings created
    deployment.apps/ratings-v1 created
    service/reviews created
    serviceaccount/bookinfo-reviews created
    deployment.apps/reviews-v1 created
    deployment.apps/reviews-v2 created
    deployment.apps/reviews-v3 created
    service/productpage created
    serviceaccount/bookinfo-productpage created
    deployment.apps/productpage-v1 created
    {{< /text >}}

    应用很快会启动起来。当每个 Pod 准备就绪时，Istio Sidecar 将伴随应用一起部署。

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    和

    {{< text bash >}}
    $ kubectl get pods
    NAME                              READY   STATUS    RESTARTS   AGE
    details-v1-558b8b4b76-2llld       2/2     Running   0          2m41s
    productpage-v1-6987489c74-lpkgl   2/2     Running   0          2m40s
    ratings-v1-7dc98c7588-vzftc       2/2     Running   0          2m41s
    reviews-v1-7f99cc4496-gdxfn       2/2     Running   0          2m41s
    reviews-v2-7d79d5bd5d-8zzqd       2/2     Running   0          2m41s
    reviews-v3-7dbcdcbc56-m8dph       2/2     Running   0          2m41s
    {{< /text >}}

    请注意，Pod 显示 `READY 2/2`，确认它们具有应用程序容器和 Istio Sidecar 容器。

1.  通过检查响应中的页面标题来验证应用程序是否在集群内运行：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## 对外开放应用 {#ip}

Bookinfo 应用程序已部署，但无法从外部访问。为了使其可访问，
您需要创建一个 Ingress Gateway，它将路径映射到网格边缘的路由。

1.  为 Bookinfo 应用创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/)：

    {{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    默认情况下，Istio 会为网关创建一个 `LoadBalancer` 服务。
    由于我们将通过隧道访问此网关，因此不需要负载均衡器。
    如果您想了解如何为外部 IP 地址配置负载均衡器，
    请阅读 [Ingress Gateway](/zh/docs/tasks/traffic-management/ingress/ingress-control/) 文档。

1.  通过注解网关将服务类型更改为 `ClusterIP`：

    {{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
    $ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
    {{< /text >}}

1.  要检查网关的状态，请运行：

    {{< text bash >}}
    $ kubectl get gateway
    NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
    bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
    {{< /text >}}

## 访问应用程序 {#access-the-application}

您将通过刚刚配置的网关连接到 Bookinfo `productpage` 服务。
要访问网关，您需要使用 `kubectl port-forward` 命令：

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

打开浏览器并导航到 `http://localhost:8080/productpage` 以查看 Bookinfo 应用程序。

{{< image width="80%" link="./bookinfo-browser.png" caption="Bookinfo 应用程序" >}}

如果您刷新页面，您应该会看到书评和评分发生变化，
因为请求分布在 `reviews` 服务的不同版本上。

## 查看仪表板 {#dashboard}

Istio 和[几个遥测应用](/zh/docs/ops/integrations)做了集成。
遥测能帮您了解服务网格的结构、展示网络的拓扑结构、分析网格的健康状态。

使用下面说明部署 [Kiali](/zh/docs/ops/integrations/kiali/) 仪表板、
以及 [Prometheus](/zh/docs/ops/integrations/prometheus/)、
[Grafana](/zh/docs/ops/integrations/grafana)、
还有 [Jaeger](/zh/docs/ops/integrations/jaeger/)。

1.  安装 [Kiali 和其他插件]({{< github_tree >}}/samples/addons)，等待部署完成。

    {{< text bash >}}
    $ kubectl apply -f @samples/addons/kiali.yaml@
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

1.  访问 Kiali 仪表板。

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  在左侧的导航菜单，选择 **Graph**，
    然后在 **Namespace** 下拉列表中，选择 **default**。

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Kiali 仪表板展示了网格的概览以及 `Bookinfo` 示例应用的各个服务之间的关系。
    它还提供过滤器来可视化流量的流动。

    {{< image link="./kiali-example2.png" caption="Kiali 仪表板" >}}

## 后续步骤 {#next-steps}

恭喜您完成了评估安装！

对于新手来说，以下这些任务是非常好的学习资源，
可以借助 `demo` 安装更深入评估 Istio 的特性：

- [请求路由](/zh/docs/tasks/traffic-management/request-routing/)
- [错误注入](/zh/docs/tasks/traffic-management/fault-injection/)
- [流量切换](/zh/docs/tasks/traffic-management/traffic-shifting/)
- [查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
- [可视化指标](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
- [访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control/)
- [可视化网格](/zh/docs/tasks/observability/kiali/)

在您为生产系统定制 Istio 之前，请先参阅这些学习资源：

- [部署模型](/zh/docs/ops/deployment/deployment-models/)
- [部署的最佳实践](/zh/docs/ops/best-practices/deployment/)
- [Pod 的要求](/zh/docs/ops/deployment/application-requirements/)
- [通用安装说明](/zh/docs/setup/)

## 加入 Istio 社区 {#join-the-istio-community}

我们欢迎您加入 [Istio 社区](/zh/get-involved/)，
提出问题，并给我们以反馈。

## 卸载 {#uninstall}

要删除 `Bookinfo` 示例应用和配置，请参阅[清理 `Bookinfo`](/zh/docs/examples/bookinfo/#cleanup)。

Istio 卸载程序按照层次结构逐级地从 `istio-system`
命令空间中删除 RBAC 权限和所有资源。对于不存在的资源报错，
可以安全地忽略掉，毕竟它们已经被分层地删除了。

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

命名空间 `istio-system` 默认情况下并不会被移除。
不需要的时候，使用下面命令移除它：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

指示 Istio 自动注入 Envoy Sidecar 代理的标签默认也不移除。
不需要的时候，使用下面命令移除它。

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}

如果您安装了 Kubernetes Gateway API CRD 并且现在想要删除它们，请运行以下命令之一：

- 如果您运行的任何任务需要**实验版本**的 CRD：

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}

- 否则：

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
