---
title: 控制 Ingress 流量
description: 介绍在服务网格 Istio 中如何配置外部公开服务。
weight: 30
keywords: [traffic-management,ingress]
---

在 Kubernetes 环境中，[Kubernetes Ingress 资源](https://kubernetes.io/docs/concepts/services-networking/ingress/) 用于指定应在集群外部公开的服务。在 Istio 服务网格中，更好的方法（也适用于 Kubernetes 和其他环境）是使用不同的配置模型，即 [Istio `Gateway`](/zh/docs/reference/config/istio.networking.v1alpha3/#gateway) 。 `Gateway` 允许将 Istio 功能（例如，监控和路由规则）应用于进入集群的流量。

此任务描述如何配置 Istio 以使用 Istio 在服务网格外部公开服务 `Gateway`。

## 前提条件

*   按照[安装指南中](/zh/docs/setup/)的说明设置 Istio 。

*   确保您当前的目录是 `istio` 目录。

{{< boilerplate start-httpbin-service >}}

*   按照以下小节中的说明确定 Ingress IP 和端口。

### 确定入口 IP 和端口

执行以下命令以确定您的 Kubernetes 集群是否在支持外部负载均衡器的环境中运行。

{{< text bash >}}
$ kubectl get svc istio-ingressgateway -n istio-system
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                      AGE
istio-ingressgateway   LoadBalancer   172.21.109.129   130.211.10.121  80:31380/TCP,443:31390/TCP,31400:31400/TCP   17h
{{< /text >}}

如果 `EXTERNAL-IP` 有值（IP 地址或主机名），则说明您的环境具有可用于 Ingress 网关的外部负载均衡器。如果 `EXTERNAL-IP` 值是 `<none>`（或一直是 `<pending>` ），则说明可能您的环境并没有为 Ingress 网关提供外部负载均衡器的功能。在这种情况下，您可以使用 Service 的 [node port](https://kubernetes.io/docs/concepts/services-networking/service/#nodeport) 方式访问网关。

#### 使用外部负载均衡器时确定 IP 和端口

如果您确定您的环境**具有**外部负载平衡器，请按照这些说明进行操作。

设置入口 IP 和端口：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
{{< /text >}}

{{< warning >}}
请注意，在某些环境中，外部负载均衡器可能需要使用主机名而不是 IP 地址。
在这种情况下，上一节命令输出中的 `EXTERNAL-IP` 的值就不是 IP 地址，
而是一个主机名，上面的命令将无法设置 `INGRESS_HOST` 环境变量。在这种情况下，使用以下命令来更正 `INGRESS_HOST` 值：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
{{< /text >}}

{{< /warning >}}

#### 确定使用 Node Port 时的 ingress IP 和端口

如果您确定您的环境**没有**外部负载均衡器，请按照这些说明操作。

确定端口：

{{< text bash >}}
$ export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
$ export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
{{< /text >}}

确定 ingress IP  的具体方法取决于集群提供商。

1.  _GKE：_

    {{< text bash >}}
    $ export INGRESS_HOST=<workerNodeAddress>
    {{< /text >}}

    您需要创建防火墙规则以允许 TCP 流量进入 _ingress gateway_ 服务的端口。运行以下命令以允许 HTTP 端口，安全端口（HTTPS）或两者的流量。

    {{< text bash >}}
    $ gcloud compute firewall-rules create allow-gateway-http --allow tcp:$INGRESS_PORT
    $ gcloud compute firewall-rules create allow-gateway-https --allow tcp:$SECURE_INGRESS_PORT
    {{< /text >}}

1.  _Minikube:_

    {{< text bash >}}
    $ export INGRESS_HOST=$(minikube ip)
    {{< /text >}}

1.  _Docker For Desktop:_

    {{< text bash >}}
    $ export INGRESS_HOST=127.0.0.1
    {{< /text >}}

1.  _其他环境（例如 IBM Cloud Private等）：_

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
    {{< /text >}}

## 使用 Istio 网关配置 Ingress

Ingress [`Gateway`](/zh/docs/reference/config/istio.networking.v1alpha3/#gateway) 描述了在网格边缘操作的负载平衡器，用于接收传入的 HTTP/TCP 连接。它配置暴露的端口、协议等，但与 [Kubernetes Ingress Resources](https://kubernetes.io/docs/concepts/services-networking/ingress/) 不同，它不包括任何流量路由配置。流入流量的流量路由使用 Istio 路由规则进行配置，与内部服务请求完全相同。

让我们看看如何为 `Gateway` 在 HTTP 80 端口上配置流量。

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

1.  为通过 `Gateway` 进入的流量配置路由：

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

    在这里，我们为服务创建了一个[虚拟服务](/zh/docs/reference/config/istio.networking.v1alpha3/#virtualservice)配置 `httpbin` ，其中包含两条路由规则，允许路径 `/status` 和 路径的流量 `/delay`。

    该[网关](/zh/docs/reference/config/istio.networking.v1alpha3/#virtualservice)列表指定，只有通过我们的要求 `httpbin-gateway` 是允许的。所有其他外部请求将被拒绝，并返回 404 响应。

    {{< warning >}}
    网格中其他服务的内部请求不受这些规则的约束，而是默认为循环路由。 要将这些规则应用于内部调用，您可以将特殊值 `mesh` 添加到 `gateways` 列表中。
    由于服务的内部主机名可能与外部主机名不同（例如，`httpbin.default.svc.cluster.local`），因此您还需要将其添加到 `hosts` 列表中。
    有关详细信息，请参阅[故障排除指南](/help/ops/traffic-management/troubleshooting/#route-rules-have-no-effect-on-ingress-gateway-requests)。
    {{< /warning >}}

1.  使用 curl 访问 httpbin 服务：

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

    请注意，这里使用该 `-H` 标志将 `Host` HTTP Header 设置为 “httpbin.example.com”。这一操作是必需的，因为上面的 Ingress `Gateway` 被配置为处理 “httpbin.example.com”，但在测试环境中没有该主机的 DNS 绑定，只是将请求发送到 Ingress IP。

1.  访问任何未明确公开的其他 URL，应该会看到一个 HTTP 404 错误：

    {{< text bash >}}
    $ curl -I -HHost:httpbin.example.com http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 404 Not Found
    date: Mon, 29 Jan 2018 04:45:49 GMT
    server: envoy
    content-length: 0
    {{< /text >}}

## 使用浏览器访问 Ingress 服务

在浏览器中输入 `httpbin` 服务的地址是不会生效的，这是因为因为我们没有办法让浏览器像 `curl` 一样装作访问 `httpbin.example.com`。而在现实世界中，因为有正常配置的主机和 DNS 记录，这种做法就能够成功了——只要简单的在浏览器中访问由域名构成的 URL 即可，例如 `https://httpbin.example.com/status/200`。

要解决此问题以进行简单的测试和演示，我们可以在 `Gateway` 和 `VirtualService` 配置中为主机使用通配符值 `*`。例如，如果我们将 Ingress 配置更改为以下内容：

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

接下来就可以在浏览器的 URL 中使用 `$INGRESS_HOST:$INGRESS_PORT`（也就是 `192.168.99.100:31380`）进行访问，输入 `http://192.168.99.100:31380/headers` 网址之后，应该会显示浏览器发送的请求 Header。

## 理解原理

`Gateway` 配置资源允许外部流量进入 Istio 服务网，并使 Istio 的流量管理和策略功能可用于边缘服务。

在前面的步骤中，我们在 Istio 服务网格中创建了一个服务，并展示了如何将服务的 HTTP 端点暴露给外部流量。

## 故障排除

1.  检查 `INGRESS_HOST` 和 `INGRESS_PORT` 环境变量的值。
    根据以下命令的输出，确保它们具有有效值：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo INGRESS_HOST=$INGRESS_HOST, INGRESS_PORT=$INGRESS_PORT
    {{< /text >}}

1.  检查在同一端口上是否没有定义其他 Istio ingress 网关：

    {{< text bash >}}
    $ kubectl get gateway --all-namespaces
    {{< /text >}}

1.  检查您是否在同一 IP 和端口上没有定义 Kubernetes Ingress 资源：

    {{< text bash >}}
    $ kubectl get ingress --all-namespaces
    {{< /text >}}

1.  如果您有外部负载平衡器并且它不适合您，请尝试使用服务的[节点端口](/docs/tasks/traffic-management/ingress/#determining-the-ingress-ip-and-ports-when-using-a-node-port)访问网关。

## 清理

删除 `Gateway` 和 `VirtualService`，并关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

{{< text bash >}}
$ kubectl delete gateway httpbin-gateway
$ kubectl delete virtualservice httpbin
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
