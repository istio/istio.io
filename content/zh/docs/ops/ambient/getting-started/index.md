---
title: Ambient Mesh 入门
description: 如何部署和安装 Ambient Mesh。
weight: 1
owner: istio/wg-networking-maintainers
test: yes
---

{{< warning >}}
Ambient 目前处于 [Alpha 状态](/zh/docs/releases/feature-stages/#feature-phase-definitions).

请勿在生产环境中使用 Ambient，
务必先行斟酌[特性阶段定义](/zh/docs/releases/feature-stages/#feature-phase-definitions)再行使用 Ambient。
具体而言，`alpha` 版本意味着存在已知的性能、稳定性和安全性问题。
还存在一些计划中的破坏性变更，其中某些变更可能会令升级失败。
这些是进阶至 `beta` 之前需要解决的问题。
{{< /warning >}}

本指南有助于您快速评估 Istio {{< gloss "ambient" >}}ambient service mesh{{< /gloss >}}。
以下操作步骤需要您有一个 {{< gloss >}}cluster{{< /gloss >}} 运行了 Kubernetes ({{< supported_kubernetes_versions >}})
的[支持版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)。
您可以使用所有受支持的平台，例如 [Minikube](https://kubernetes.io/zh-cn/docs/tasks/tools/install-minikube/)
或[特定平台搭建指南](/zh/docs/setup/platform-setup/)中所述的其他平台。

参照以下步骤开始使用 Ambient：

1. [下载和安装](#download)
1. [部署相同的应用](#bookinfo)
1. [添加应用到 Ambient](#addtoambient)
1. [确保应用访问安全](#secure)
1. [控制流量](#control)
1. [卸载](#uninstall)

## 下载和安装 {#download}

1.  下载对 Ambient Mesh 提供 `alpha` 支持的[最新 Istio 版本](https://github.com/istio/istio/releases/tag/1.18.0-alpha.0)。

1.  如果您没有 Kubernetes 集群，可以参照以下命令使用 `kind` 在本地部署一个集群：

    {{< text syntax=bash snip_id=none >}}
    $ kind create cluster --config=- <<EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: ambient
    nodes:
    - role: control-plane
    - role: worker
    - role: worker
    EOF
    {{< /text >}}

1.  `ambient` 配置文件设计用于帮助您开始使用 Ambient Mesh。
    使用刚下载的 `istioctl` 命令，在您的 Kubernetes 集群上安装附带 `ambient` 配置文件的 Istio：

    {{< text bash >}}
    $ istioctl install --set profile=ambient --skip-confirmation
    {{< /text >}}

1.  运行上一条命令后，您将看到以下输出，
    表明（包括 {{< gloss "ztunnel" >}}Ztunnel{{< /gloss >}} 在内的）五个组件已被成功安装！

    {{< text syntax=plain snip_id=none >}}
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ CNI installed
    ✔ Ingress gateways installed
    ✔ Ztunnel installed
    ✔ Installation complete
    {{< /text >}}

1.  执行以下命令确认已安装的组件：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                    READY   STATUS    RESTARTS   AGE
    istio-cni-node-n9tcd                    1/1     Running   0          57s
    istio-ingressgateway-5b79b5bb88-897lp   1/1     Running   0          57s
    istiod-69d4d646cd-26cth                 1/1     Running   0          67s
    ztunnel-lr7lz                           1/1     Running   0          69s
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get daemonset -n istio-system
    NAME             DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   70s
    ztunnel          1         1         1       1            1           <none>                   82s
    {{< /text >}}

## 部署样例应用 {#bookinfo}

您将使用样例 [bookinfo 应用](/zh/docs/examples/bookinfo/)，这是刚下载的 Istio 发行版默认包含的应用。
在 Ambient 模式中，您将这些应用部署到 Kubernetes 集群的方式与没有 Istio 时的部署方式完全相同。
这意味着您可以先让这些应用在集群中运行，再启用 Ambient Mesh，
最后将这些应用接入到网格，无需重启，也无需重新配置这些应用。

{{< warning >}}
确保 default 命名空间未包括标签 `istio-injection=enabled`，
因为使用 Ambient 时，您不会想要 Istio 将 Sidecar 注入到应用 Pod 中。
{{< /warning >}}

{{< text syntax=bash snip_id=none >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
{{< /text >}}

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
$ kubectl apply -f @samples/sleep/notsleep.yaml@
{{< /text >}}

注：`sleep` 和 `notsleep` 是可以用作 curl 客户端的两个简单应用。

将 `productpage` 连接到 Istio Ingress Gateway，
这样您可以从集群外访问 bookinfo 应用：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/bookinfo-gateway.yaml@
{{< /text >}}

测试您的 bookinfo 应用，无论是否有网关都应该能够正常工作。
注：您可以将以下命令中的 `istio-ingressgateway.istio-system` 替换为负载均衡器 IP（或 hostname）：

{{< text syntax=bash snip_id=verify_traffic_sleep_to_ingress >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=verify_traffic_sleep_to_productpage >}}
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=verify_traffic_notsleep_to_productpage >}}
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

## 添加应用到 Ambient {#addtoambient}

您只需给命名空间打标签，就可以作为 Ambient Mesh 的一部分，在给定的命名空间启用所有 Pod：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode=ambient
{{< /text >}}

恭喜！您已成功将 default 命名空间中的所有 Pod 添加到 Ambient Mesh。
体验最佳的地方在于无需重启，也无需重新部署任何组件！

发送一些测试流量：

{{< text syntax=bash snip_id=none >}}
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=none >}}
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=none >}}
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

您将在 Ambient Mesh 的应用之间立即达成 mTLS 通信和 L4 遥测。
如果按照指示说明安装 [Prometheus](/zh/docs/ops/integrations/prometheus/#installation)
和 [Kiali](/zh/docs/ops/integrations/kiali/#installation)，
您将能够在 Kiali 的应用中直观地查看自己的应用：

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali dashboard" >}}

## 确保应用访问安全 {#secure}

将您的应用添加到 Ambient Mesh 之后，可以使用 L4 鉴权策略确保应用访问的安全。
这允许您基于客户端负载身份来控制到服务的访问或源于服务的访问，
但类似 `GET` 和 `POST` 的这些 HTTP 方法并不在 L7 级别。

### L4 鉴权策略{#l4-policy}

显式允许 `sleep` 服务账号和 `istio-ingressgateway` 服务账号调用 `productpage` 服务：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     app: productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
EOF
{{< /text >}}

确认上述鉴权策略正在工作：

{{< text syntax=bash snip_id=none >}}
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://istio-ingressgateway.istio-system/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=none >}}
$ # this should succeed
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

{{< text syntax=bash snip_id=none >}}
$ # this should fail with a connection reset error code 56
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
command terminated with exit code 56
{{< /text >}}

### L7 鉴权策略{#l7-policy}

使用 Kubernetes Gateway API，您可以为使用 `bookinfo-productpage` 服务账号的
`productpage` 服务来部署 {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}}。
转到 `productpage` 服务的所有流量都将通过 L7 代理被协调、执行和观测。
安装在大多数 Kubernetes 集群上默认并未安装的 Kubernetes Gateway CRD。

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.6.1" | kubectl apply -f -; }
{{< /text >}}

为 `productpage` 服务部署 waypoint proxy：

{{< text bash >}}
$ istioctl x waypoint apply --service-account bookinfo-productpage
waypoint default/bookinfo-productpage applied
{{< /text >}}

查看 `productpage` waypoint proxy 状态；您应看到处于 `Ready` 状态的网关资源详情：

{{< text bash >}}
$ kubectl get gtw bookinfo-productpage -o yaml
{{< /text >}}

验证 waypoint proxy 状态为 `Ready`：

{{< text plaintext >}}
...
status:
  conditions:
  - lastTransitionTime: "2023-02-24T03:22:43Z"
    message: Deployed waypoint proxy to "default" namespace for "bookinfo-productpage" service account
    observedGeneration: 1
    reason: Ready
    status: "True"
    type: Ready
{{< /text >}}

更新 `AuthorizationPolicy` 以显式允许 `sleep` 服务账号和 `istio-ingressgateway` 服务账号
`GET` `productpage` 服务，但不执行其他操作：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: productpage-viewer
 namespace: default
spec:
 selector:
   matchLabels:
     istio.io/gateway-name: bookinfo-productpage
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep", "cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

确认上述鉴权策略正在工作：

{{< text bash >}}
$ # this should fail with an RBAC error because it is not a GET operation
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ -X DELETE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>405 Method Not Allowed</title>
<h1>Method Not Allowed</h1>
<p>The method is not allowed for the requested URL.</p>
{{< /text >}}

{{< text bash >}}
$ # this should fail with an RBAC error because the identity is not allowed
$ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/
RBAC: access denied
{{< /text >}}

{{< text bash >}}
$ # this should continue to work
$ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

## 控制流量{#control}

使用 `bookinfo-review` 服务账号为评审服务部署一个 waypoint proxy，
因此转到评审服务的所有流量都将通过 waypoint proxy 进行协调。

{{< text bash >}}
$ istioctl x waypoint apply --service-account bookinfo-reviews
waypoint default/bookinfo-reviews applied
{{< /text >}}

应用评审虚拟服务以控制 90% 流量到 reviews-v1，控制 10% 流量到 reviews-v2。

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-90-10.yaml@
$ kubectl apply -f @samples/bookinfo/networking/destination-rule-reviews.yaml@
{{< /text >}}

确认 100 个请求中大约有 10% 流量转到 reviews-v2：

{{< text bash >}}
$ kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://istio-ingressgateway.istio-system/productpage | grep reviews-v.-; done"
{{< /text >}}

## 卸载 {#uninstall}

若要删除 Bookinfo 样例应用及其配置，请参阅 [`Bookinfo` 清理](/zh/docs/examples/bookinfo/#cleanup)。

若要移除 `sleep` 和 `notsleep` 应用：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
$ kubectl delete -f @samples/sleep/notsleep.yaml@
{{< /text >}}

若要移除 `productpage-viewer` 鉴权策略、waypoint proxy 并卸载 Istio：

{{< text bash >}}
$ kubectl delete authorizationpolicy productpage-viewer
$ istioctl x waypoint delete --service-account bookinfo-reviews
$ istioctl x waypoint delete --service-account bookinfo-productpage
$ istioctl uninstall -y --purge
$ kubectl delete namespace istio-system
{{< /text >}}

指示 Istio 自动在 `default` 命名空间中包括应用程序的标签默认不会被移除。
如果不再需要此标签，请使用以下命令来移除：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}
