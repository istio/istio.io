---
title: TCP 流量转移
description: 展示如何将一个服务的 TCP 流量从旧版本迁移到新版本。
weight: 31
keywords: [traffic-management,tcp-traffic-shifting]
aliases:
    - /zh/docs/tasks/traffic-management/tcp-version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

本任务展示了如何将 TCP 流量从微服务的一个版本迁移到另一个版本。

一个常见的用例是将 TCP 流量从微服务的旧版本逐步迁移到新版本。
在 Istio 中，您可以通过配置一系列路由规则来实现此目标，这些规则将一定比例的 TCP
流量从一个目的地重定向到另一个目的地。

在此任务中，您将会把 100% 的 TCP 流量分配到 `tcp-echo:v1`。
接着，再通过配置 Istio 路由权重把 20% 的 TCP 流量分配到 `tcp-echo:v2`。

{{< boilerplate gateway-api-support >}}

{{< boilerplate gateway-api-experimental >}}

## 开始之前 {#before-you-begin}

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 查看[流量管理](/zh/docs/concepts/traffic-management)概念文档。

## 设置测试环境 {#set-up-the-test-environment}

1.  首先，创建一个命名空间用于测试 TCP 流量迁移。

    {{< text bash >}}
    $ kubectl create namespace istio-io-tcp-traffic-shifting
    {{< /text >}}

1. 部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用程序，作为发送请求的测试源。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

1. 部署 `tcp-echo` 微服务的 `v1` 和 `v2` 版本。

    {{< text bash >}}
    $ kubectl apply -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    {{< /text >}}

## 应用基于权重的 TCP 路由 {#apply-weight-based-TCP-routing}

1. 将所有 TCP 流量路由到微服务 `tcp-echo` 的 `v1` 版本。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) 确定 Ingress IP 和端口：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

遵循[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的指示说明来设置
`TCP_INGRESS_PORT` 和 `INGRESS_HOST` 环境变量。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用以下命令设置 `SECURE_INGRESS_PORT` 和 `INGRESS_HOST` 环境变量：

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting
$ export INGRESS_HOST=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.status.addresses[0].value}')
$ export TCP_INGRESS_PORT=$(kubectl get gtw tcp-echo-gateway -n istio-io-tcp-traffic-shifting -o jsonpath='{.spec.listeners[?(@.name=="tcp-31400")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  通过发送一些 TCP 流量来确认 `tcp-echo` 服务已启动且正在运行。

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:24:57 UTC 2022
    one Mon Nov 12 23:25:00 UTC 2022
    one Mon Nov 12 23:25:02 UTC 2022
    one Mon Nov 12 23:25:05 UTC 2022
    one Mon Nov 12 23:25:07 UTC 2022
    one Mon Nov 12 23:25:10 UTC 2022
    one Mon Nov 12 23:25:12 UTC 2022
    one Mon Nov 12 23:25:15 UTC 2022
    one Mon Nov 12 23:25:17 UTC 2022
    one Mon Nov 12 23:25:19 UTC 2022
    ...
    {{< /text >}}

    请注意，所有时间戳都有一个前缀 “**one**”，说明所有流量都被路由到 `tcp-echo`
    Service 的 `v1` 版本。

4)  通过以下命令，将 20% 流量从 `tcp-echo:v1` 迁移到 `tcp-echo:v2`：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f @samples/tcp-echo/gateway-api/tcp-echo-20-v2.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) 等几秒让新规则传播并确认规则已被替换：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash yaml >}}
$ kubectl get virtualservice tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
  ...
spec:
  ...
  tcp:
  - match:
    - port: 31400
    route:
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v1
      weight: 80
    - destination:
        host: tcp-echo
        port:
          number: 9000
        subset: v2
      weight: 20
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get tcproute tcp-echo -o yaml -n istio-io-tcp-traffic-shifting
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
  ...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: tcp-echo-gateway
    sectionName: tcp-31400
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: tcp-echo-v1
      port: 9000
      weight: 80
    - group: ""
      kind: Service
      name: tcp-echo-v2
      port: 9000
      weight: 20
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  发送更多 TCP 流量到 `tcp-echo` 微服务。

    {{< text bash >}}
    $ export SLEEP=$(kubectl get pod -l app=sleep -n istio-io-tcp-traffic-shifting -o jsonpath={.items..metadata.name})
    $ for i in {1..20}; do \
    kubectl exec "$SLEEP" -c sleep -n istio-io-tcp-traffic-shifting -- sh -c "(date; sleep 1) | nc $INGRESS_HOST $TCP_INGRESS_PORT"; \
    done
    one Mon Nov 12 23:38:45 UTC 2022
    two Mon Nov 12 23:38:47 UTC 2022
    one Mon Nov 12 23:38:50 UTC 2022
    one Mon Nov 12 23:38:52 UTC 2022
    one Mon Nov 12 23:38:55 UTC 2022
    two Mon Nov 12 23:38:57 UTC 2022
    one Mon Nov 12 23:39:00 UTC 2022
    one Mon Nov 12 23:39:02 UTC 2022
    one Mon Nov 12 23:39:05 UTC 2022
    one Mon Nov 12 23:39:07 UTC 2022
    ...
    {{< /text >}}

    请注意，大约 20% 的时间戳带有前缀 “**two**”，说明 80% 的 TCP 流量被路由到
    `tcp-echo` Service 的 `v1` 版本，而 20% 的流量被路由到 `v2` 版本。

## 理解原理 {#understanding-what-happened}

这个任务中，使用 Istio 路由权重特性将 `tcp-echo` 服务的 TCP
流量从旧版本迁移到了新版本。请注意，这与使用容器编排平台的部署功能进行版本迁移完全不同，
后者（容器编排平台）使用了实例扩容来管理流量。

在 Istio 中，可以对 `tcp-echo` 服务的两个版本进行独立扩容和缩容，
这个过程不会影响两个服务版本之间的流量分配。

有关不同版本间流量管理及自动扩缩的更多信息，请查看[使用 Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)这篇博文。

## 清理 {#cleanup}

1. 移除路由规则：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/tcp-echo/gateway-api/tcp-echo-all-v1.yaml@ -n istio-io-tcp-traffic-shifting
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) 移除 `sleep` 样例、`tcp-echo` 应用和测试命名空间：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete -f @samples/tcp-echo/tcp-echo-services.yaml@ -n istio-io-tcp-traffic-shifting
    $ kubectl delete namespace istio-io-tcp-traffic-shifting
    {{< /text >}}
