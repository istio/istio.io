---
title: Ingress Gateways
description: 描述如何配置一个 Istio gateway，以将服务暴露至服务网格之外。
weight: 10
keywords: [traffic-management,ingress]
aliases:
    - /zh/docs/tasks/ingress.html
    - /zh/docs/tasks/ingress
---

在 Kubernetes 环境中，使用 [Kubernetes Ingress 资源](https://kubernetes.io/docs/concepts/services-networking/ingress/) 来指定需要暴露到集群外的服务。
在 Istio 服务网格中，一个更好的选择（同样适用于 Kubernetes 及其他环境）是使用一种新的配置模型，名为 [Istio Gateway](/zh/docs/reference/config/networking/gateway/)。
`Gateway` 允许应用一些诸如监控和路由规则的 Istio 特性来管理进入集群的流量。

本任务描述了如何配置 Istio，以使用 Istio `Gateway` 来将服务暴露至服务网格之外。

## 开始之前{#before-you-begin}

*   遵照[安装指南](/zh/docs/setup/)中的指令，安装 Istio。

*   确定当前目录路径为 `istio` 目录。

{{< boilerplate start-httpbin-service >}}

*   根据下文描述，确定 ingress IP 和端口。

### 确定 ingress IP 和端口{#determining-the-ingress-i-p-and-ports}

执行如下指令，明确自身 Kubernetes 集群环境支持外部负载均衡：

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

如果 `EXTERNAL-IP` 值已设置，说明环境正在使用一个外部负载均衡，可以用其为 ingress gateway 提供服务。
如果 `EXTERNAL-IP` 值为 `<none>` （或持续显示 `<pending>`）， 说明环境没有提供外部负载均衡，无法使用 ingress gateway。
在这种情况下，你可以使用服务的 [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport) 访问网关。

选择符合自身环境的指令执行：

{{< tabset cookie-name="gateway-ip" >}}

{{< tab name="external load balancer" cookie-value="external-lb" >}}

若已确定自身环境使用了外部负载均衡器，执行如下指令。

设置 ingress IP 和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
在特定的环境下，可能会使用主机名指代负载均衡器，而不是 IP 地址。
此时，ingress 网关的 `EXTERNAL-IP` 值将不再是一个 IP 地址，而是一个主机名。前文设置 `INGRESS_HOST` 环境变量的命令将执行失败。
使用下面的命令更正 `INGRESS_HOST` 值：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

{{< /tab >}}

{{< tab name="node port" cookie-value="node-port" >}}

若自身环境未使用外部负载均衡器，需要通过 node port 访问。执行如下命令。

设置 ingress 端口：

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

基于集群供应商，设置 ingress IP：

1.  _GKE：_

    {{< text bash >}}
    $ export INGRESS_HOST=<workerNodeAddress>
    {{< /text >}}

    需要创建防火墙规则，允许 TCP 流量通过 _ingressgateway_ 服务的端口。
    执行下面的命令，设置允许流量通过 HTTP 端口、HTTPS 安全端口，或均可：

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow tcp:$INGRESS_PORT
    $ gcloud compute firewall-rules create allow-gateway-https --allow tcp:$SECURE_INGRESS_PORT
    {{< /text >}}

1.  _Minikube：_

    {{< text bash >}}
    $ export INGRESS_HOST=$(minikube ip)
    {{< /text >}}

1.  _Docker For Desktop：_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _其他环境（如：IBM Cloud Private 等）：_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 使用一个 Istio Gateway 配置 ingress{#configuring-ingress-using-an-mesh-gateway}

一个 ingress [Gateway](/zh/docs/reference/config/networking/gateway/) 描述一个运行在网格边界的负载均衡器，负责接收入口 HTTP/TCP 连接。
其中配置了对外暴露的端口、协议等。
但是，不像 [Kubernetes Ingress 资源](https://kubernetes.io/docs/concepts/services-networking/ingress/)，ingress Gateway 不包含任何流量路由配置。Ingress 流量的路由使用 Istio 路由规则来配置，和内部服务请求完全一样。

让我们一起来看如何为 HTTP 流量在80端口上配置一个 `Gateway`。

1.  创建一个 Istio `Gateway`：

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

1.  为通过 `Gateway` 的入口流量配置路由：

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

    已为 `httpbin` 服务创建了一个[虚拟服务](/zh/docs/reference/config/networking/virtual-service/) 配置，包含两个路由规则，允许流量流向路径 `/status` 和 `/delay`。

    [gateways](/zh/docs/reference/config/networking/virtual-service/#VirtualService-gateways) 列表规约了哪些请求允许通过 `httpbin-gateway` 网关。
    所有其他外部请求均被拒绝并返回一个 404 响应。

    {{< warning >}}
    来自网格内部其他服务的内部请求无需遵循这些规则，而是默认遵守轮询调度路由规则。
    你可以为 `gateways` 列表添加特定的 `mesh` 值，将这些规则同时应用到内部请求。
    由于服务的内部主机名可能与外部主机名不一致（譬如： `httpbin.default.svc.cluster.local`），你需要同时将内部主机名添加到 `hosts` 列表中。
    详情请参考 [操作指南](/zh/docs/ops/common-problems/network-issues#route-rules-have-no-effect-on-ingress-gateway-requests)。
    {{< /warning >}}

1.  使用 _curl_ 访问 _httpbin_ 服务：

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/status/200
    HTTP/1.1 200 OK
    server: envoy
    date: Mon, 29 Jan 2018 04:45:49 GMT
    content-type: text/html; charset=utf-8
    access-control-allow-origin: *
    access-control-allow-credentials: true
    content-length: 0
    x-envoy-upstream-service-time: 48
    {{< /text >}}

    注意上文命令使用 `-H` 标识将 HTTP头部参数 _Host_ 设置为 "httpbin.example.com"。
    该操作为必须操作，因为 ingress `Gateway` 已被配置用来处理 "httpbin.example.com" 的服务请求，而在测试环境中并没有为该主机绑定 DNS 而是简单直接地向 ingress IP 发送请求。

1.  访问其他没有被显式暴露的 URL 时，将看到一个 HTTP 404 错误：

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    {{< /text >}}

## 通过浏览器访问 ingress 服务{#accessing-ingress-services-using-a-browser}

在浏览器中输入 `httpbin` 服务的URL 不能获得有效的响应，因为无法像 `curl` 那样，将请求头部参数 _Host_ 传给浏览器。在现实场景中，这并不是一个问题，因为你需要合理配置被请求的主机及可解析的 DNS，从而在 URL 中使用主机的域名，譬如： `https://httpbin.example.com/status/200`。

为了在简单的测试和演示中绕过这个问题，请在 `Gateway` 和 `VirtualService` 配置中使用通配符 `*`。譬如，修改 ingress 配置如下：

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

此时，便可以在浏览器中输入包含 `$INGRESS_HOST:$INGRESS_PORT` 的URL。譬如，输入`http://$INGRESS_HOST:$INGRESS_PORT/headers`，将显示浏览器发送的所有 headers 信息。

## 理解原理{#understanding-what-happened}

`Gateway` 配置资源允许外部流量进入 Istio 服务网格，并对边界服务实施流量管理和 Istio 可用的策略特性。

事先，在服务网格中创建一个服务并向外部流量暴露该服务的一个 HTTP 端点。

## 问题排查{#troubleshooting}

1.  检查环境变量 `INGRESS_HOST` and `INGRESS_PORT`。确保环境变量的值有效，命令如下：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT
    {{< /text >}}

1.  检查没有在相同的端口上定义其它 Istio ingress gateways：

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1.  检查没有在相同的 IP 和端口上定义 Kubernetes Ingress 资源：

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1.  如果使用了外部负载均衡器，该外部负载均衡器无法正常工作，尝试[通过 node port 访问 gateway](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)。

## 清除{#cleanup}

删除 `Gateway` 和 `VirtualService` 配置， 并关闭服务 [httpbin]({{< github_tree >}}/samples/httpbin)：

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
