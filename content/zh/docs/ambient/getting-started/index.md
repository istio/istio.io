---
title: 入门
description: 如何在 Ambient 模式下部署和安装 Istio。
weight: 1
aliases:
  - /zh/docs/ops/ambient/getting-started
  - /zh/latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
test: yes
---

本指南有助于您快速评估 Istio 的
{{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}。
这些步骤要求您有一个运行[受支持版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)的
Kubernetes ({{< supported_kubernetes_versions >}}) {{< gloss >}}Cluster{{< /gloss >}}。
您可以在[任何被支持的 Kubernetes 平台](/zh/docs/setup/platform-setup/)上安装 Istio Ambient 模式，
但为了简单起见，本指南将假设使用 [kind](https://kind.sigs.k8s.io/)。

{{< tip >}}
请注意，Ambient 模式当前需要使用
[istio-cni](/zh/docs/setup/additional-setup/cni)
来配置 Kubernetes 节点，该节点必须作为特权 Pod 运行。
Ambient 模式与之前支持 Sidecar 模式的所有主流 CNI 兼容。
{{< /tip >}}

请按照以下步骤开始使用 Istio 的 Ambient 模式：

1. [下载和安装](#download)
1. [部署相同的应用](#bookinfo)
1. [添加应用到 Ambient](#addtoambient)
1. [确保应用访问安全](#secure)
1. [控制流量](#control)
1. [卸载](#uninstall)

## 下载和安装 {#download}

1.  安装 [kind](https://kind.sigs.k8s.io/)

1.  下载对 Ambient 模式提供 Alpha
    支持的[最新 Istio 版本](/zh/docs/setup/getting-started/#download)（v1.21.0 或更高）。

1.  部署一个新的本地 `kind` 集群：

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

1.  安装大多数 Kubernetes 集群上默认并未安装的 Kubernetes Gateway API CRD：

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
      { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
    {{< /text >}}

1.  使用上面下载的 `istioctl` 版本，
    在 Kubernetes 集群上安装带有 `ambient` 配置文件的 Istio：

    {{< text bash >}}
    $ istioctl install --set profile=ambient --skip-confirmation
    {{< /text >}}

    运行上述命令后，您将得到以下输出，
    表明四个组件（包括 {{< gloss "ztunnel" >}}ztunnel{{< /gloss >}}）已被成功安装！

    {{< text syntax=plain snip_id=none >}}
    ✔ Istio core installed
    ✔ Istiod installed
    ✔ CNI installed
    ✔ Ztunnel installed
    ✔ Installation complete
    {{< /text >}}

1.  使用以下命令验证已安装的组件：

    {{< text bash >}}
    $ kubectl get pods,daemonset -n istio-system
    NAME                                        READY   STATUS    RESTARTS   AGE
    pod/istio-cni-node-btbjf                    1/1     Running   0          2m18s
    pod/istiod-55b74b77bd-xggqf                 1/1     Running   0          2m27s
    pod/ztunnel-5m27h                           1/1     Running   0          2m10s

    NAME                            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
    daemonset.apps/istio-cni-node   1         1         1       1            1           kubernetes.io/os=linux   2m18s
    daemonset.apps/ztunnel          1         1         1       1            1           kubernetes.io/os=linux   2m10s
    {{< /text >}}

## 部署样例应用 {#bookinfo}

您将使用样例 [bookinfo 应用](/zh/docs/examples/bookinfo/)，
这是刚下载的 Istio 发行版默认包含的应用。在 Ambient 模式中，
您将这些应用部署到 Kubernetes 集群的方式与没有 Istio 时的部署方式完全相同。
这意味着您可以先让这些应用在集群中运行，再启用 Ambient 模式，
最后将这些应用接入到网格，无需重启，也无需重新配置这些应用。

{{< warning >}}
使用 Ambient 模式时，请确保 default 命名空间不包含标签
`istio-injection=enabled`，因为您不需要 Istio 将 Sidecar 注入应用程序 Pod。
{{< /warning >}}

1. 启动样例服务：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ kubectl apply -f @samples/sleep/notsleep.yaml@
    {{< /text >}}

    `sleep` 和 `notsleep` 是可以用作 curl 客户端的两个简单应用。

1. 部署一个 Ingress Gateway，这样您可以从集群外访问 bookinfo 应用：

    {{< tip >}}
    要在 `kind` 中获取服务类型为 `Loadbalancer` 的 IP 地址，
    您可能需要安装 [MetalLB](https://metallb.universe.tf/)
    这类工具。更多细节请参阅[此指南](https://kind.sigs.k8s.io/docs/user/loadbalancer/)。
    {{</ tip >}}

    创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway)
    和 [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute)：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
    {{< /text >}}

    设置 Kubernetes Gateway 的环境变量：

    {{< text bash >}}
    $ kubectl wait --for=condition=programmed gtw/bookinfo-gateway
    $ export GATEWAY_HOST=bookinfo-gateway-istio.default
    $ export GATEWAY_SERVICE_ACCOUNT=ns/default/sa/bookinfo-gateway-istio
    {{< /text >}}

1. 测试您的 bookinfo 应用。无论是否有网关都应该能够正常工作。

    {{< text syntax=bash snip_id=verify_traffic_sleep_to_ingress >}}
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
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

## 添加应用到 Ambient 网格 {#addtoambient}

1. 您可以通过简单地标记命名空间来使给定命名空间中的所有 Pod 成为 Ambient 网格的一部分：

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    namespace/default labeled
    {{< /text >}}

    恭喜！您已成功将 default 命名空间中的所有 Pod 添加到网格中。
    请注意，您不必重新启动或重新部署任何内容！

1. 现在，发送一些测试流量：

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

您将在 Ambient 模式的应用之间立即达成 mTLS 通信和 L4 遥测。
如果按照指示说明安装 [Prometheus](/zh/docs/ops/integrations/prometheus/#installation)
和 [Kiali](/zh/docs/ops/integrations/kiali/#installation)，
您将能够在 Kiali 的应用中直观地查看自己的应用：

{{< image link="./kiali-ambient-bookinfo.png" caption="Kiali 仪表盘" >}}

## 确保应用访问安全 {#secure}

将您的应用添加到 Ambient 模式之后，
可以使用 Layer 4 鉴权策略确保应用访问的安全。
该功能允许您基于客户端负载身份来控制到服务的访问或源于服务的访问，
但类似 `GET` 和 `POST` 的这些 HTTP 方法并不在 Layer 7 级别。

### Layer 4 鉴权策略 {#layer-4-authorization-policy}

1. 显式允许 `sleep` 服务账号和 `istio-ingressgateway` 服务账号调用 `productpage` 服务：

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
            principals:
            - cluster.local/ns/default/sa/sleep
            - cluster.local/$GATEWAY_SERVICE_ACCOUNT
    EOF
    {{< /text >}}

1. 确认上述鉴权策略正在工作：

    {{< text bash >}}
    $ # 这条命令应成功
    $ kubectl exec deploy/sleep -- curl -s "http://$GATEWAY_HOST/productpage" | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # 这条命令应成功
    $ kubectl exec deploy/sleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    <title>Simple Bookstore App</title>
    {{< /text >}}

    {{< text bash >}}
    $ # 这条命令应失败且返回连接重置错误码 56
    $ kubectl exec deploy/notsleep -- curl -s http://productpage:9080/ | grep -o "<title>.*</title>"
    command terminated with exit code 56
    {{< /text >}}

### Layer 7 鉴权策略 {#layer-7-authorization-policy}

1. 使用 Kubernetes Gateway API，
   您可以为您的命名空间部署 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}：

    {{< text bash >}}
    $ istioctl x waypoint apply --enroll-namespace --wait
    waypoint default/waypoint applied
    namespace default labeled with "istio.io/use-waypoint: waypoint"
    {{< /text >}}

1. 查看 waypoint 代理状态；您应该看到状态为 `Programmed` 的网关资源的详细信息：

    {{< text bash >}}
    $ kubectl get gtw waypoint -o yaml
    ...
    status:
      conditions:
      - lastTransitionTime: "2024-04-18T14:25:56Z"
        message: Resource programmed, assigned to service(s) waypoint.default.svc.cluster.local:15008
        observedGeneration: 1
        reason: Programmed
        status: "True"
        type: Programmed
    {{< /text >}}

1. 更新您的 `AuthorizationPolicy` 以显式允许 `sleep` 服务通过 `GET`
   访问 `productpage` 服务，但不执行其他操作：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      targetRefs:
      - kind: Service
        group: ""
        name: productpage
      action: ALLOW
      rules:
      - from:
        - source:
            principals:
            - cluster.local/ns/default/sa/sleep
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. 确认新的 waypoint 代理正在执行更新的鉴权策略：

    {{< text bash >}}
    $ # this should fail with an RBAC error because it is not a GET operation
    $ kubectl exec deploy/sleep -- curl -s "http://productpage:9080/productpage" -X DELETE
    RBAC: access denied
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

## 控制流量 {#control}

1. 您可以使用相同的 waypoint 来控制 `reviews` 的流量。
   配置流量路由以将 90% 的请求发送到 `reviews` v1，将 10% 发送到 `reviews` v2：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
    $ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-90-10.yaml@
    {{< /text >}}

1. 确认 100 个请求中大约有 10% 流量转到 reviews-v2：

    {{< text bash >}}
    $ kubectl exec deploy/sleep -- sh -c "for i in \$(seq 1 100); do curl -s http://productpage:9080/productpage | grep reviews-v.-; done"
    {{< /text >}}

## 卸载 {#uninstall}

1. 默认情况下，不会删除指示 Istio 自动将 `default`
   命名空间中的应用程序包含到 Ambient 网格中的标签。
   如果不再需要，请使用以下命令将其删除：

    {{< text bash >}}
    $ kubectl label namespace default istio.io/dataplane-mode-
    $ kubectl label namespace default istio.io/use-waypoint-
    {{< /text >}}

1. 要删除 waypoint 代理、已安装的策略并卸载 Istio：

    {{< text bash >}}
    $ istioctl x waypoint delete --all
    $ istioctl uninstall -y --purge
    $ kubectl delete namespace istio-system
    {{< /text >}}

1. 若要删除 Bookinfo 样例应用及其配置，
   请参阅 [Bookinfo 清理](/zh/docs/examples/bookinfo/#cleanup)。

1. 移除 `sleep` 和 `notsleep` 应用：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    $ kubectl delete -f @samples/sleep/notsleep.yaml@
    {{< /text >}}

1. 如果您安装了 Gateway API CRD，执行以下命令移除：

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref={{< k8s_gateway_api_version >}}" | kubectl delete -f -
    {{< /text >}}
