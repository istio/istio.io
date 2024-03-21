---
title: Kubernetes Gateway API 入门
description: 使用 Gateway API 为 Kubernetes 集群配置入口流量。
publishdate: 2022-12-14
attribution: Frank Budinsky (IBM)
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

无论您使用 Istio 或其他服务网格运行 Kubernetes 应用程序服务，
还是仅在 Kubernetes 集群中使用普通服务，
您都需要为集群外部的客户端提供对应用程序服务的访问方式。
如果您使用的是普通 Kubernetes 集群，可能正在使用 Kubernetes
[Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/) 资源来配置入口流量。

一段时间以来，人们都知道 Kubernetes Ingress 资源存在重大缺陷，
尤其是在使用它为大型应用程序配置入口流量以及使用除 HTTP 外的其他协议时问题更为突出。
其中一个问题是它在单个资源中同时配置了客户端 L4-L6 属性（例如端口、TLS 等）和服务端
L7 路由，而对于大型应用程序的配置应该由不同的团队在不同的命名空间中进行管理。
此外，通过尝试在不同的 HTTP 代理之间找到共同点，使得 Ingress 只能支持最基本的
HTTP 路由，并且最终会将先进代理的所有其他功能配置推入到不可移植的注解中。

为了克服 Ingress 的缺点，Istio 曾引入自己用于入口流量管理的配置 API。
基于 Istio 的 API，客户端表达式是使用 Istio Gateway 资源进行定义的，
对于被转移到 VirtualService 的 L7 流量，不巧的是，
它也是使用与在网格内服务之间路由流量相同的配置资源。
尽管 Istio API 为大型应用程序的入口流量管理提供了一个很好的解决方案，
但不幸的是它是一个仅支持 Istio 的 API。如果您使用不同的服务网格实现，
或者环境中根本没有服务网格，那您就不走运了。

## 了解 Gateway API {#enter-gateway-api}

拿最近[升级到 Beta 版](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/)的
[Gateway API](https://gateway-api.sigs.k8s.io/) 来说，
围绕全新的 Kubernetes 流量管理 API，其具有非常多可圈可点的内容。
Gateway API 提供了一套用于入口流量控制的 Kubernetes 配置资源，
与 Istio 的 API 一样，它克服了 Ingress 的缺点，但与 Istio 不同的是，
它是具有广泛行业协议的标准 Kubernetes API。包括正在开发中的 Istio Beta 版 API
的[几个实现](https://gateway-api.sigs.k8s.io/implementations/)，
所以现在可能是开始思考如何将入口流量配置从 Kubernetes Ingress
或 Istio Gateway/VirtualService 转移到新的 Gateway API 的天赐良机。

无论您是否已经使用或计划使用 Istio 来管理服务网格，Gateway API
的 Istio 实现都可以开始被轻松地用于集群的入口控制。由于 Gateway API
本身仍然是 Beta 版的原因，其在 Istio 中的实现也处于 Beta 版，
但由于在其幕后使用了与 Istio 相同且久经考验的内部资源来实现相关配置
Istio 中的 Gateway API 实现也是非常健壮的。

## Gateway API 快速入门 {#gateway-api-quick-start}

要开始使用 Gateway API，您需要先下载它的 CRD，至少目前为止大多数
Kubernetes 集群都没有默认安装这些 CRD：

{{< text bash >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref={{< k8s_gateway_api_version >}}" | kubectl apply -f -; }
{{< /text >}}

安装了这些 CRD 后，您可以使用它们创建 Gateway API 资源来配置入口流量，
但是为了使这些资源正常工作，集群中还需要运行网关控制器。
您可以通过使用简单地最小化配置文件安装 Istio 来启用 Istio 的网关控制器实现：

{{< text bash >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ ./bin/istioctl install --set profile=minimal -y
{{< /text >}}

现在，您的集群已经通过名为 `istio.io/gateway-controller` 的 Istio
网关控制器实现了 Gateway API 的全部功能，并可以随时使用它们。

### 在 Kubernetes 中部署一个目标服务 {#deploy-a-kubernetes-target-service}

为了试用 Gateway API，我们将使用 Istio
[helloworld 示例程序]({{< github_tree >}}/samples/helloworld)作为入口目标服务，
但是仅仅作为一个简单的 Kubernetes 服务运行，并不启用 Sidecar 注入。
因为我们只打算使用 Gateway API 来控制进入“Kubernetes 集群”的入口流量，
所以目标服务在网格内部或外部运行都没有区别。

我们将使用以下命令部署 helloworld 服务：

{{< text bash >}}
$ kubectl create ns sample
$ kubectl apply -f @samples/helloworld/helloworld.yaml@ -n sample
{{< /text >}}

helloworld 服务背后包括两个不同的版本（`v1` 和 `v2`）的部署。
我们可以使用以下命令确认它们是否都在运行中：

{{< text bash >}}
$ kubectl get pod -n sample
NAME                             READY   STATUS    RESTARTS   AGE
helloworld-v1-776f57d5f6-s7zfc   1/1     Running   0          10s
helloworld-v2-54df5f84b-9hxgww   1/1     Running   0          10s
{{< /text >}}

### 配置 helloworld 入口流量 {#configure-the-helloworld-ingress-traffic}

随着 helloworld 服务的启动和运行，我们现在可以使用
Gateway API 为其配置入口流量。

入口端点是使用 [Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway)
资源定义的：

{{< text bash >}}
$ kubectl create namespace sample-ingress
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: sample-gateway
  namespace: sample-ingress
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "*.sample.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

控制器会实现通过 [GatewayClass](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.GatewayClass)
选择的一个 Gateway 资源。集群中必须至少定义一个 GatewayClass
才能具有 Gateway 的功能。在我们的例子中，我们选择 Istio 的网关控制器，
`istio.io/gateway-controller`，通过在 Gateway 中使用
`gatewayClassName: istio` 设置引用其关联的（名为 `istio`）GatewayClass。

请注意，与 Ingress 不同，Kubernetes Gateway 不包含对目标服务
helloworld 的任何引用。使用 Gateway API 后，服务路由被定义在单独的配置资源中，
这些配置资源会附加到 Gateway 中，用于将流量子集定向到特定服务，例如我们示例中的
helloworld。这种分离允许我们在不同的命名空间中定义 Gateway 和路由，
并可以由不同的团队进行管理。至此，在扮演集群操作员的角色时，我们在
`sample-ingress` 命名空间中应用了 Gateway。接下来，我们将代表应用程序开发人员在
与 helloworld 服务相同的 `sample` 命名空间中添加路由。

因为 Gateway 资源的所有权归于集群操作员，它可以很好地用于为多个团队的服务提供入口，
在我们的例子中不仅仅是 helloworld 服务。为了强调这一点，
我们在 Gateway 中将主机名设置为 `*.sample.com`，允许附加多个基于子域名的路由。

在应用 Gateway 资源后，我们需要等待它就绪，然后再获取它的外部地址：

{{< text bash >}}
$ kubectl wait -n sample-ingress --for=condition=programmed gateway sample-gateway
$ export INGRESS_HOST=$(kubectl get -n sample-ingress gateway sample-gateway -o jsonpath='{.status.addresses[0].value}')
{{< /text >}}

接下来，我们将 [HTTPRoute](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute)
附加到 `sample-gateway`（即，使用 `parentRefs`
字段）暴露流量并将其路由到 helloworld 服务：

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

在这里，我们将 helloworld 服务的 `/hello` 路径暴露给集群外部的客户端，
特别通过主机 `helloworld.sample.com` 进行访问。您可以使用 curl 命令确认
helloworld 示例是否可以访问：

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
{{< /text >}}

由于在路由规则中没有配置版本路由，您应该会看到流量会被平均分配，
大约一半由 `helloworld-v1` 处理，另一半由 `helloworld-v2` 处理。

### 配置基于权重的版本路由 {#configure-weight-based-version-routing}

在其他“流量调整”功能中，您可以使用 Gateway API
将所有流量发送到其中一个版本或根据请求百分比拆分流量。例如，
您可以使用以下规则分配 helloworld 流量中的 90% 到 `v1`，10% 到 `v2`：

{{< text bash >}}
$ kubectl apply -n sample -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: sample-gateway
    namespace: sample-ingress
  hostnames: ["helloworld.sample.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld-v1
      port: 5000
      weight: 90
    - name: helloworld-v2
      port: 5000
      weight: 10
EOF
{{< /text >}}

Gateway API 依赖于路由目标的版本特定后端服务定义，
在此示例程序中它们是 `helloworld-v1` 和 `helloworld-v2`。helloworld
示例程序已经包含 helloworld 服务的 `v1` 和 `v2` 版本的定义，
我们只需要运行以下命令来启用它们：

{{< text bash >}}
$ kubectl apply -n sample -f @samples/helloworld/gateway-api/helloworld-versions.yaml@
{{< /text >}}

现在，我们可以再次运行之前的 curl 命令：

{{< text bash >}}
$ for run in {1..10}; do curl -HHost:helloworld.sample.com http://$INGRESS_HOST/hello; done
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
Hello version: v2, instance: helloworld-v2-54dddc5567-2lm7b
Hello version: v1, instance: helloworld-v1-78b9f5c87f-2sskj
{{< /text >}}

这次我们看到，现在 10 个请求中大约有 9 个由 `helloworld-v1` 处理，
而 10 个请求中只有 1 个由 `helloworld-v2` 处理。

## 用于网格内部流量的 Gateway API {#gateway-api-for-internal-mesh-traffic}

您可能已经注意到，我们一直在谈论的 Gateway API 只是作为入口配置 API，
通常称为南北流量管理，而不是用于集群内服务到服务（也称之为东西）流量管理的 API。

如果您正在使用服务网格，则非常希望使用相同的 API
资源来配置入口流量路由和服务内部流量，类似于 Istio 使用相同的
VirtualService 为两者配置路由规则的方式。幸运的是，
Kubernetes Gateway API 正在努力添加这种支持。尽管 Gateway API 不像 Ingress
入口流量那样成熟，但一项被称为[用于网格管理和管控的 Gateway API（GAMMA）](https://gateway-api.sigs.k8s.io/contributing/gamma/)的计划正在为实现这一目标努力着，
Istio [在未来](/zh/blog/2022/gateway-api-beta/)打算让 Gateway API
成为其所有流量管理的默认 API。

首个重要的[网关增强提案（GEP）](https://gateway-api.sigs.k8s.io/geps/gep-1426/) 最近已被接受，
实际上也已经可以在 Istio 中使用。要试用它，您需要使用 Gateway API
的[实验版](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard) CRD，
而不是我们上面安装的标准 Beta 版本。查看 Istio
[请求路由任务](/zh/docs/tasks/traffic-management/request-routing/)来开始您的使用。

## 总结 {#summary}

在本文中，我们了解了如何使用 Istio 轻量级最小化安装来提供用于集群入口流量控制的新
Kubernetes Gateway API 的 Beta 版的实现。对于 Istio 用户，
该 Istio 实现还允许您开始尝试 Gateway API 对网格内东西向流量管理的实验性支持。

Istio 的大部分文档，包括所有 [Ingress 任务](/zh/docs/tasks/traffic-management/ingress/)以及一些网格内部流量管理任务，
都已经支持并行使用 Gateway API 或 Istio 配置 API 进行流量配置。
查看 [Gateway API 任务](/zh/docs/tasks/traffic-management/ingress/gateway-api/)以获取有关
Istio 中 Gateway API 实现的更多信息。
