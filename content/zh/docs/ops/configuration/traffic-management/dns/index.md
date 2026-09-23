---
title: 理解 DNS
linktitle: DNS
description: 理解 Istio 如何与 DNS 交互。
weight: 31
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio 以不同的方式与 DNS 交互，这可能会让人感到困惑。本文档深入介绍了
Istio 和 DNS 的交互方式。

{{< warning >}}
本文档描述了底层实施细节。要了解更高层次的概述，
请查看流量管理[概念](/zh/docs/concepts/traffic-management/)或
[任务](/zh/docs/tasks/traffic-management/)页面。
{{< /warning >}}

## 范围与视角 {#scope-and-perspective}

本文档描述了在 Istio 服务网格内部运行的应用工作负载（已启用 Envoy 边车代理）的 DNS 行为。

在本文档中，术语 `client` 指代网格内部的工作负载。

## 请求过程 {#life-of-a-request}

在这些示例中，我们将逐步演示网格内的应用程序执行 `curl example.com`
命令时所发生的过程。虽然此处为了简化起见使用了 `curl`，
但这一原理同样适用于网格内运行的几乎所有 HTTP 客户端。

当您向某个域名发送请求时，客户端会首先执行 DNS 解析，
将主机名解析为 IP 地址。无论 Istio 的设置如何，
这一过程都会发生；因为 Istio 仅负责拦截网络流量，
而无法改变应用程序执行 DNS 查找的决定。
在下方的示例中，`example.com` 被解析为 `192.0.2.0`。

{{< text bash >}}
$ curl example.com -v
*   Trying 192.0.2.0:80...
{{< /text >}}

只有在 DNS 解析成功后，应用程序才会尝试建立网络连接；
而这正是 Istio 能够拦截流量的时机。

接下来，该请求会被 Istio 拦截。此时，Istio 能够同时获取主机名（来自 `Host: example.com` 标头）
和目标地址（`192.0.2.0:80`）。Istio 利用这些信息来确定预期的目标。

[理解流量路由](/zh/docs/ops/configuration/traffic-management/traffic-routing/)深入探讨了这一行为的工作原理。

如果网格工作负载无法使用其配置的 DNS 解析器解析 DNS 名称，则连接将永远不会被发起。

Istio 的 [DNS 代理](#dns-proxying)功能可以通过拦截来自应用程序的
DNS 请求并直接返回响应，来改变这一行为。

一旦 Istio 确定了预期的目标地址，它必须选择具体将流量发送至哪一个地址。
得益于 Istio 先进的[负载均衡能力](/zh/docs/concepts/traffic-management/#load-balancing-options)，
该地址往往并非客户端最初发送的那个 IP 地址。
根据具体的服务配置，Istio 实现这一过程的方式主要有几种。

* 使用客户端的原始 IP 地址（在上述示例中为 `192.0.2.0`）。
  对于类型为 `resolution: NONE`（默认值）的 `ServiceEntry`
  以及[无头（Headless）`Services`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services) 而言，
  情况正是如此。
* 在一组静态 IP 地址上执行负载均衡。这种情况适用于 `resolution: STATIC`
  类型的 `ServiceEntry`（此时将使用所有的 `spec.endpoints`），
  或标准 `Service`（此时将使用所有的 `Endpoints`）。
* 使用 DNS 定期解析地址，并在所有结果中进行负载均衡。这种情况适用于
  `resolution: DNS` 类型的 `ServiceEntry`。

请注意，在所有情况下，Istio 代理内部的 DNS 解析均独立于用户应用程序执行的 DNS 解析。
即使客户端已执行了 DNS 解析，代理仍可能忽略解析出的 IP 地址，
转而使用其自身的 IP 地址——该地址可能源自静态 IP 列表，
也可能源自代理自身执行的 DNS 解析（解析对象可能是同一主机名，也可能是另一主机名）。

## 代理 DNS 解析 {#proxying-dns-resolution}

与大多数客户端不同（大多数客户端通常会在发出请求时按需执行 DNS 查询，随后缓存查询结果），
Istio 代理绝不会执行同步 DNS 查询。当配置了 `resolution: DNS`
类型的 `ServiceEntry` 时，代理会周期性地解析所配置的主机名，
并将解析结果应用于所有的请求。此解析周期固定为 30 秒，
目前尚无法进行修改。即使代理从未向关联的服务发送过任何请求，
DNS 解析过程依然会照常执行。

对于包含大量代理或大量 `resolution: DNS` 类型 `ServiceEntry` 的网格，
尤其是当使用较低的 DNS `TTL` 值时，这可能会给 DNS 服务器造成较高的负载。
在这种情况下，采取以下措施有助于减轻负载：

* 将 `ServiceEntries` 切换为 `resolution: NONE` 类型以完全避免代理 DNS 查找，
  这适用于许多使用场景。
* 如果您控制着正在被解析的域名，请增加它们的 `TTL` 值。
* 如果某个 `ServiceEntry` 仅被少量工作负载所需要，请使用 `exportTo`
  或 [`Sidecar`](/zh/docs/reference/config/networking/sidecar/) 来限制其作用域。

## DNS 代理 {#dns-proxying}

Istio 提供了一项用于[代理 DNS 请求](/zh/docs/ops/configuration/traffic-management/dns-proxy/)的功能。
借此，Istio 能够捕获应用程序发出的 DNS 请求，并直接返回响应。

DNS 代理能够改善 DNS 延迟、减轻上游 DNS 服务器的负载，
并允许解析那些原本对 `kube-dns` 或 `core-dns`
而言属于未知的主机名（即 `ServiceEntry` 中的主机名）。

请注意，DNS 代理仅适用于由用户应用程序发出的 DNS 请求。
当使用类型为 `resolution: DNS` 的 `ServiceEntry` 时，
DNS 代理不会影响 Istio 代理自身执行 DNS 解析的方式。
