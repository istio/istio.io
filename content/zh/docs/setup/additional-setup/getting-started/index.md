---
title: 开始使用 Istio 和 Kubernetes Gateway API
description: 轻松试用 Istio 的各项功能。
weight: 5
aliases:
    - /zh/docs/setup/kubernetes/getting-started/
    - /zh/docs/setup/kubernetes/
    - /zh/docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes, gateway-api]
owner: istio/wg-environments-maintainers
test: yes
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
以下文档将指导您通过 Gateway API 来使用 Istio。
如果您更喜欢用经过验证的 Istio API 来进行流量管理，
您应转为参阅[这些指示说明](/zh/docs/setup/getting-started/)。
{{< /tip >}}

{{< warning >}}
大多数 Kubernetes 集群上默认并未安装 Kubernetes Gateway API CRD，
因此需要先确保安装了 Kubernetes Gateway API CRD，再使用 Gateway API：

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

{{< /warning >}}

本指南可以让您快速熟悉 Istio。如果您已经熟悉了 Istio
或想要安装其他配置文件或高级的[部署模型](/zh/docs/ops/deployment/deployment-models/)，
请参阅 FAQ 页面：[我应该使用哪种 Istio 安装方法？](/zh/about/faq/#install-method-selection)。

这些步骤需要您有一个运行 Kubernetes ({{< supported_kubernetes_versions >}})
所[支持版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)的
{{< gloss >}}cluster{{< /gloss >}}。您可以使用任意受支持的平台，例如
[Minikube](https://kubernetes.io/zh-cn/docs/tasks/tools/install-minikube/)
或[特定平台安装说明](/zh/docs/setup/platform-setup/)中指定的其他平台。

遵循以下步骤开始使用 Istio：

1. [下载并安装 Istio](#download)
1. [部署样例应用](#bookinfo)
1. [打开应用程序并允许外部流量](#ip)
1. [查看仪表板](#dashboard)

## 下载 Istio {#download}

1.  转到 [Istio 发布]({{< istio_release_url >}})页面下载适合您操作系统的安装文件，
    或下载并自动解压最新的版本（Linux 或 macOS）：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    上述命令将下载 Istio 的最新版本（按数字顺序）。
    您可以通过命令行传递变量，下载特定的版本或重载处理器架构。
    例如要下载 x86_64 架构的 Istio {{< istio_full_version >}}，执行以下命令：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  切换到 Istio 文件包目录。例如，如果文件包是
    `istio-{{< istio_full_version >}}`：

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录包含：

    - 位于 `samples/` 中的样例应用
    - 位于 `bin/` 目录中的 [`istioctl`](/zh/docs/reference/commands/istioctl) 客户端二进制文件。

1.  添加 `istioctl` 客户端到您的路径（Linux 或 macOS）：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## 安装 Istio {#install}

1.  本次安装使用 `demo` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)。
    这个配置文件包含了便于测试的一组默认值，当然您可以使用其他配置文件用于生产或性能测试。

    {{< warning >}}
    如果您的平台有特定于供应商（例如 Openshift）的配置文件，
    可以在以下命令中直接使用而不是采用 `demo` 配置文件。
    更多细节请参阅[平台指示说明](/zh/docs/setup/platform-setup/)。
    {{< /warning >}}

    与 [Istio Gateways](/zh/docs/concepts/traffic-management/#gateways) 不同，
    创建 [Kubernetes Gateways](https://gateway-api.sigs.k8s.io/api-types/gateway/)
    将默认[部署关联的网关代理服务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)。
    因为本例不会使用这些服务，所以将禁用默认的 Istio 网关服务，
    这些默认服务通常是作为 `demo` 配置文件的一部分被安装的。

    {{< text bash >}}
    $ istioctl install -f @samples/bookinfo/demo-profile-no-gateways.yaml@ -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Installation complete
    {{< /text >}}

1.  添加命名空间标签，指示 Istio 在您稍后部署应用时自动注入 Envoy Sidecar 代理：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## 部署样例应用{#bookinfo}

1.  部署 [`Bookinfo` 样例应用](/zh/docs/examples/bookinfo/)：

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

1.  此应用将启动。随着每个 Pod 就绪，Istio Sidecar 将随之被部署。

    {{< text bash >}}
    $ kubectl get services
    NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    details       ClusterIP   10.0.0.212      <none>        9080/TCP   29s
    kubernetes    ClusterIP   10.0.0.1        <none>        443/TCP    25m
    productpage   ClusterIP   10.0.0.57       <none>        9080/TCP   28s
    ratings       ClusterIP   10.0.0.33       <none>        9080/TCP   29s
    reviews       ClusterIP   10.0.0.28       <none>        9080/TCP   29s
    {{< /text >}}

    还有

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

    {{< tip >}}
    再次运行上一条命令，等到所有 Pod 报告 READY `2/2` 且 STATUS 为 `Running`，
    然后转到下一步。这可能要用几分钟时间，具体时间取决于您的平台。
    {{< /tip >}}

1.  确认到此为止一切运行良好。执行以下命令通过检查响应中的页面标题查看应用是否在集群内运行且正在提供 HTML 页面：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## 打开应用并允许对外流量{#ip}

Bookinfo 应用已被部署但还不能从外部进行访问。
要使其能够被访问，您需要创建 Ingress Gateway，将路径映射到网格边缘处的某个路由。

1.  为 Bookinfo 应用创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway/)：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    gateway.gateway.networking.k8s.io/bookinfo-gateway created
    httproute.gateway.networking.k8s.io/bookinfo created
    {{< /text >}}

    因为创建 Kubernetes `Gateway`
    资源也会[部署关联的代理服务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)，
    所以执行以下命令等到 Gateway 就绪：

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw bookinfo-gateway
    {{< /text >}}

1.  确保配置没有问题：

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

### 确定 Ingress IP 和端口{#determing-ingress-ip-and-ports}

1. 设置访问网关的 `INGRESS_HOST` 和 `INGRESS_PORT` 变量：

    {{< boilerplate external-loadbalancer-support >}}

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.status.addresses[0].value}')
    $ export INGRESS_PORT=$(kubectl get gtw bookinfo-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
    {{< /text >}}

1. 设置 `GATEWAY_URL`：

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1. 确保 IP 地址和端口均被成功分配给了环境变量：

    {{< text bash >}}
    $ echo "$GATEWAY_URL"
    169.48.8.37:80
    {{< /text >}}

### 验证外部访问{#confirm}

通过浏览器查看 Bookinfo 产品页面，确认能从集群外访问 Bookinfo 应用。

1.  执行以下命令检索 Bookinfo 应用的对外地址。

    {{< text bash >}}
    $ echo "http://$GATEWAY_URL/productpage"
    {{< /text >}}

1.  将上一条命令的输出粘贴到您的 Web 浏览器中，确认 Bookinfo 产品页面显示正常。

## 查看仪表板{#dashboard}

Istio 集成了[几种](/zh/docs/ops/integrations)不同的遥测应用。
这些可以帮助您了解服务网格的结构，能够显示网格的拓扑，还能分析网格的健康状况。

参阅以下指示说明部署 [Kiali](/zh/docs/ops/integrations/kiali/) 仪表板，
以及 [Prometheus](/zh/docs/ops/integrations/prometheus/)、
[Grafana](/zh/docs/ops/integrations/grafana) 和
[Jaeger](/zh/docs/ops/integrations/jaeger/)。

1.  安装 [Kiali 和其他插件]({{< github_tree >}}/samples/addons)并等待其完成部署。

    {{< text bash >}}
    $ kubectl apply -f samples/addons
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

    {{< tip >}}
    如果尝试安装插件时报错，请重新运行命令。
    因为再次执行命令可以解决一些时序问题。
    {{< /tip >}}

1.  访问 Kiali 仪表板。

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  在左侧导航菜单中，从 _Namespace_ 下拉菜单中选择 _Graph_，选择 _default_。

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Kiali 仪表板显示了网格的概述以及 `Bookinfo` 样例应用中服务之间的关系。
    Kiali 还能过滤显示流量。

    {{< image link="./kiali-example2.png" caption="Kiali Dashboard" >}}

## 下一步{#next-steps}

恭喜完成了评估安装！

以下任务便于初学者使用这个 `demo` 安装进一步评估 Istio 的功能特性：

- [请求路由](/zh/docs/tasks/traffic-management/request-routing/)
- [故障注入](/zh/docs/tasks/traffic-management/fault-injection/)
- [流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)
- [查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
- [图形化显示指标](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
- [访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control/)
- [图形化显示网格](/zh/docs/tasks/observability/kiali/)

自定义 Istio 用于生产之前，请参阅以下资源：

- [部署模型](/zh/docs/ops/deployment/deployment-models/)
- [部署最佳实践](/zh/docs/ops/best-practices/deployment/)
- [Pod 要求](/zh/docs/ops/deployment/requirements/)
- [常规安装指示](/zh/docs/setup/)

## 加入 Istio 社区{#join-istio-community}

欢迎您加入 [Istio 社区](/zh/get-involved/)提问和给出反馈。

## 卸载{#uninstall}

要删除 `Bookinfo` 样例应用及其配置，请参阅
[`Bookinfo` 清理](/zh/docs/examples/bookinfo/#cleanup)。

卸载 Istio 时将删除 RBAC 权限和 `istio-system` 命名空间下的所有资源层次结构。
可以安全地忽略不存在资源的错误，因为它们可能已经被按层次结构删除了。

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

`istio-system` 命名空间默认未被移除。如果不再需要，请执行以下命令将其移除：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

指示 Istio 自动注入 Envoy Sidecar 代理的标签默认未被移除。
如果不再需要，执行以下命令将其移除：

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
