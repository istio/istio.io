---
title: 部署示例应用程序
description: 部署 Bookinfo 示例应用程序。
weight: 2
owner: istio/wg-networking-maintainers
test: yes
---

为了探索 Istio，您需要安装示例
[Bookinfo 应用程序](/zh/docs/examples/bookinfo/)，
它由四个独立的微服务组成，用于演示各种 Istio 功能。

{{< image width="50%" link="./bookinfo.svg" caption="Istio 的 Bookinfo 示例应用程序以多种不同的语言编写" >}}

作为本指南的一部分，您将部署 Bookinfo 应用程序并使用入口网关暴露 `productpage` 服务。

## 部署 Bookinfo 应用程序 {#deploy-the-bookinfo-application}

首先部署应用程序：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-versions.yaml@
{{< /text >}}

要验证应用程序是否正在运行，请检查 Pod 的状态：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods
NAME                             READY   STATUS    RESTARTS   AGE
details-v1-cf74bb974-nw94k       1/1     Running   0          42s
productpage-v1-87d54dd59-wl7qf   1/1     Running   0          42s
ratings-v1-7c4bbf97db-rwkw5      1/1     Running   0          42s
reviews-v1-5fd6d4f8f8-66j45      1/1     Running   0          42s
reviews-v2-6f9b55c5db-6ts96      1/1     Running   0          42s
reviews-v3-7d99fd7978-dm6mx      1/1     Running   0          42s
{{< /text >}}

要从集群外部访问 `productpage` 服务，需要配置入口网关。

## 部署并配置入口网关 {#deploy-and-configure-the-ingress-gateway}

您将使用 Kubernetes Gateway API 部署一个名为 `bookinfo-gateway` 的网关：

{{< text syntax=bash snip_id=deploy_bookinfo_gateway >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/bookinfo-gateway.yaml@
{{< /text >}}

在默认情况下，Istio 会为网关创建一个 `LoadBalancer` 服务。
由于您将通过隧道访问此网关，因此不需要负载均衡器。
通过注解将网关的服务类型更改为 `ClusterIP`：

{{< text syntax=bash snip_id=annotate_bookinfo_gateway >}}
$ kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
{{< /text >}}

要检查网关的状态，请运行：

{{< text bash >}}
$ kubectl get gateway
NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         42s
{{< /text >}}

等待网关按照程序显示后再继续。

## 访问应用程序 {#access-the-application}

您将通过刚刚配置的网关连接到 Bookinfo `productpage` 服务。
要访问网关，您需要使用 `kubectl port-forward` 命令：

{{< text syntax=bash snip_id=none >}}
$ kubectl port-forward svc/bookinfo-gateway-istio 8080:80
{{< /text >}}

打开浏览器并导航到 `http://localhost:8080/productpage` 以查看 Bookinfo 应用程序。

{{< image width="80%" link="./bookinfo-browser.png" caption="Bookinfo 应用程序" >}}

如果您刷新页面，您应该会看到书籍的 ratings 发生变化，
因为请求分布在 `reviews` 服务的不同版本上。

## 下一步 {#next-steps}

[继续下一部分](../secure-and-visualize/)将应用程序添加到网格中，
并了解如何保护和可视化应用程序之间的通信。
