---
title: 无需 Gateway API 开始使用
description: 使用旧式 Istio API 尝试 Istio 的功能。
weight: 80
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
owner: istio/wg-environments-maintainers
test: yes
---

本指南可让您仅使用其旧版 API 快速评估 Istio。如果您想使用 Kubernetes Gateway API，
[请参阅该示例](/zh/docs/setup/getting-started/)。如果您已经熟悉了 Istio
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

    {{< text bash >}}
    $ istioctl install --set profile=demo -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Egress gateways installed
    ✔ Ingress gateways installed
    ✔ Installation complete
    {{< /text >}}

1.  添加命名空间标签，指示 Istio 在您稍后部署应用时自动注入 Envoy Sidecar 代理：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## 部署样例应用 {#bookinfo}

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

## 打开应用并允许对外流量 {#ip}

Bookinfo 应用已被部署但还不能从外部进行访问。
要使其能够被访问，您需要创建 [Istio Ingress Gateway](/zh/docs/concepts/traffic-management/#gateways)，
将路径映射到网格边缘处的某个路由。

1.  将此应用程序与 Istio Gateway 关联：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

1.  确保配置没有问题：

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

### 确定 Ingress IP 和端口 {#determing-ingress-ip-and-ports}

按照以下说明设置用于访问网关的 `INGRESS_HOST` 和 `INGRESS_PORT` 变量。
使用选项卡选择适用于您所选平台的说明：

{{< tabset category-name="gateway-ip" >}}

{{< tab name="Minikube" category-value="external-lb" >}}

在新的终端窗口中运行此命令以启动将流量发送到 Istio Ingress Gateway 的 Minikube 隧道。
这将为 `service/istio-ingressgateway` 提供外部负载均衡器及 `EXTERNAL-IP`。

{{< text bash >}}
$ minikube tunnel
{{< /text >}}

设置 Ingress 主机和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

确保已成功为每个环境变量分配 IP 地址和端口：

{{< text bash >}}
$ echo "$INGRESS_HOST"
127.0.0.1
{{< /text >}}

{{< text bash >}}
$ echo "$INGRESS_PORT"
80
{{< /text >}}

{{< text bash >}}
$ echo "$SECURE_INGRESS_PORT"
443
{{< /text >}}

{{< /tab >}}

{{< tab name="其他平台" category-value="node-port" >}}

执行以下命令来确定您的 Kubernetes 集群是否在支持外部负载均衡器的环境中运行：

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

如果设置了 `EXTERNAL-IP` 值，则表示您的环境具有可用于 Ingress Gateway 的外部负载均衡器。
如果 `EXTERNAL-IP` 值为 `<none>`（或始终为 `<pending>`），
则表示您的环境不能为 Ingress Gateway 提供外部负载均衡器。在这种情况下，
您可以使用服务的[节点端口](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)访问网关。

选择适合您环境的说明：

如果您确定您的环境具有外部负载均衡器，请按照这些说明进行操作。

设置 Ingress IP 和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
在某些环境中，负载均衡器可能使用主机名而不是 IP 地址来公开。在这种情况下，
Ingress Gateway 的 `EXTERNAL-IP` 值将不是 IP 地址，而是主机名，
并且上述命令将无法设置 `INGRESS_HOST` 环境变量。使用以下命令更正 `INGRESS_HOST` 值：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

如果您的环境没有外部负载均衡器，请按照这些说明操作并选择节点端口。

设置 Ingress 端口：

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

GKE：

{{< text bash >}}
$ export INGRESS_HOST=worker-node-address
{{< /text >}}

您需要创建防火墙规则以允许 TCP 流量进入 `ingressgateway` 服务的端口。
运行以下命令以允许 HTTP 端口、安全端口（HTTPS）或两者的流量：

{{< text bash >}}
$ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
$ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
{{< /text >}}

IBM Cloud Kubernetes Service：

{{< text bash >}}
$ ibmcloud ks workers --cluster cluster-name-or-id
$ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
{{< /text >}}

Docker For Desktop：

{{< text bash >}}
$ export INGRESS_HOST=127.0.0.1
{{< /text >}}

其他环境：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1.  设置 `GATEWAY_URL`:

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1.  确保 IP 地址和端口均被成功分配给了环境变量：

    {{< text bash >}}
    $ echo "$GATEWAY_URL"
    127.0.0.1:80
    {{< /text >}}

### 验证外部访问 {#confirm}

通过浏览器查看 Bookinfo 产品页面，确认可以访问 Bookinfo 应用。

1.  执行以下命令检索 Bookinfo 应用的对外地址。

    {{< text bash >}}
    $ echo "http://$GATEWAY_URL/productpage"
    {{< /text >}}

1.  将上一条命令的输出粘贴到您的 Web 浏览器中，确认 Bookinfo 产品页面显示正常。

## 查看仪表板 {#dashboard}

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

1.  在左侧导航菜单中，从 **Namespace** 下拉菜单中选择 **Graph**，选择 **default**。

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Kiali 仪表板显示了网格的概述以及 `Bookinfo` 样例应用中服务之间的关系。
    Kiali 还能过滤显示流量。

    {{< image link="./kiali-example2.png" caption="Kiali Dashboard" >}}

## 下一步 {#next-steps}

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
- [Pod 要求](/zh/docs/ops/deployment/application-requirements/)
- [常规安装指示](/zh/docs/setup/)

## 加入 Istio 社区 {#join-istio-community}

欢迎您加入 [Istio 社区](/zh/get-involved/)提问和给出反馈。

## 卸载 {#uninstall}

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
