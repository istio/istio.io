---
title: 入门
description: 快速、轻松地尝试 Istio 特性。
weight: 5
aliases:
    - /zh/docs/setup/kubernetes/getting-started/
    - /zh/docs/setup/kubernetes/
    - /zh/docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
test: yes
owner: istio/wg-environments-maintainers
---

{{< tip >}}
{{< boilerplate gateway-api-future >}}
如果您想从 Gateway API 开始使用 Istio，
请参阅[后续入门说明](/zh/docs/setup/additional-setup/getting-started/)而不是以下内容。
{{< /tip >}}

本指南帮您快速评估 Istio。
如果您已经熟悉 Istio，或对安装其他配置类型或高级[部署模型](/zh/docs/ops/deployment/deployment-models/)感兴趣，
请参阅[我们应该采用哪种 Istio 安装方法？](/zh/about/faq/#install-method-selection) 的 FAQ 页面。

完成下面步骤需要您有一个 {{< gloss >}}cluster{{< /gloss >}}，
且运行着兼容版本的 Kubernetes ({{< supported_kubernetes_versions >}})。
您可以使用任何支持的平台，例如：
[Minikube](https://kubernetes.io/zh-cn/docs/tasks/tools/#minikube)
或[特定平台安装说明](/zh/docs/setup/platform-setup/)章节中指定的其他平台。

请按照以下步骤开始使用 Istio：

1. [下载并安装 Istio](#download)
1. [部署示例应用程序](#bookinfo)
1. [对外开放应用程序](#ip)
1. [查看仪表板](#dashboard)

## 下载 Istio {#download}

1.  转到 [Istio 发布]({{< istio_release_url >}}) 页面，下载针对您操作系统的安装文件，
    或用自动化工具下载并提取最新版本（Linux 或 macOS）：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

    {{< tip >}}
    上面的命令下载最新版本（用数值表示）的 Istio。
    您可以给命令行传递变量，用来下载指定的、不同处理器体系的版本。
    例如，要为 x86_64 架构下载 Istio {{< istio_full_version >}}，请运行：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | ISTIO_VERSION={{< istio_full_version >}} TARGET_ARCH=x86_64 sh -
    {{< /text >}}

    {{< /tip >}}

1.  转到 Istio 包目录。例如，如果包是 `istio-{{< istio_full_version >}}`：

    {{< text syntax=bash snip_id=none >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录包含：

    - `samples/` 目录下的示例应用程序
    - `bin/` 目录下的 [`istioctl`](/zh/docs/reference/commands/istioctl) 客户端二进制文件。

1.  将 `istioctl` 客户端添加到路径（Linux 或 macOS）：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

## 安装 Istio {#install}

1.  对于本次安装，我们采用 `demo`
    [配置组合](/zh/docs/setup/additional-setup/config-profiles/)。
    选择它是因为它包含了一组专为测试准备的功能集合，另外还有用于生产或性能测试的配置组合。

    {{< warning >}}
    如果您的平台有供应商提供的配置组合，比如 Openshift，则在下面命令中替换掉 `demo` 配置项。更多细节请参阅[平台说明](/zh/docs/setup/platform-setup/)。
    {{< /warning >}}

    {{< text bash >}}
    $ istioctl install --set profile=demo -y
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ Egress gateways installed
    ✔ Ingress gateways installed
    ✔ Installation complete
    {{< /text >}}

1.  给命名空间添加标签，指示 Istio 在部署应用的时候，自动注入 Envoy 边车代理：

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    namespace/default labeled
    {{< /text >}}

## 部署示例应用 {#bookinfo}

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

1.  应用很快会启动起来。当每个 Pod 准备就绪时，Istio 边车将伴随应用一起部署。

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

    {{< tip >}}
    在执行下一步之前，重新运行上面的命令直到所有的 Pod 达到此状态：就绪状态（READY）的值为 `2/2`、状态（STATUS）的值为 `Running`。
    基于您平台的不同，这个操作过程可能会花费几分钟的时间。
    {{< /tip >}}

1.  确认上面的操作都正确之后，运行下面命令，通过检查返回的页面标题来验证应用是否已在集群中运行，并已提供网页服务：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

## 对外开放应用程序 {#ip}

此时，BookInfo 应用已经部署，但还不能被外界访问。
要开放访问，您需要创建
[Istio 入站网关（Ingress Gateway）](/zh/docs/concepts/traffic-management/#gateways)，
它会在网格边缘把一个路径映射到路由。

1.  把应用关联到 Istio 网关：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
    gateway.networking.istio.io/bookinfo-gateway created
    virtualservice.networking.istio.io/bookinfo created
    {{< /text >}}

1.  确保配置文件没有问题：

    {{< text bash >}}
    $ istioctl analyze
    ✔ No validation issues found when analyzing namespace: default.
    {{< /text >}}

### 确定入站 IP 和端口{#determining-the-ingress-ip-and-ports}

按照说明，为访问网关设置两个变量：`INGRESS_HOST` 和 `INGRESS_PORT`。
使用标签页，切换到您选用平台的说明：

{{< tabset category-name="gateway-ip" >}}

{{< tab name="Minikube" category-value="external-lb" >}}

在新的终端窗口中运行此命令以启动一个 Minikube 隧道，将流量发送到 Istio Ingress Gateway。
这将为 `service/istio-ingressgateway` 提供一个外部负载均衡器 `EXTERNAL-IP`。

{{< text bash >}}
$ minikube tunnel
{{< /text >}}

设置入站主机和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

确保 IP 地址和端口被成功地赋值给了每一个环境变量：

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

执行下面命令以判断您的 Kubernetes 集群环境是否支持外部负载均衡：

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

设置 `EXTERNAL-IP` 的值之后，
您的环境就有了一个外部的负载均衡器，可以将其用作入站网关。
但如果 `EXTERNAL-IP` 的值为 `<none>` (或者一直是 `<pending>` 状态)，
则您的环境则没有提供可作为入站流量网关的外部负载均衡器。
在这个情况下，您还可以用服务（Service）的[节点端口](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)访问网关。

依据您的环境，选择相应的说明：

如果您确定您的环境中确实存在外部的负载均衡，请参照下面的说明。

设置入站 IP 地址和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
在某些环境中，负载均衡器可能使用主机名访问，而不是 IP 地址。
在这种情况下，入站流量网关的 `EXTERNAL-IP` 值不是 IP 地址，而是一个主机名，
那上面设置 `INGRESS_HOST` 环境变量的操作会失败。
使用下面命令纠正 `INGRESS_HOST` 的值。

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

按照下面说明：如果您的环境中没有外部负载均衡器，那就选择一个节点端口来代替。

设置入站的端口：

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

_GKE:_

{{< text bash >}}
$ export INGRESS_HOST=worker-node-address
{{< /text >}}

您需要创建防火墙规则，以允许 TCP 流量发送到 `ingressgateway` 服务地端口。
运行下面的命令，以允许 HTTP 端口或 HTTPS 端口的流量，或两者的流量都允许。

{{< text bash >}}
$ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
$ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
{{< /text >}}

_IBM Cloud Kubernetes Service:_

{{< text bash >}}
$ ibmcloud ks workers --cluster cluster-name-or-id
$ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
{{< /text >}}

_Docker For Desktop:_

{{< text bash >}}
$ export INGRESS_HOST=127.0.0.1
{{< /text >}}

其他环境：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1.  设置环境变量 `GATEWAY_URL`：

    {{< text bash >}}
    $ export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
    {{< /text >}}

1.  确保 IP 地址和端口均成功地赋值给了环境变量：

    {{< text bash >}}
    $ echo "$GATEWAY_URL"
    192.168.99.100:32194
    {{< /text >}}

### 验证外部访问 {#confirm}

用浏览器查看 Bookinfo 应用的产品页面，验证 Bookinfo 已经实现了外部访问。

1.  运行下面命令，获取 Bookinfo 应用的外部访问地址。

    {{< text bash >}}
    $ echo "http://$GATEWAY_URL/productpage"
    {{< /text >}}

1.  把上面命令的输出地址复制粘贴到浏览器并访问，确认 Bookinfo 应用的产品页面是否可以打开。

## 查看仪表板 {#dashboard}

Istio 和[几个](/zh/docs/ops/integrations)遥测应用做了集成。
遥测能帮您了解服务网格的结构、展示网络的拓扑结构、分析网格的健康状态。

使用下面说明部署 [Kiali](/zh/docs/ops/integrations/kiali/) 仪表板、
以及 [Prometheus](/zh/docs/ops/integrations/prometheus/)、
[Grafana](/zh/docs/ops/integrations/grafana)、
还有 [Jaeger](/zh/docs/ops/integrations/jaeger/)。

1.  安装 [Kiali 和其他插件]({{< github_tree >}}/samples/addons)，等待部署完成。

    {{< text bash >}}
    $ kubectl apply -f samples/addons
    $ kubectl rollout status deployment/kiali -n istio-system
    Waiting for deployment "kiali" rollout to finish: 0 of 1 updated replicas are available...
    deployment "kiali" successfully rolled out
    {{< /text >}}

    {{< tip >}}
    如果在安装插件时出错，再运行一次命令。有一些和时间相关的问题，再次运行就能解决。
    {{< /tip >}}

1.  访问 Kiali 仪表板。

    {{< text bash >}}
    $ istioctl dashboard kiali
    {{< /text >}}

1.  在左侧的导航菜单，选择 _Graph_ ，然后在 _Namespace_ 下拉列表中，选择 _default_ 。

    {{< tip >}}
    {{< boilerplate trace-generation >}}
    {{< /tip >}}

    Kiali 仪表板展示了网格的概览以及 `Bookinfo` 示例应用的各个服务之间的关系。
    它还提供过滤器来可视化流量的流动。

    {{< image link="./kiali-example2.png" caption="Kiali 仪表板" >}}

## 后续步骤{#next-steps}

恭喜您完成了评估安装！

对于新手来说，这些任务是非常好的资源，可以借助 `demo` 安装更深入评估 Istio 的特性：

- [请求路由](/zh/docs/tasks/traffic-management/request-routing/)
- [错误注入](/zh/docs/tasks/traffic-management/fault-injection/)
- [流量切换](/zh/docs/tasks/traffic-management/traffic-shifting/)
- [查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
- [可视化指标](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
- [访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control/)
- [可视化网格](/zh/docs/tasks/observability/kiali/)

在您为了生产系统定制 Istio 之前，参阅这些资源：

- [部署模型](/zh/docs/ops/deployment/deployment-models/)
- [部署的最佳实践](/zh/docs/ops/best-practices/deployment/)
- [Pod 的需求](/zh/docs/ops/deployment/requirements/)
- [通用安装说明](/zh/docs/setup/)

## 加入 Istio 社区{#join-the-istio-community}

我们欢迎您加入 [Istio 社区](/zh/get-involved/)，
提出问题，并给我们以反馈。

## 卸载{#uninstall}

删除 `Bookinfo` 示例应用和配置, 参阅[清理 `Bookinfo`](/zh/docs/examples/bookinfo/#cleanup)。

Istio 卸载程序按照层次结构逐级的从 `istio-system` 命令空间中删除 RBAC 权限和所有资源。对于不存在的资源报错，可以安全的忽略掉，毕竟它们已经被分层地删除了。

{{< text bash >}}
$ kubectl delete -f @samples/addons@
$ istioctl uninstall -y --purge
{{< /text >}}

命名空间 `istio-system` 默认情况下并不会被移除。
不需要的时候，使用下面命令移除它：

{{< text bash >}}
$ kubectl delete namespace istio-system
{{< /text >}}

指示 Istio 自动注入 Envoy 边车代理的标签默认也不移除。
不需要的时候，使用下面命令移除它。

{{< text bash >}}
$ kubectl label namespace default istio-injection-
{{< /text >}}
