---
title: 配置 Egress 网关
description: 描述如何通过专用网关服务将流量定向到外部服务来配置 Istio 。
weight: 43
keywords: [traffic-management,egress]
---

> 此任务使用新的 [v1alpha3 流量管理 API](/zh/blog/2018/v1alpha3-routing/) 。旧的 API 已被弃用并将在下一个 Istio 版本中删除。如果您需要使用旧版本，请按照[此处](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)的文档操作。请注意，此任务引入了一个新概念，即 Egress 网关，这在以前的 Istio 版本中是不存在的。

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务演示了如何从网格内的应用程序访问外部（Kubernetes 集群外部）HTTP 和 HTTPS 服务。快速提醒：默认情况下，启用 Istio 的应用程序无法访问群集外的 URL。要启用此类访问，必须定义外部服务的[服务条目](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry)，或者[直接访问外部服务](/docs/tasks/traffic-management/egress/#calling-external-services-directly)。

[Egress 流量的 TLS](/zh/docs/tasks/traffic-management/egress-tls-origination/) 任务演示了如何允许应用程序将 HTTP 请求发送到需要 HTTPS 的外部服务器。

此任务描述了通过名为  _Egress Gateway_  的专用服务如何配置 Istio 引导出口流量。我们实现了与 [Egress 流量的 TLS](/zh/docs/tasks/traffic-management/egress-tls-origination/) 任务中描述的相同功能，这次我们通过添加 egress 网关来完成它。

## 用例

考虑一个具有严格安全要求的组织。根据这些要求，离​​开服务网格的所有流量必须流经一组专用节点。这些节点将在专用计算机上运行，​​与用于在群集中运行应用程序的其余节点分开运行。特殊节点将用于 egress 流量的策略实施，并且将比其余节点进行更详细地监控。

Istio 0.8 引入了 [ingress 和 egress 网关](/docs/reference/config/istio.networking.v1alpha3/#Gateway)的概念。 Ingress 网关允许定义进入服务网格的入口点，所有入站流量都通过该入口点。 _Egress gateway_  是一个对称的概念，它定义了网格的出口点。 Egress 网关允许将 Istio 功能（例如，监控和路由规则）应用于离开网格的流量。

另一个用例是应用程序节点没有公共 IP 的集群，因此在其上运行的网格内服务无法访问 Internet。定义 egress 网关，通过它引导所有出口流量并将公共 IP 分配给 egress 网关节点，允许应用节点以受控方式访问外部服务。

## 开始之前

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

*   启动 [sleep]({{<github_tree>}}/samples/sleep)，它将被用作外部调用的测试源。

    如果您已经启用了 [automatic sidecar injection](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)，请执行此操作

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，您必须在部署 `sleep` 应用程序之前手动注入 sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    请注意，您可以在任意 pod 使用 `exec` 和 `curl`。

*   创建一个 shell 变量来保存源 pod 的名称，以便将请求发送到外部服务。如果我们使用 [sleep]({{<github_tree>}}/samples/sleep) 示例，我们运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 定义 egress `Gateway` 并通过它定向 HTTP 流量

首先定向没有 TLS 的 HTTP 流量

1.  为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

1.  验证您的 `ServiceEntry` 是否已正确应用。发送 HTTPS 请求到 [http://edition.cnn.com/politics](http://edition.cnn.com/politics)。

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

    输出应与 [Egress 流量的 TLS](/zh/docs/tasks/traffic-management/egress-tls-origination/) 任务中的输出相同，不带 TLS。

1.  创建 egress `Gateway` 为 _edition.cnn.com_ ，端口 80。

    如果在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，请使用以下命令。请注意，除了创建 `Gateway` 之外，它还创建了一个 `DestinationRule` 来指定 egress 网关的 mTLS，将 SNI 设置为 `edition.cnn.com`。

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 80
          tls:
            mode: MUTUAL
            clientCertificate: /etc/certs/cert-chain.pem
            privateKey: /etc/certs/key.pem
            caCertificates: /etc/certs/root-cert.pem
            subjectAltNames:
            - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
            sni: edition.cnn.com
    EOF
    {{< /text >}}

    除此之外：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
    EOF
    {{< /text >}}

1.  定义 `VirtualService` 来引导流量通过 egress 网关：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-through-egress-gateway
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

1.  将 HTTP 请求重新发送到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

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

1.  检查  _istio-egressgateway_ pod 的日志，并查看与我们的请求对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    {{< /text >}}

    我们看到与请求相关的行，类似于以下内容：

    {{< text plain >}}
    [2018-06-14T11:46:23.596Z] "GET /politics HTTP/1.1" 301 - 0 0 3 1 "172.30.146.87" "curl/7.35.0" "ab7be694-e367-94c5-83d1-086eca996dae" "edition.cnn.com" "151.101.193.67:80"
    {{< /text >}}

    请注意，我们只将流量从 80 端口重定向到 egress 网关，到 443 端口的 HTTPS 流量直接转到  _edition.cnn.com_ 。

### 清除 HTTP 流量的 egress 网关

在继续下一步之前删除先前的定义：

{{< text bash >}}
$ istioctl delete gateway istio-egressgateway
$ istioctl delete serviceentry cnn
$ istioctl delete virtualservice direct-through-egress-gateway
$ istioctl delete destinationrule set-sni-for-egress-gateway
{{< /text >}}

## Egress `Gateway` 执行 TLS

让我们用 egress `Gateway` 执行 TLS，类似于 [TLS Origination for Egress Traffic](/zh/docs/tasks/traffic-management/egress-tls-origination/) 任务。请注意，在这种情况下，TLS 将由 egress 网关服务器完成，而不是前一任务中的 sidecar。

1.  为 `edition.cnn.com` 定义 `ServiceEntry`：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

1.  验证您的 `ServiceEntry` 是否已正确应用。发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    command terminated with exit code 35
    {{< /text >}}

    输出应该包含  _301 Moved Permanently_ ，如果您看到它，证明 `ServiceEntry` 配置正确。退出代码 _35_ 是由于 Istio 没有执行 TLS。 Egress 网关将执行 TLS，继续执行以下步骤进行配置。

1.  为  _edition.cnn.com_  创建 egress `Gateway`，端口 443。

    如果在 Istio 中启用了 [双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/) ，请使用以下命令。请注意，除了创建 `Gateway` 之外，它还创建了一个 `DestinationRule` 来指定 egress 网关的 mTLS，将 SNI 设置为 `edition.cnn.com`。

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: MUTUAL
            clientCertificate: /etc/certs/cert-chain.pem
            privateKey: /etc/certs/key.pem
            caCertificates: /etc/certs/root-cert.pem
            subjectAltNames:
            - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
            sni: edition.cnn.com
    EOF
    {{< /text >}}

    除此之外：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
    EOF
    {{< /text >}}

1.  定义 `VirtualService` 来引导流量通过 egress 网关，并定义 `DestinationRule` 以执行 TLS：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-through-egress-gateway
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

1.  发送 HTTP 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    content-length: 150793
    ...
    {{< /text >}}

    输出应与 [TLS Origination for Egress Traffic](/zh/docs/tasks/traffic-management/egress-tls-origination/) 任务中的输出相同，TLS 来源：没有  _301 Moved Permanently_ 信息。

1.  检查  _istio-egressgateway_ pod 的日志，并查看与我们的请求相对应的行。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') egressgateway -n istio-system | tail
    {{< /text >}}

    我们看到与我们的请求相关的行，类似于以下内容：

    {{< text plain>}}
    "[2018-06-14T13:49:36.340Z] "GET /politics HTTP/1.1" 200 - 0 148528 5096 90 "172.30.146.87" "curl/7.35.0" "c6bfdfc3-07ec-9c30-8957-6904230fd037" "edition.cnn.com" "151.101.65.67:443"
    {{< /text >}}

### 清除 TLS 发起的 egress 网关

删除我们创建的 Istio 配置项：

{{< text bash >}}
$ istioctl delete gateway istio-egressgateway
$ istioctl delete serviceentry cnn
$ istioctl delete virtualservice direct-through-egress-gateway
$ istioctl delete destinationrule originate-tls-for-edition-cnn-com
$ istioctl delete destinationrule set-sni-for-egress-gateway
{{< /text >}}

## 通过 egress 网关定向 HTTPS 流量

在本节中，您将通过 egress 网关引导HTTPS流量（由应用程序发起的 TLS）。在相应的 `ServiceEntry` 中指定端口 443，协议 `TLS`，egress `Gateway` 和 `VirtualService`。

1.  为 `edition.cnn.com` 定义 `ServiceEntry`：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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

1.  验证您的 `ServiceEntry` 是否已正确应用。发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出应与上一节中的输出相同。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  为  _edition.cnn.com_  创建 egress `Gateway` ，端口 443，TLS 协议。

    如果在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/) ，请使用以下命令。请注意，除了创建 `Gateway` 之外，它还创建了一个 `DestinationRule` 来指定 egress 网关的 mTLS，将 SNI 设置为 `edition.cnn.com`。

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
      name: set-sni-for-egress-gateway
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: MUTUAL
            clientCertificate: /etc/certs/cert-chain.pem
            privateKey: /etc/certs/key.pem
            caCertificates: /etc/certs/root-cert.pem
            subjectAltNames:
            - spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
            sni: edition.cnn.com
    EOF
    {{< /text >}}

    除此之外:

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
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
    EOF
    {{< /text >}}

1.  定义 `VirtualService` 来引导流量通过 egress 网关：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-through-egress-gateway
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - istio-egressgateway
      - mesh
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
            port:
              number: 443
          weight: 100
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

1.  发送 HTTPS 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。输出应与之前相同。

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

1.  检查 egress 网关代理的统计信息，并查看与我们对 _edition.cnn.com_ 的请求相对应的计数器。如果 Istio 部署在 `istio-system` 命名空间中，则打印计数器的命令是：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c egressgateway -n istio-system -- curl -s localhost:15000/stats | grep edition.cnn.com.upstream_cx_total
    cluster.outbound|443||edition.cnn.com.upstream_cx_total: 1
    {{< /text >}}

    您可能需要执行几个额外的请求，并验证每个请求上面的计数器增加1。

### 清除 HTTPS 流量的 egress 网关

{{< text bash >}}
$ istioctl delete serviceentry cnn
$ istioctl delete gateway istio-egressgateway
$ istioctl delete virtualservice direct-through-egress-gateway
$ istioctl delete destinationrule set-sni-for-egress-gateway
{{< /text >}}

## 其他安全因素

请注意，在 Istio 中定义 egress `Gateway` 本身并不为运行 egress 网关服务的节点提供任何特殊处理。集群管理员或云提供商可以在专用节点上部署 egress 网关，并引入额外的安全措施，使这些节点比网格的其余部分更安全。

另请注意，实际上 Istio 本身无法安全地强制将所有 egress 流量流经 egress 网关，Istio 仅通过其 sidecar 代理启用此类流量。如果恶意应用程序攻击连接到应用程序 pod 的 sidecar 代理，它可能会绕过 sidecar 代理。绕过 sidecar 代理后，恶意应用程序可能会尝试绕过 egress 网关退出服务网格，以逃避 Istio 的控制和监控。由集群管理员或云提供商来强制执行没有流量绕过 egress 网关的网格。这种强制执行必须由 Istio 以外的机制执行。例如，防火墙可以拒绝其源不是 egress 网关的所有流量。 [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)也可以禁止所有不在 egress 网关中出口的 egress 流量。另一种可能的安全措施涉及以这样的方式配置网络：应用节点不能访问因特网而不将 egress 流量引导到将被监视和控制的网关。这种网络配置的一个例子是将公共 IP 专门分配给网关。

## 故障排除

1.  检查您是否在 Istio 中启用了[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)，然后执行以下步骤：[验证 Istio 的双向 TLS 认证设置](/docs/tasks/security/mutual-tls/#verifying-istio-s-mutual-tls-authentication-setup)。如果启用了双向 TLS，请确保创建相应的项目配置（请注意备注 _如果您在 Istio 中启用了双向 TLS 认证，则必须创建..._ ）。

1.  如果[双向 TLS 认证](/zh/docs/tasks/security/mutual-tls/)启用后, 验证 egress 网关的证书：

    {{< text bash >}}
    $ kubectl exec -i -n istio-system $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')  -- cat /etc/certs/cert-chain.pem | openssl x509 -text -noout  | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name:
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
    {{< /text >}}

## 清理

关闭 [sleep]({{<github_tree>}}/samples/sleep) 服务:

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
