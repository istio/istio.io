---
title: "简化到通配符目标的出口路由"
description: "Istio 现在支持带有 DYNAMIC_DNS 解析的通配符 ServiceEntry，允许 Sidecar 将流量直接路由到通配符 HTTPS 目标，同时简化出口配置。"
publishdate: 2026-03-20
attribution: "Rudrakh Panigrahi (Salesforce); Translated by Wilson Wu (DaoCloud)"
keywords: [traffic-management,gateway,mesh,egress,wildcard,service-entry,ambient,waypoint]
---

## 概述 {#overview}

控制出站流量是服务网格部署中的常见需求。许多组织通过设置以下参数来配置其服务网格，以仅允许显式注册的外部服务：

{{< text plain >}}
meshConfig.outboundTrafficPolicy.mode = REGISTRY_ONLY
{{< /text >}}

通过这种配置，任何外部目标都必须使用诸如 `ServiceEntry` 之类的资源，
通过完全限定域名和 DNS 解析类型在网格中注册。

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wikipedia-https
  namespace: istio-system
spec:
  hosts:
  - "www.wikipedia.org"
  ports:
  - name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DNS
  exportTo:
  - "*"
{{< /text >}}

然而，某些外部服务会公开许多动态子域，应用程序可能需要访问诸如以下端点：

{{< text plain >}}
https://en.wikipedia.org
https://de.wikipedia.org
https://upload.wikipedia.org
{{< /text >}}

随着主机名列表的增长，逐个注册主机名很快就会变得难以管理和扩展。
为了解决这个问题，Istio 需要支持通配符主机名注册。

## 为什么通配符 HTTPS 出口难以实现 {#why-wildcard-https-egress-is-difficult}

当工作负载发起 HTTPS 连接时，目标主机名通过 TLS 握手中的**服务器名称指示（SNI）**字段进行传输。

例如，调用 `https://en.wikipedia.org` 的客户端会在 TLS 握手期间，
在 ClientHello SNI 字段中发送主机名 `en.wikipedia.org`。Istio Sidecar 会拦截出站连接，
并确定目标地址是否已注册以及应如何路由。

然而，Istio 的路由模型通常要求预先知道上游目标地址。即使在路由规则中使用通配符匹配，
最终的上游集群仍然必须对应于静态配置的服务。由于不同的子域名可能解析到不同的端点，
因此直接路由到通配符主机在历史上并非易事。

## 通过出口网关进行 SNI 路由 {#sni-routing-via-egress-gateway}

这个问题之前在 Istio 博客文章[将出口流量路由到通配符目标](/zh/blog/2023/egress-sni/)中讨论过。
该架构包含一个专用的出口网关设置，用作 SNI 转发代理。

{{< image width="90%" link="./egress-sni-flow.svg" alt="使用任意域名进行出口 SNI 路由" title="使用任意域名进行出口 SNI 路由" caption="应用程序 → Sidecar → 出口网关 → SNI 检测 → 外部目标" >}}

上图最初发表于[将出口流量路由到通配符目的地](/zh/blog/2023/egress-sni/)。

如上图所示：

1. 应用程序发起 HTTPS 连接。
1. Sidecar 代理拦截此连接，并向出口网关发起内部 mTLS 连接。
1. 网关终止此内部 mTLS 连接。
1. 内部监听器检查原始 TLS 握手中的 SNI 值。
1. 流量动态转发到从 SNI 中提取的主机名。

实现此功能需要多个自定义资源：

* `ServiceEntry` 和 `VirtualService` 用于将通配符域名流量转发到出口网关。
* `DestinationRule` 用于边车服务器和网关之间的 mTLS 通信。
* `EnvoyFilter` 配置使出口网关能够执行动态 SNI 转发，这是该解决方案中最复杂的部分。
  该过滤器通过引入三个组件来扩展网关，利用了 Envoy 的底层功能：一个**对网关 TCP 代理的补丁**，
  用于将流量路由到内部监听器；一个**监听器中的 SNI 检查器**，
  用于从 TLS ClientHello 中提取 SNI；以及一个**动态转发代理集群**，
  用于执行 SNI 的动态 DNS 解析。

虽然这种方法可行，但它会引入额外的网络跃点，并为该跃点增加一层内部 mTLS。
此外，由于需要大量的自定义配置，操作也变得更加复杂，这些配置难以管理且容易出错。
但最近的改进使得用更简单的配置即可实现相同的结果。

## 具有 `DYNAMIC_DNS` 解析的通配符 `ServiceEntry` {#wildcard-serviceentry-with-dynamic-dns-resolution}

Istio 现在支持在 `ServiceEntry` 中使用 `DYNAMIC_DNS` 解析的通配符主机名，
使 Sidecar 代理能够直接路由通配符出站 TLS 流量，而无需出口网关。

例如，以下配置允许访问所有 `*.wikipedia.org` 端点：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wildcard-https
  namespace: istio-system
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
  - "*"
{{< /text >}}

应用此资源后，网格中的工作负载可以通过此 ServiceEntry 连接到任何匹配的子域。

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" https://de.wikipedia.org && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|443||\*\.wikipedia\.org" | grep -E "rq|cx"

HTTP 200
Checking stats after request...
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_connect_fail::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_total::3
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_error::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_success::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_timeout::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_total::3
{{< /text >}}

### 配置工作原理 {#how-the-configuration-works}

{{< image width="90%" link="./egress-dynamic-dns.svg" alt="具有 DYNAMIC_DNS 解析的通配符 ServiceEntry" title="具有 DYNAMIC_DNS 解析的通配符 ServiceEntry" caption="应用程序 → Sidecar → 外部目的地" >}}

使用 `resolution: DYNAMIC_DNS` 的通配符 `ServiceEntry` 会导致
Istio 创建一个动态转发代理 (DFP) 集群，该集群会根据 SNI 字段中的主机名转发 TLS 连接。
通配符主机（例如 `*.wikipedia.org`）首先在网格服务注册表中注册，
以便 Sidecar 能够路由主机名与该模式匹配的出站请求。当工作负载发起 TLS 连接时，
监听器中的 SNI Inspector 会配置为从握手中读取 SNI 值。
然后，DFP 集群会使用该值作为上游主机名来转发连接。
这实际上实现了通配符 HTTPS 出站流量，允许代理动态解析连接并将连接转发到匹配的子域名，
而无需静态配置端点。同时，它还能保持客户端发起的 TLS 会话，原封不动地转发加密流量。

## 其他用例 {#other-use-cases}

这种方法适用于应用程序需要连接到通配符域，同时还要获得网格可观测性和弹性功能的用例。

### Ambient 模式下的出口流量 {#egress-traffic-in-ambient-mode}

在 [Ambient 网格](/zh/docs/ambient/overview/)中，节点级 ztunnel 处理 L4 流量，
可选的 [waypoint 代理](/zh/docs/ambient/usage/waypoint/)可在显式连接时应用 L7 策略和遥测数据。
例如，为了处理通过路点的出站流量，以便为调用多个 AWS 服务终端节点保持一致的策略路径，
可以将 `ServiceEntry` 标记为 `istio.io/use-waypoint`，
以便控制平面将匹配的流量定向到指定的路点 `Gateway`。

以下示例将 `*.amazonaws.com` 注册为外部 TLS (`443`) ServiceEntry，
并将其绑定到名为 `waypoint` 的 waypoint 网关：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: amazonaws-wildcard
  namespace: istio-system
  labels:
    istio.io/use-waypoint: waypoint # attached to a waypoint gateway
spec:
  exportTo:
  - .
  hosts:
  - '*.amazonaws.com'
  location: MESH_EXTERNAL
  ports:
  - name: tls
    number: 443
    protocol: TLS
  resolution: DYNAMIC_DNS
{{< /text >}}

### 发往未知内部目标的流量 {#traffic-to-unknown-internal-destinations}

调用方配置中可能只包含有限数量的服务，但仍然需要通过 mTLS 连接到其他内部服务。具体设置如下：

* 一个 `Sidecar` 资源，它将评分服务的出口主机限制在 `istio-system`
  命名空间内，也就是说，它不能直接调用 details 服务：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: restrict-default
  namespace: default
spec:
  workloadSelector:
    labels:
      app: ratings
  egress:
  - hosts:
    - "istio-system/*"
{{< /text >}}

* `ServiceEntry` 用于定义其他内部服务的通配符服务：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: internal-wildcard-http
  namespace: istio-system
spec:
  hosts:
  - "*.svc.cluster.local"
  ports:
  - name: http
    number: 9080
    protocol: HTTP
  location: MESH_INTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
  - "*"
{{< /text >}}

* 定义此 `ServiceEntry` 的 mTLS 配置的 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: internal-wildcard-dr
  namespace: istio-system
spec:
  host: "*.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: MUTUAL_TLS # needs DNS SAN in cert
  exportTo:
  - "*"
{{< /text >}}

即使评分服务在其配置中没有包含其他服务，
它现在也可以通过使用 DNS 动态解析主机名来调用网格中的其他服务：

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" details.default.svc.cluster.local:9080/details/0 && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|9080||\*\.svc\.cluster\.local" | grep -E "rq_total|rq_success"

Making test request...
HTTP 200
Checking stats after request...
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_success::1
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_total::1
{{< /text >}}

注意：在此用例中，mTLS 需要证书具有 DNS SAN，
因为 Envoy 的动态转发代理利用主机名执行自动 SAN 验证。

## 结论 {#conclusion}

通过引入通配符 `ServiceEntry` 支持和 `DYNAMIC_DNS` 解析，
Istio Sidecar 代理现在可以直接处理发往通配符域名的 HTTP 和 TLS 出站流量。
这简化了配置，提供了更直接的请求路径，无需中间出站网关即可降低延迟，同时仍能保留现有的安全性和策略控制。

## 参考 {#references}

* [将出口流量路由到通配符目标](/zh/blog/2023/egress-sni/)
* [SNI 动态转发代理 - Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [HTTP 动态转发代理 - Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_proxy#arch-overview-http-dynamic-forward-proxy)
