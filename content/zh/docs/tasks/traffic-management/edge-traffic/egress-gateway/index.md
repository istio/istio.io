---
title: 配置 Egress gateway
description: 描述如何通过专用网关服务将流量定向到外部服务来配置 Istio。
weight: 43
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway/
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务演示了如何从网格内的应用程序访问外部（Kubernetes 集群外部）HTTP 和 HTTPS 服务。这里提醒一下：默认情况下，启用 Istio 的应用程序无法访问集群外的 URL。要启用此类访问，必须定义外部服务的 [`ServiceEntry`](/zh/docs/reference/config/istio.networking.v1alpha3/#serviceentry)，或者配置[直接访问外部服务](/zh/docs/tasks/traffic-management/egress/#直接调用外部服务)。

[Egress 流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 任务演示了如何允许应用程序将 HTTP 请求发送到需要 HTTPS 的外部服务器。

此任务描述了通过名为 `Egress Gateway`  的专用服务如何配置 Istio 引导出口流量。我们实现了与 [Egress 流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 任务中描述的相同功能，唯一的区别就是，这里会使用 Egress gateway 来完成这一任务。

## 用例

设想一个具有严格安全要求的组织。根据这些要求，服务网格的所有外发流量必须流经一组专用节点。这些节点和运行其他应用分别在不同的节点上运行。这些专用的节点将用于 Egress 流量的策略实施，并且将比其余节点进行更详细地监控。

Istio 0.8 引入了 [Ingress 和 Egress gateway](/zh/docs/reference/config/istio.networking.v1alpha3/#gateway) 的概念。 Ingress 网关允许定义进入服务网格的入口点，所有入站流量都通过该入口点；`Egress gateway` 与之相对，它定义了网格的出口点。 Egress gateway 允许将 Istio 功能（例如，监控和路由规则）应用于 Egress 流量。

另一个用例是应用程序节点没有公共 IP 的集群，因此在其上运行的网格内服务无法访问 Internet。定义 Egress gateway ，通过它引导所有出口流量并将公共 IP 分配给 Egress gateway 节点，允许应用节点以受控方式访问外部服务。

## 开始之前

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

* 启动 [sleep]({{<github_tree>}}/samples/sleep) 应用，它将被用作外部调用的测试源。

    如果已经启用了 [Sidecar 的自动注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入)，请执行此操作

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，就要在部署 `sleep` 应用程序之前手工进行 Sidecar 的注入：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    这样就可以在任意 pod 使用 `exec` 和 `curl` 命令了。

* 创建一个环境变量来保存源 Pod 名称，以便将请求发送到外部服务。例如在 [sleep]({{<github_tree>}}/samples/sleep) 示例中运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 定义 Egress gateway 并引导 HTTP 流量通过这一网关

首先定向没有 TLS 的 HTTP 流量

1. 为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

1. 验证 `ServiceEntry` 是否已正确应用。发送 HTTPS 请求到 [http://edition.cnn.com/politics](http://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    输出应与 [Egress 流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 任务中的输出相同，不带 TLS。

1. 为 `edition.cnn.com` 端口 80 创建 Egress gateway。除此之外还要创建一个 `DestinationRule` 和 `VirtualService` 来引导流量通过 Egress gateway 与外部服务通信。

    如果在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，请使用以下命令。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 80
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 80
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text >}}

    如果没有启用双向 TLS 认证：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1. 定义 `VirtualService` 来引导流量通过 Egress gateway ：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 80
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 80
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 80
          weight: 100
    EOF
    {{< /text >}}

1. 将 HTTP 请求重新发送到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    输出应与步骤2中的输出相同。

1. 检查  `istio-egressgateway` pod 的日志，并查看与我们的请求对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    我们看到与请求相关的行，类似于以下内容：

    {{< text plain >}}
    [2018-06-14T11:46:23.596Z] "GET /politics HTTP/1.1" 301 - 0 0 3 1 "172.30.146.87" "curl/7.35.0" "ab7be694-e367-94c5-83d1-086eca996dae" "edition.cnn.com" "151.101.193.67:80"
    {{< /text >}}

    请注意，我们只将流量从 80 端口重定向到 Egress gateway ，到 443 端口的 HTTPS 流量直接转到 `edition.cnn.com` 。

### 清除 HTTP 流量的 Egress gateway

在继续下一步之前删除先前的定义：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 用 Egress gateway 发起 TLS 连接

接下来尝试使用 Egress Gateway 发起 TLS 连接，效果类似于 [出口流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 任务，具体区别是，在这种情况下，TLS 功能是由 Egress gateway 服务器完成的，而不是前一任务中的 Sidecar。

1. 为 `edition.cnn.com` 定义 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: http-port-for-tls-origination
        protocol: HTTP
      resolution: DNS
    EOF
    {{< /text >}}

1. 验证您的 `ServiceEntry` 是否已正确生效。发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    如果看到输出结果中包含 `301 Moved Permanently`，说明 `ServiceEntry` 配置正确。退出代码 `35` 是由于 Istio 没有执行 TLS。 为了让 Egress gateway 执行 TLS，还要继续执行以下步骤进行配置。

1. 为 `edition.cnn.com` 创建 Egress Gateway，端口 443。除此之外还创建了一个 `DestinationRule` 和 `VirtualService`，这两个对象用来引导流量通过 Egress gateway 与外部服务通信。

    如果在 Istio 中启用了 [双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，请使用以下命令。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    EOF
    {{< /text >}}

    如果没有启用双向 TLS 认证：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: http-port-for-tls-origination
          protocol: HTTP
        hosts:
        - edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    EOF
    {{< /text >}}

1. 定义 `VirtualService` 来引导流量通过 Egress gateway，并定义 `DestinationRule` 以执行 TLS：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
      http:
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
          weight: 100
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
    EOF
    {{< /text >}}

1. 发送 HTTP 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    {{< /text >}}

    输出应与 [出口流量的 TLS](/zh/docs/tasks/traffic-management/edge-traffic/egress-tls-origination/) 任务中的输出相同：没有 `301 Moved Permanently` 信息。

1. 检查 `istio-egressgateway` pod 的日志，并查看与我们的请求相对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
    {{< /text >}}

    这里会看到与之前请求相关的行，类似于以下内容：

    {{< text plain>}}
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    {{< /text >}}

### 清除发起 TLS 的 Egress gateway

删除我们创建的 Istio 配置项：

{{< text bash >}}
$ kubectl delete gateway istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 通过 Egress gateway 进行 HTTPS 流量透传

在本节中，将通过 Egress gateway 进行 HTTPS 流量透传（由应用程序发起的 TLS）。在相应的 `ServiceEntry`、`Egress gateway` 以及 `VirtualService` 中指定端口 443，协议 `TLS`。

1. 为 `edition.cnn.com` 定义 `ServiceEntry`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1. 验证 `ServiceEntry` 是否已正确生效。发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出应与上一节中的输出相同。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1. 为 `edition.cnn.com` 创建 Egress gateway，端口 443，TLS 协议。除此之外还创建了一个 `DestinationRule` 和 `VirtualService` 来引导流量通过 Egress gateway 与外部服务通信。

    如果在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，请使用以下命令。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls-cnn
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
        trafficPolicy:
          loadBalancer:
            simple: ROUND_ROBIN
          portLevelSettings:
          - port:
              number: 443
            tls:
              mode: ISTIO_MUTUAL
              sni: edition.cnn.com
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
      tcp:
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

    如果没有启用双向 TLS 认证:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway
    spec:
      selector:
        istio: egressgateway
      servers:
      - port:
          number: 443
          name: tls
          protocol: TLS
        hosts:
        - edition.cnn.com
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-cnn
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
      - name: cnn
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-cnn-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - mesh
      - istio-egressgateway
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: istio-egressgateway.istio-system.svc.cluster.local
            subset: cnn
            port:
              number: 443
      - match:
        - gateways:
          - istio-egressgateway
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出应与之前相同。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1. 检查 Egress gateway 代理的统计信息，并查看与我们对 `edition.cnn.com` 的请求相对应的计数器。如果 Istio 部署在 `istio-system` 命名空间中，则打印计数器的命令是：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 1
    {{< /text >}}

    如果再执行几个额外的请求，应该会看到每次请求之后上面的计数器都会加 1。

### 清除 HTTPS 流量的 Egress gateway

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

## 额外的安全考量

在 Istio 中定义的 Egress gateway，本身并不会对运行 Egress gateway 服务的节点进行任何特殊处理。集群管理员或云提供商可以在专用节点上部署 Egress gateway ，并引入额外的安全措施，使这些节点比网格的其余部分更安全。

另外要注意的是，实际上 Istio 本身无法安全地强制将所有 Egress 流量流经 Egress gateway ，Istio 仅通过其 Sidecar 代理启用此类流量。攻击者只要绕过 Sidecar 代理，就可以不经 Egress gateway 直接与网格外面的服务进行通信，从而避免了 Istio 的控制和监控。集群管理员或云供应商必须确保所有外发流量都从 Egress gateway 途径发起。需要用 Istio 之外的机制来满足这一需求，例如以下几种做法：

* 使用防火墙拒绝所有来自 Egress gateway 以外的流量。
* [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)也能禁止所有不是从 Egress gateway 发起的 Egress 流量（[#下一节](#应用-kubernetes-网络策略)中举出了这样的例子）。
* 管理员或者云供应商还可以对网络进行限制，让运行应用的节点只能通过 Gateway 来访问外部网络。要完成这一限制，可以只给 Gateway Pod 分配公网 IP，或者可以配置 NAT 设备，丢弃来自 Egress gateway 以外 Pod 的流量。

## 应用 Kubernetes 网络策略

本节中会创建 [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)，阻止绕过 Egress gateway 的外发流量。要完成这一示例，首先创建一个 `test-egress` 命名空间，并在其中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用。

1. 重复执行[“通过 Egress gateway 进行 HTTPS 流量透传”](#通过-egress-gateway-进行-https-流量透传)一节的内容。

1. 创建 `test-egress` 命名空间：

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

1. 在 `test-egress` 命名空间中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用：

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 检查生成的 Pod，其中应该只有一个容器，也就是说没有注入 Istio sidecar：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

1. 从 `test-egress` 命名空间的 `sleep` Pod 中向 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)  发送 HTTPS 请求。因为没有任何限制，所以这一请求应该会成功：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

1. 给 Istio 组件（控制平面和 Gateway）所在的命名空间打上标签，例如 `istio-system`：

    {{< text bash >}}
    $ kubectl label namespace istio-system istio=system
    {{< /text >}}

1. 给 `kube-system` 命名空间打标签：

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

1. 创建一个 `NetworkPolicy`，来自 `test-egress` 命名空间的流量，只允许目标为 `kube-system` 的 DNS（端口 53）请求，以及目标为 `istio-system` 命名空间的所有请求：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n test-egress -f -
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-egress-to-istio-system-and-kube-dns
    spec:
      podSelector: {}
      policyTypes:
      - Egress
      egress:
      - to:
        - namespaceSelector:
            matchLabels:
              kube-system: "true"
        ports:
        - protocol: UDP
          port: 53
      - to:
        - namespaceSelector:
            matchLabels:
              istio: system
    EOF
    {{< /text >}}

1. 重新发送前面的 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。这次请求就不会成功了，这是因为流量被网络策略拦截了。测试 Pod 无法越过 `istio-egressgateway`。要访问 `edition.cnn.com`，只能通过 Istio sidecar 将流量转给 `istio-egressgateway` 才能完成。这一设置演示了即使绕过了 Sidecar，也会被网络策略拦截，而无法访问到外部站点。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -v https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

1. 接下来在 `test-egress` 命名空间的 `sleep` Pod 上注入 Sidecar，启用 `test-egress` 命名空间的自动注入：

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

1. 重新部署 `sleep`：

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

1. 检查生成的 Pod，其中应该有了两个容器，其中包含了注入的 Sidecar（`istio-proxy`）：

    {{< text bash >}}
    $ kubectl get pod $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -o jsonpath={.spec.containers[*].name}
    sleep istio-proxy
    {{< /text >}}

1. 向 [http://edition.cnn.com/politics](https://edition.cnn.com/politics) 发送 HTTP 请求，这次会成功，原因是网络策略允许流量流向 `istio-system` 中的 `istio-egressgateway`，`istio-egressgateway` 最终把流量转发到 `edition.cnn.com`。

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name}) -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

1. 检查 Egress gateway 中的代理统计数据，查看对 `edition.cnn.com` 的请求计数。如果 Istio 部署在 `istio-system` 命名空间，那么打印计数器的命令就是：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

### 清理网络策略

1. 删除本节中建立的资源：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
    $ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
    $ kubectl label namespace kube-system kube-system-
    $ kubectl label namespace istio-system istio-
    $ kubectl delete namespace test-egress
    {{< /text >}}

1. 执行[“通过 Egress gateway 进行 HTTPS 流量透传”](#通过-egress-gateway-进行-https-流量透传)一节中的[清理工作](#清除-https-流量的-egress-gateway)。

## 故障排除

1. 检查是否在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，然后执行以下步骤：[验证 Istio 的双向 TLS 认证设置](/zh/docs/tasks/security/mutual-tls/#检查-istio-双向-tls-认证的配置)。如果启用了双向 TLS，请确保创建相应的项目配置（请注意备注**如果您在 Istio 中启用了双向 TLS 认证，则必须创建...**）。

1. 如果[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)启用后, 验证 Egress gateway 的证书：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
    {{< /text >}}

1. HTTPS 透传流量情况，需要使用 `openssl` 命令测试流量。`openssl` 的 `-servername` 选项可以用来设置 SNI：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- openssl s_client -connect edition.cnn.com:443 -servername edition.cnn.com
    CONNECTED(00000003)
    ...
    Certificate chain
     0 s:/C=US/ST=California/L=San Francisco/O=Fastly, Inc./CN=turner-tls.map.fastly.net
       i:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
     1 s:/C=BE/O=GlobalSign nv-sa/CN=GlobalSign CloudSSL CA - SHA256 - G3
       i:/C=BE/O=GlobalSign nv-sa/OU=Root CA/CN=GlobalSign Root CA
     ---
     Server certificate
     -----BEGIN CERTIFICATE-----
    ...
    {{< /text >}}

    如果在上面命令的输出中看到了类似的证书信息，就表明路由是正确的。接下来检查 Egress gateway 代理，查找对应请求的计数器（由 `openssl` 和 `curl` 发送，目标是 `edition.cnn.com`）：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 2
    {{< /text >}}

## 清理

关闭 [sleep]({{<github_tree>}}/samples/sleep) 服务:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
