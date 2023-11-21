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

## 请求过程 {#life-of-a-request}

下面我们将以一个应用程序运行 `curl example.com` 为例来看一个请求的全过程。
这里的 `curl` 请求过程适用于几乎所有客户端。

当您向一个域名发送请求时，客户端会进行 DNS 解析，将其解析为一个 IP 地址。
不管 Istio 如何设置，这都会发生，因为 Istio 只是拦截网络流量；
它不能改变应用程序的行为或决定是否发送 DNS 请求。在下面的例子中，
`example.com` 被解析为 `192.0.2.0`。

{{< text bash >}}
$ curl example.com -v
*   Trying 192.0.2.0:80...
{{< /text >}}

接下来，该请求将被 Istio 拦截。这时，Istio 将看到主机名（来自
`Host: example.com` 头）和目标地址（`192.0.2.0:80`）。Istio
使用这些信息来确定预定目的地。
[理解流量路由](/zh/docs/ops/configuration/traffic-management/traffic-routing/)对这种行为的工作原理进行了深入探讨。

如果客户端无法解析 DNS 请求，在 Istio 收到请求之前就会终止。
这意味着，即使一个请求发送到一个 Istio 已知的主机名（例如，通过
`ServiceEntry` 配置），但是无法通过 DNS 解析，该请求也会失败。
不过 Istio 的 [DNS 代理](#dns-proxing)可以改变这种行为。

一旦 Istio 确定了预期的目的地，它必须选择要发送到的地址。由于
Istio 的高级[负载均衡能力](/zh/docs/concepts/traffic-management/#load-balancing-options)，
这个地址往往不是客户端发送的原始 IP 地址。根据服务配置的不同，Istio
有几种不同的方式来实现：

* 使用客户端的原始 IP 地址（上例中为 `192.0.2.0`）。
  这种情况适用于 `resolution: NONE` 类型的 `ServiceEntry`
  和[无头服务](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services)。
* 在一组静态 IP 地址上进行负载均衡。这种情况适用于 `resolution: STATIC`
  类型的 `ServiceEntry`，这将使用 `spec.endpoints` 中的所有地址，
  或者对于标准 `Services` 将使用其所有 `Endpoints` 地址。
* 使用 DNS 定期解析地址，并在所有结果中进行负载均衡。这种情况适用于
  `resolution: DNS` 类型的 `ServiceEntry`。

请注意，在任何情况下，Istio 代理内部的 DNS 解析与用户应用程序中的
DNS 解析是正交（orthogonal）的。即使客户端进行了 DNS 解析，
代理也可能忽略已解析的 IP 地址，而使用自己的地址，这些地址可能来自静态的
IP 列表或通过代理的 DNS 解析（可能是同一主机名或不同的主机名）。

## 代理 DNS 解析 {#proxying-dns-resolution}

与大多数客户端在请求时按需执行 DNS 请求（然后通常缓存结果）不同，
Istio 代理从不执行同步 DNS 请求。配置 `resolution: DNS`
类型的 `ServiceEntry` 后，代理将定期解析配置的主机名并将其用于所有请求。
此时间间隔由 DNS 响应的 [TTL](https://en.wikipedia.org/wiki/Time_to_live#DNS_records)
确定。即使代理从未向这些应用程序发送任何请求，该情况也会发生。

对于具有许多代理或许多 `resolution: DNS` 类型 `ServiceEntry`
的网格而言，尤其是在使用较低 `TTL` 时，可能会导致 DNS 服务器的负载很高。
在这些情况下，以下行为有助于减轻负载：

* 将 `ServiceEntries` 切换为 `resolution: NONE` 类型以完全避免代理 DNS 查找，
  这适用于许多使用场景。
* 如果您可以控制正在解析的域，请适当增加它们的 TTL。
* 如果您的 `ServiceEntry` 只有少量工作负载，请使用 `exportTo`
  或 [`Sidecar`](/zh/docs/reference/config/networking/sidecar/) 限制其范围。

## DNS 代理 {#dns-proxing}

Istio 提供了[代理 DNS 请求](/zh/docs/ops/configuration/traffic-management/dns-proxy/)的功能。
这允许 Istio 捕获客户端发送的 DNS 请求并直接返回响应。这可以改善 DNS 延迟，
减少负载，并解决了 `ServiceEntries` 无法通过 `kube-dns` 解析的问题。

请注意，此代理仅适用于用户应用程序发送的 DNS 请求；当使用 `resolution: DNS`
类型的 `ServiceEntries` 时，DNS 代理对 Istio 代理的 DNS 解析没有影响。
