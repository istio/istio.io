---
title: 入口网关
description: 描述如何配置 Istio Gateway 对象，以将服务暴露至服务网格之外。
weight: 10
keywords: [traffic-management,ingress]
aliases:
    - /zh/docs/tasks/ingress.html
    - /zh/docs/tasks/ingress
owner: istio/wg-networking-maintainers
test: yes
---

除了支持 Kubernetes [Ingress](/zh/docs/tasks/traffic-management/ingress/kubernetes-ingress/)，
Istio还提供了另一种配置模式，[Istio Gateway](/zh/docs/reference/config/networking/gateway/)。
与 `Ingress` 相比，`Gateway` 提供了更广泛的自定义和灵活性，并允许将 Istio
功能（例如监控和路由规则）应用于进入集群的流量。

本任务描述了如何配置 Istio，以使用 Istio `Gateway` 来将服务暴露至服务网格之外。

## 开始之前{#before-you-begin}

*   遵照[安装指南](/zh/docs/setup/)中的文档说明，安装 Istio。

    {{< tip >}}
    如果准备使用 `Gateway API` 指令，您可以使用 `minimal` 配置文件来安装 Istio，
    因为您不再需要默认以其他方式安装的 `istio-ingressgateway`：

    {{< text bash >}}
    $ istioctl install --set profile=minimal
    {{< /text >}}

    {{< /tip >}}

*   启动 [httpbin]({{< github_tree >}}/samples/httpbin) 样例，用作入口流量的目标服务：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

    请注意本文旨在展示如何使用网关控制到“Kubernetes 集群”中的入口流量，
    无论是否启用 Sidecar 注入都可以启动 `httpbin` 服务（即目标服务可以在
    Istio 网格内，也可以在 Istio 网格外）。

## 使用网关配置 Ingress {#configuring-ingress-using-a-gateway}

Ingress `Gateway` 描述在网格边界运作的负载均衡器，用于接收传入的 HTTP/TCP 连接。
它会配置暴露的端口、协议等，但与 [Kubernetes Ingress 资源](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/)不同，不会包括任何流量路由配置。
转而使用路由规则来配置入口流量的流量路由，这与内部服务请求所用的方式相同。

现在看看如何为 HTTP 流量在 80 端口上配置 `Gateway`。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

创建 [Istio Gateway](/zh/docs/reference/config/networking/gateway/)：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
EOF
{{< /text >}}

通过 `Gateway` 为进入的流量配置路由：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

已为 `httpbin` 服务创建了[虚拟服务](/zh/docs/reference/config/networking/virtual-service/)配置，包含两个路由规则，允许流量流向路径 `/status` 和 `/delay`。

[Gateways](/zh/docs/reference/config/networking/virtual-service/#VirtualService-gateways) 列表指定了哪些请求允许通 `httpbin-gateway` 网关。
所有其他外部请求均被拒绝并返回 404 响应。

{{< warning >}}
来自网格内部其他服务的内部请求无需遵循这些规则，而是默认遵守轮询调度路由规则。
您可以为 `gateways` 列表添加特定的 `mesh` 值，将这些规则同时应用到内部请求。
由于服务的内部主机名可能与外部主机名不一致（譬如：`httpbin.default.svc.cluster.local`），
您需要同时将内部主机名添加到 `hosts` 列表中。
详情请参考[操作指南](/zh/docs/ops/common-problems/network-issues#route-rules-have-no-effect-on-ingress-gateway-requests)。
{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

创建 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway)：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: "httpbin.example.com"
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< tip >}}
在生产环境中，`Gateway` 及其对应的路由通常由具有不同角色的用户在独立的命名空间中进行创建。
这种情况下，将配置 `Gateway` 中的 `allowedRoutes` 字段以指定应创建路由的命名空间。
在此例中，预期这些路由应处于与 `Gateway` 相同的命名空间中。
{{< /tip >}}

因为创建 Kubernetes `Gateway` 资源也将[部署关联的代理服务](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)，
运行以下命令等待 Gateway 就绪：

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw httpbin-gateway
{{< /text >}}

通过 `Gateway` 为进入的流量配置路由：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

您现在已为 `httpbin` 服务创建了 [HTTP 路由](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.HTTPRoute)配置，
包含两个路由规则，允许流量流向路径 `/status` 和 `/delay`。

{{< /tab >}}

{{< /tabset >}}

### 确定 Ingress IP 和端口  {#determining-the-ingress-ip-and-ports}

每个 `Gateway` 由[类型为 LoadBalancer 的 Service](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/create-external-load-balancer/)支撑。
该 Service 的外部负载均衡器 IP 和端口用于访问 Gateway。
大多数云平台上运行的集群默认支持类型为 `LoadBalancer` 的 Kubernetes Service，
但在某些环境（例如测试环境）中，您可能需要执行如下操作：

* `minikube` - 在另一个终端中运行以下命令，启动一个外部负载均衡器：

    {{< text syntax=bash snip_id=minikube_tunnel >}}
    $ minikube tunnel
    {{< /text >}}

* `kind` - 遵循 [MetalLB 设置指南](https://kind.sigs.k8s.io/docs/user/loadbalancer/)使得类型为
   `LoadBalancer` 的服务能够工作。

* 其他平台 - 您可以使用 [MetalLB](https://metallb.universe.tf/installation/) 获取
  `EXTERNAL-IP` 用于 `LoadBalancer` 服务。

为了方便演示，我们将 Ingress IP 和端口存储到环境变量中，在后续的教程中使用。
根据以下指示设置 `INGRESS_HOST` 和 `INGRESS_PORT` 环境变量：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

将以下环境变量设置到您集群中 Istio Ingress Gateway 所用的名称及其所在的命名空间：

{{< text bash >}}
$ export INGRESS_NAME=istio-ingressgateway
$ export INGRESS_NS=istio-system
{{< /text >}}

{{< tip >}}
如果您使用 Helm 安装 Istio，则 Ingress Gateway 名称和命名空间都是 `istio-ingress`：

{{< text bash >}}
$ export INGRESS_NAME=istio-ingress
$ export INGRESS_NS=istio-ingress
{{< /text >}}

{{< /tip >}}

执行如下指令，确定您的 Kubernetes 集群是否运行在支持外部负载均衡器的环境中：

{{< text bash >}}
$ kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)   AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121   ...       17h
{{< /text >}}

如果 `EXTERNAL-IP` 值已设置，说明环境正在使用外部负载均衡器，可以用其为 Ingress Gateway 提供服务。
如果 `EXTERNAL-IP` 值为 `<none>` （或持续显示 `<pending>`），说明环境没有为 Ingress Gateway
提供外部负载均衡器，无法使用 Ingress Gateway。

如果您的环境不支持外部负载均衡器，您可以尝试[使用 Node Port 访问 Ingress Gateway](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)。
否则，使用以下命令设置 Ingress IP 和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
$ export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')
{{< /text >}}

{{< warning >}}
在特定的环境下，可能会使用主机名来暴露负载均衡器，而不是 IP 地址。
此时，Ingress Gateway 的 `EXTERNAL-IP` 值将不再是 IP 地址，而是主机名。
前文设置 `INGRESS_HOST` 环境变量的命令将执行失败。使用下面的命令更正 `INGRESS_HOST` 值：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

从 httpbin 网关资源获取网关地址和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< tip >}}
您可以使用类似的命令找到任何网关上的其他端口。
例如在名为 `my-gateway` 的网关上访问名为 `https` 的安全 HTTP 端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw my-gateway -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw my-gateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

## 访问 Ingress 服务  {#accessing-ingress-services}

1. 使用 **curl** 访问 **httpbin** 服务：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    注意上文命令使用 `-H` 标识将 HTTP 头部参数 **Host** 设置为 "httpbin.example.com"。
    该操作是必需的，因为 Ingress `Gateway` 已被配置用来处理 "httpbin.example.com" 的服务请求，
    而在测试环境中并没有为该主机绑定 DNS，而是简单直接地向 Ingress IP 发送请求。

1. 访问其他没有被显式暴露的 URL 时，将看到 HTTP 404 错误：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## 通过浏览器访问 Ingress 服务  {#accessing-ingress-services-using-a-browser}

在浏览器中输入 `httpbin` 服务的 URL 不能获得有效的响应，因为无法像 `curl` 那样，
将请求头部参数 **Host** 传给浏览器。在现实场景中，这并不是问题，
因为您需要合理配置被请求的主机及可解析的 DNS，从而在 URL 中使用主机的域名，
例如 `https://httpbin.example.com/status/200`。

您可以在简单的测试和演示中按下述方法绕过这个问题：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

在 `Gateway` 和 `VirtualService` 配置中使用通配符 `*`。例如如下修改 Ingress 配置：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # 使用 Istio 默认网关实现
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "*"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /headers
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

如果您从 `Gateway` 和 `HTTPRoute` 配置中移除主机名，则将应用到任何请求。
例如，如下修改 Ingress 配置：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: httpbin-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /headers
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

此时，便可以在浏览器中输入包含 `$INGRESS_HOST:$INGRESS_PORT` 的 URL。
譬如，输入 `http://$INGRESS_HOST:$INGRESS_PORT/headers`，将显示浏览器发送的所有 Header 信息。

## 理解原理  {#understanding-what-happened}

`Gateway` 配置资源允许外部流量进入 Istio 服务网格，并对边界服务实施流量管理和 Istio 可用的策略特性。

在前面的步骤中，在服务网格中创建一个服务并向外部流量暴露该服务的 HTTP 端点。

## 使用 Ingress Gateway 服务的 Node Port {#using-node-ports-of-the-ingress-gateway-service}

{{< warning >}}
如果您的 Kubernetes 环境有支持[类型为 LoadBalancer 的 Service](https://kubernetes.io/zh-cn/docs/tasks/access-application-cluster/create-external-load-balancer/)的外部负载均衡器，
您无需使用这些指示步骤。
{{< /warning >}}

如果您的环境不支持外部负载均衡器，则您仍然可以使用 `istio-ingressgateway`
Service 的 [Node Port](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)来实验某些 Istio 特性。

设置 Ingress 端口：

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
$ export TCP_INGRESS_PORT=$(kubectl -n "${INGRESS_NS}" get service "${INGRESS_NAME}" -o jsonpath='{.spec.ports[?(@.name=="tcp")].nodePort}')
{{< /text >}}

根据集群提供商来设置 Ingress IP：

1.  **GKE：**

    {{< text bash >}}
    $ export INGRESS_HOST=worker-node-address
    {{< /text >}}

    您需要创建防火墙规则以允许 TCP 流量到达 **ingressgateway** Service 的端口。
    运行以下命令以允许到 HTTP 和/或 HTTPS 端口的流量：

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow "tcp:$INGRESS_PORT"
    $ gcloud compute firewall-rules create allow-gateway-https --allow "tcp:$SECURE_INGRESS_PORT"
    {{< /text >}}

1.  **IBM Cloud Kubernetes Service：**

    {{< text bash >}}
    $ ibmcloud ks workers --cluster cluster-name-or-id
    $ export INGRESS_HOST=public-IP-of-one-of-the-worker-nodes
    {{< /text >}}

1.  **Docker For Desktop：**

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  **其他环境：**

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n "${INGRESS_NS}" -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

## 问题排查  {#troubleshooting}

1. 检查环境变量 `INGRESS_HOST` and `INGRESS_PORT`。确保环境变量的值有效，命令如下：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT"
    {{< /text >}}

1. 检查没有在相同的端口上定义其它 Istio Ingress Gateway：

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1. 检查没有在相同的 IP 和端口上定义 Kubernetes Ingress 资源：

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1. 如果使用了外部负载均衡器，但该外部负载均衡器无法正常工作，
   可尝试[通过 Node Port 访问 Gateway](#using-node-ports-of-the-ingress-gateway-service)。

## 清除  {#cleanup}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

删除 `Gateway` 和 `VirtualService` 配置，并关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

删除 `Gateway` 和 `HTTPRoute` 配置，并关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

{{< text bash >}}
$ kubectl delete gtw httpbin-gateway
$ kubectl delete httproute httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}
