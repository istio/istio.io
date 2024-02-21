---
title: 出口网关
description: 描述如何配置 Istio 通过专用网关服务将流量定向到外部服务。
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /zh/docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
此例子对 Minikube 无效。
{{</warning>}}

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/egress-control)任务展示了如何配置
Istio 以允许网格内部的应用程序访问外部 HTTP 和 HTTPS 服务，但那个任务实际上是通过
Sidecar 直接调用的外部服务。而这个示例会展示如何配置 Istio 以通过专用的 **Egress Gateway**
服务间接调用外部服务。

Istio 使用 [Ingress 和 Egress Gateway](/zh/docs/reference/config/networking/gateway/)
配置运行在服务网格边缘的负载均衡。Ingress Gateway 允许您定义网格所有入站流量的入口。
Egress Gateway 是一个与 Ingress Gateway 对称的概念，它定义了网格的出口。
Egress Gateway 允许您将 Istio 的功能（例如，监视和路由规则）应用于网格的出站流量。

## 使用场景 {#use-case}

设想一个对安全有严格要求的组织，要求服务网格所有的出站流量必须经过一组专用节点。
专用节点运行在专门的机器上，与集群中运行应用程序的其他节点隔离。
这些专用节点用于实施 Egress 流量的策略，并且受到比其余节点更严密地监控。

另一个使用场景是集群中的应用节点没有公有 IP，所以在该节点上运行的网格
Service 无法访问互联网。通过定义 Egress gateway，将公有 IP 分配给
Egress Gateway 节点，用它引导所有的出站流量，可以使应用节点以受控的方式访问外部服务。

{{< boilerplate gateway-api-gamma-support >}}

## 开始之前 {#before-you-begin}

*   参照[安装指南](/zh/docs/setup/)中的说明搭建 Istio。

    {{< tip >}}
    如果您安装 `demo` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)，
    则会启用 Egress Gateway 和访问日志。
    {{< /tip >}}

*   部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，用作发送请求的测试源。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    {{< tip >}}
    您可以使用任何安装了 `curl` 的 Pod 作为测试源。
    {{< /tip >}}

*   将 `SOURCE_POD` 环境变量设置为源 Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

    {{< warning >}}
    此任务中的指令在 `default` 命名空间中为 Egress Gateway 创建目标规则。
    并假设客户端 `SOURCE_POD` 也在 `default` 命名空间中运行。如果没有，
    目标规则将不会在[目标规则查找路径](/zh/docs/ops/best-practices/traffic-management/#cross-namespace-configuration)上找到，
    并且客户端请求将失败。
    {{< /warning >}}

*   如果尚未启用，则[启用 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)。
    例如，使用 `istioctl`：

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

## 部署 Istio Egress Gateway {#deploy-Istio-egress-gateway}

{{< tip >}}
当使用 Gateway API 配置 Egress Gateway 时，这些 Egress Gateway
会被[自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#deployment-methods)。
如果您在下文中使用 `Gateway API` 指令，则可以跳过这部分。
{{< /tip >}}

1. 检查 Istio Egress Gateway 是否已部署：

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    如果没有 Pod 返回，通过接下来的步骤来部署 Istio Egress Gateway。

1. 如果您使用 `IstioOperator` CR 安装 Istio，请在配置中添加以下字段：

    {{< text yaml >}}
    spec:
      components:
        egressGateways:
        - name: istio-egressgateway
          enabled: true
    {{< /text >}}

    否则，将等效设置添加到原始 `istioctl install` 命令中，例如：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set "components.egressGateways[0].name=istio-egressgateway" \
                       --set "components.egressGateways[0].enabled=true"
    {{< /text >}}

## 定义 Egress gateway 并引导 HTTP 流量 {#egress-gateway-for-http-traffic}

首先创建一个 `ServiceEntry`，允许流量直接访问一个外部服务。

1. 为 `edition.cnn.com` 定义一个 `ServiceEntry`：

    {{< warning >}}
    必须在下面的服务条目中使用 `DNS` 解析。如果分辨率为 `NONE`，
    则网关将将流量引导到一个无限循环中。这是因为网关收到原始请求目标
    IP 地址，该地址等于网关的服务IP（因为请求是由 Sidecar 定向的网关的代理）。

    借助 `DNS` 解析，网关执行 DNS 查询以获取外部服务的 IP 地址并进行定向该 IP 地址的流量。
    {{< /warning >}}

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

1. 发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，
   验证 `ServiceEntry` 是否已正确应用。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    输出结果应该与[发起 TLS 的 Egress 流量](/zh/docs/tasks/traffic-management/egress/egress-tls-origination/)中示例中的输出结果相同，
    都还没有发起 TLS。

1. 为 `edition.cnn.com` 端口 80 创建 Egress `Gateway`。并为指向
   Egress Gateway 的流量创建一个目标规则。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
要通过 Egress Gateway 引导多个主机，您可以在 `Gateway` 中包含主机列表，
或使用 `*` 匹配所有主机。应该将 `DestinationRule` 中的 `subset` 字段重用于其他主机。
{{< /tip >}}

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  配置路由规则，将流量从边车导向到 Egress Gateway，再从 Egress Gateway 导向到外部服务：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  重新发送 HTTP 请求到 [http://edition.cnn.com/politics](https://edition.cnn.com/politics)。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    输出应与第 2 步中的输出相同。

6)  检查 Egress Gateway Pod 的日志，找到与请求对应的那一行。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

您应该会看到一行类似于下面这样的内容：

{{< text plain >}}
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
{{< /text >}}

{{< tip >}}
如果启用了[双向 TLS 身份验证](/zh/docs/tasks/security/authentication/authn-policy/)，
并且当您在连接到出口网关时遇到问题，请运行以下命令来验证证书是否正确：

{{< text bash >}}
$ istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用 Istio 生成的 Pod 标签访问与 Egress Gateway 对应的日志：

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

您应该会看到一行类似于下面这样的内容：

{{< text plain >}}
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< tip >}}
如果启用了[双向 TLS 身份验证](/zh/docs/tasks/security/authentication/authn-policy/)，
并且当您在连接到出口网关时遇到问题，请运行以下命令来验证证书是否正确：

{{< text bash >}}
$ istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

请注意，您只是将流量从 80 端口重定向到 Egress Gateway。到端口 443 的 HTTPS
流量直接进入 **edition.cnn.com**。

### 清理 HTTP Gateway {#cleanup-http-gateway}

在继续下一步之前删除先前的定义：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 用 Egress Gateway 发起 HTTPS 请求 {#egress-gateway-for-https-traffic}

接下来尝试使用 Egress Gateway 发起 HTTPS 请求（TLS 由应用程序发起）。
您需要在相应的 `ServiceEntry` 和 Egress `Gateway` 中指定 `TLS` 协议的端口 443。

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

1. 发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，
   验证您的 `ServiceEntry` 是否已正确生效。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

1. 为 `edition.cnn.com` 创建一个 Egress `Gateway`。除此之外还需要创建一个
   目标规则和一个虚拟服务，用来引导流量通过 Egress Gateway，
   并通过 Egress Gateway 与外部服务通信。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
要通过 Egress Gateway 引导多个主机，您可以在 `Gateway` 中包含主机列表，
或使用 `*` 匹配所有主机。应该将 `DestinationRule` 中的 `subset` 字段用于其他主机。
{{< /tip >}}

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
      sniHosts:
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
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  发送 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)，
    输出结果应该和之前一样。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

5)  检查 Egress Gateway 代理的日志。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

您应该会看到类似于下面的内容：

{{< text plain >}}
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用 Istio 生成的 Pod 标签访问与 Egress Gateway 对应的日志：

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

您应该会看到类似于下面的内容：

{{< text plain >}}
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清理 HTTPS Gateway {#cleanup-https-gateway}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete tlsroute direct-cnn-to-egress-gateway
$ kubectl delete tlsroute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 其他安全注意事项 {#additional-security-considerations}

注意，Istio 中定义的 egress `Gateway` 本身并没有为其所在的节点提供任何特殊处理。
集群管理员或云提供商可以在专用节点上部署 Egress Gateway，并引入额外的安全措施，
从而使这些节点比网格中的其他节点更安全。

另外要注意的是，Istio **无法强制**让所有出站流量都经过 Egress Gateway，
Istio 只是通过 Sidecar 代理实现了这种流向。攻击者只要绕过 Sidecar 代理，
就可以不经 Egress Gateway 直接与网格外的服务进行通信，从而避开了 Istio 的控制和监控。
出于安全考虑，集群管理员和云供应商必须确保网格所有的出站流量都要经过 Egress Gateway。
这需要通过 Istio 之外的机制来满足这一要求。例如，集群管理员可以配置防火墙，
拒绝 Egress Gateway 以外的所有流量。
[Kubernetes 网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)也能禁止所有不是从
Egress Gateway 发起的出站流量（[下一节](#apply-Kubernetes-network-policies)有一个这样的例子）。
此外，集群管理员和云供应商还可以对网络进行限制，让运行应用的节点只能通过 gateway 来访问外部网络。
要实现这一限制，可以只给 gateway Pod 分配公网 IP，并且可以配置 NAT 设备，
丢弃来自 Egress Gateway Pod 之外的所有流量。

## 应用 Kubernetes 网络策略 {#apply-Kubernetes-network-policies}

本节中展示了如何创建 [Kubernetes 网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)来阻止绕过
Egress Gateway 的出站流量。为了测试网络策略，首先创建一个 `test-egress` 命名空间，
并在其中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，
然后尝试发送一个会通过安全网关的外部服务请求。

1. 参考[用 Egress Gateway 发起 HTTPS 请求](#egress-gateway-for-http-traffic)一节中的步骤。

1. 创建 `test-egress` 命名空间：

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

1. 在 `test-egress` 命名空间中部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用：

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  将 [sleep]({{< github_tree >}}/samples/sleep) 样例部署到 `test-egress` 命名空间。

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 检查生成的 Pod，其中应该只有一个容器，也就是说没有注入 Istio Sidecar：

    {{< text bash >}}
    $ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    sleep-776b7bcdcd-z7mc4   1/1       Running   0          18m
    {{< /text >}}

1. 从 `test-egress` 命名空间的 `sleep` Pod 中向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)
   发送 HTTPS 请求。因为没有任何限制，所以这一请求应该会成功：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

1. 给 Istio 组件（控制平面和 Gateway）所在的命名空间打上标签。
   如果您将 Istio 部署在 `istio-system` 命名空间中，则命令是：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
$ kubectl label namespace default gateway=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) 给 `kube-system` 命名空间打标签：

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

8) 创建一个 `NetworkPolicy`，来限制 `test-egress` 命名空间的出站流量，
    只允许目标为控制平面、网关和 `kube-system` DNS 服务（端口 53）的所有请求。

    {{< warning >}}
    [网络政策](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)由
    Kubernetes 集群中的网络插件实现。根据您的测试集群，以下步骤中的流量可能不会被阻止。
    {{< /warning >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

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
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

9) 重新发送前面的 HTTPS 请求到 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)。
   这次请求就不会成功了，这是因为流量被网络策略拦截了。`sleep` Pod 无法绕过 `istio-egressgateway`。
   要访问 `edition.cnn.com`，只能通过 Istio Sidecar 代理，让流量经过 `istio-egressgateway`
   才能完成。这种配置表明，即使一些恶意的 Pod 绕过了 Sidecar，也会被网络策略拦截，而无法访问到外部站点。

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -v -sS https://edition.cnn.com/politics
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

10) 接下来在 `test-egress` 命名空间的 `sleep` Pod 上注入 Sidecar，启用
   `test-egress` 命名空间的自动注入：

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

11) 重新部署 `sleep`：

    {{< text bash >}}
    $ kubectl delete deployment sleep -n test-egress
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n test-egress
    {{< /text >}}

12) 检查生成的 Pod，其中应该有了两个容器，其中包含了注入的 sidecar（`istio-proxy`）：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
sleep istio-proxy
{{< /text >}}

在 `default` 命名空间中创建一个与 `sleep` Pod 类似的目标规则，用来引导
`test-egress` 命名空间内的流量经过 Egress Gateway：

{{< text bash >}}
$ kubectl apply -n test-egress -f - <<EOF
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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
sleep istio-proxy
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

13) 向 [https://edition.cnn.com/politics](https://edition.cnn.com/politics)
    发送 HTTP 请求，这次会成功，原因是网络策略允许流量流向 Egress Gateway。
    Gateway 最终把流量转发到 `edition.cnn.com`。

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=sleep -o jsonpath={.items..metadata.name})" -n test-egress -c sleep -- curl -sS -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

14) 检查 Egress Gateway 代理的日志。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

如果 Istio 部署在 `istio-system` 命名空间，那么打印日志的命令就是：

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

您应该会看到一行类似于下面这样的内容：

{{< text plain >}}
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

使用 Istio 生成的 Pod 标签访问与 Egress Gateway 对应的日志：

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

您应该会看到一行类似于下面这样的内容：

{{< text plain >}}
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504837 46 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清理网络策略 {#cleanup-network-policies}

1. 删除本节中建立的资源：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
$ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@ -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl label namespace default gateway-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) 请参考[清理 HTTPS Gateway](#cleanup-https-gateway) 一节的内容。

## 清理 {#cleanup}

关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
