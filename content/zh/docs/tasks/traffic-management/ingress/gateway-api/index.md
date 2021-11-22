---
title: Kubernetes Gateway API
description: 描述在 Istio 中如何配置 Kubernetes Gateway API。
weight: 50
aliases:
    - /docs/tasks/traffic-management/ingress/service-apis/
    - /latest/docs/tasks/traffic-management/ingress/service-apis/
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

本任务描述如何配置 Istio ，以使用 Kubernetes Gateway API 在 Service Mesh 集群外部暴露服务。
这些 API 是 Kubernetes [Service](https://kubernetes.io/zh/docs/concepts/services-networking/service/) 和 [Ingress](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/) API 的积极发展演进。



{{< warning >}}
该特性目前被认为是 alpha 版本。
API (由 Kubernetes SIG-NETWORK 拥有)和 Istio 的实现方式都有可能在进一步升级之前发生改变。
{{< /warning >}}。

## 设置 {#setup}

1. 在大多数 Kubernetes 集群中，默认情况下不会安装 Gateway API。如果 Gateway API CRD 不存在，请安装：

    {{< text bash >}}
    $ kubectl get crd gateways.gateway.networking.k8s.io || { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v0.4.0" | kubectl apply -f -; }
    {{< /text >}}

## 与 Istio API 的区别{#differences-from-Istio-APIs }

Gateway API 与 Istio API (如 Gateway 和 VirtualService )有很多相似之处。
主资源使用相同的 `Gateway` 名称，并且这些资源服务于相类似的目标。

新的 Gateway API 致力于从 Kubernetes 的各种 Ingress 实现（包括 Istio）中吸取经验，以构建标准化的，独立于供应商的 API。
这些 API 通常与 Istio Gateway 和 VirtualService 具有相同的用途，但有一些关键的区别：

*  Istio API 中的`Gateway` 仅配置已部署的现有网关 Deployment/Service，而在 Gateway API 中的`Gateway` 资源不仅配置也会部署网关。有关更多信息，请参阅具体 [部署方法](#deployment-methods) 。
* 在 Istio `VirtualService` 中，所有协议都在单一的资源中配置，
而在 Gateway API 中，每种协议类型都有自己的资源，例如 `HTTPRoute` 和 `TCPRoute`。
* 虽然 Gateway API  提供了大量丰富的路由功能，但它还没有涵盖 Istio 的全部特性。
  因此，正在进行的工作是扩展 API 以覆盖这些用例，以及利用 API 的[可拓展性](https://gateway-api.sigs.k8s.io/#gateway-api-concepts)来更好地暴露 Istio 的功能。

## 配置网关 {#configuring-a-gateway}

有关 API 的信息，请参阅 [Gateway API](https://gateway-api.sigs.k8s.io/) 文档。

在本例中，我们将部署一个简单的应用程序，并使用 `Gateway` 将其暴露到外部。

1. 首先部署一个测试应用:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 部署 Gateway API 配置：

    {{< text bash >}}
    $ kubectl create namespace istio-ingress
    $ kubectl apply -f - <<EOF
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-ingress
    spec:
      gatewayClassName: istio
      listeners:

      - name: default
        hostname: "*.example.com"
        port: 80
        protocol: HTTP
        allowedRoutes:
          namespaces:
            from: All
    ---
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
    spec:
      parentRefs:
      - name: gateway
        namespace: istio-ingress
        hostnames: ["httpbin.example.com"]
        rules:
      - matches:
        - path:
            type: PathPrefix
            value: /get
            filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
            - name: my-added-header
              value: added-value
              backendRefs:
        - name: httpbin
          port: 8000
          EOF
          {{< /text >}}

1.  设置主机 Ingress

    {{< text bash >}}
    $ kubectl wait -n istio-ingress --for=condition=ready gateways.gateway.networking.k8s.io gateway
    $ export INGRESS_HOST=$(kubectl get gateways.gateway.networking.k8s.io gateway -n istio-ingress -ojsonpath='{.status.addresses[*].value}')
    {{< /text >}}

1.  使用 *curl* 访问 *httpbin* 服务：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    请注意，使用 `-H` 标志可以将 *Host* HTTP 标头设置为"httpbin.example.com"。这一步是必需的，因为 `HTTPRoute` 已配置为处理"httpbin.example.com"的请求，但是在测试环境中，该主机没有 DNS 绑定，只是将请求发送到入口 IP。
    
1.  访问其他没有被显式暴露的 URL 时，将看到 HTTP 404 错误：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## 部署方法{#deployment-methods}

在上面的示例中，在配置网关之前，您不需要安装 ingress 网关 `Deployment` 。因为在默认配置中会根据 `Gateway` 配置自动分发网关`Deployment` 和 `Service` ，但是对于高级别的用例，仍然允许手动部署。

### 自动部署{#automated-deployment}

默认情况下，每个 `Gateway` 将自动提供相同名称的 `Service` 和 `Deployment`。如果 `Gateway` 发生变化(例如添加了一个新端口)，这些配置将会自动更新。

这些资源可以通过以下几种方式进行定义：

* 将`Gateway` 上的注释和标签复制到 `Service` 和 `Deployment`。这就允许配置从上述字段中读取到的内容，如配置[内部负载均衡器](https://kubernetes.io/zh/docs/concepts/services-networking/service/#internal-load-balancer)等。
* Istio 提供了一个额外的注释来配置生成的资源:

    |Annotation| 用途                                                         |
    |----------|-------|
    |`networking.istio.io/service-type`|控制 `Service.spec.type` 字段。 例如，设置 `ClusterIP` 为不对外暴露服务 ， 将会默认为`LoadBalancer` 。|

* 通过配置 `addresses` 字段可以显式设置 `Service.spec.loadBalancerIP` 字段：

    {{< text yaml >}}
    apiVersion: gateway.networking.k8s.io/v1alpha2
    kind: Gateway
    metadata:
      name: gateway
    spec:
      addresses:
    
      - value: 192.0.2.0
        type: IPAddress
        ...
        {{< /text >}}

请注意:仅能指定一个地址。

* (高级用法)生成的 Pod 配置可以通过[自定义注入模板](/docs/setup/additional-setup/sidecar-injection/#custom-templates-experimental)进行配置。

### 手动部署{#manual-deployment}

如果您不希望使用自动部署，可以进行[手动配置](/docs/setup/additional-setup/gateway/) `Deployment` 和 `Service`。

完成此选项后，您将需要手动将 `Gateway` 链接到 `Service`，并保持它们的端口配置同步。

要将 `Gateway` 链接到 `Service`，需要将 `addresses` 字段配置为指向**单个**主机名。

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: gateway
spec:
  addresses:

  - value: ingress.istio-gateways.svc.cluster.local
    type: Hostname
    ...
    {{< /text >}}

## 网格流量{#Mesh-Traffic}

Gateway API 也可以用来配置网格流量，具体做法是先配置 `parentRef` ，然后指向`istio` `Mesh`来实现的。这个资源实际上并不存在于集群中，只是用来标识要使用的 Istio 网格参数。

例如，要将对 `example.com` 的调用重定向到另外一个名为 `example` 的集群内的 `Service`:

The Gateway API can also be used to configure mesh traffic.
This is done by configuring the `parentRef`, to point to the `istio` `Mesh`.
This resource does not actually exist in the cluster and is only used to signal that the Istio mesh should be used.

For example, to redirect calls to `example.com` to an in-cluster `Service` named `example`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
metadata:
  name: mesh
spec:
  parentRefs:

  - kind: Mesh
    name: istio
    hostnames: ["example.com"]
    rules:
  - backendRefs:
    - name: example
      port: 80
      {{< /text >}}
