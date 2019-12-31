---
title: Istio 中的安全管控出口流量，第二部分
subtitle: 使用 istio 的出口流量管控来防止相关出口流量攻击
description: 使用 istio 的出口流量管控来防止相关出口流量攻击。
publishdate: 2019-07-10
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,egress,security,gateway,tls]
target_release: 1.2
---

欢迎来看在 Istio 对出口流量进行安全管控系列文章的第 2 部分。
在[这个系列文章的第一步](/zh/blog/2019/egress-traffic-control-in-istio-part-1/),我提出了出口流量相关攻击和针对出口流量进行安全管控我们收集的要求点。
在这一期中，我会讲述对出口流量进行安全管控的 Istio 方式，并且展示 Istio 如何帮你防止攻击。

## Secure control of egress traffic in Istio
## Istio 中的出口流量安全管控 {#secure-control-of-egress-traffic-in-Istio}

为了在 Istio 中实施出口流量的安全管控，你必须[通过出口网关将 TLS 流量发送到外部服务](/zh/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-https-traffic)。
或者可以[通过出口网关发送 HTTP 流量](/zh/docs/tasks/traffic-management/egress/egress-gateway/#egress-gateway-for-http-traffic)，并且[让出口网关来发起执行 TLS](/zh/docs/tasks/traffic-management/egress/egress-gateway-tls-origination/#perform-TLS-origination-with-an-egress-gateway)。

两种选择各有利弊，你应该根据你的具体场景进行选择。选择的关键取决于你的应用陈旭是否能发送不加密的 HTTP 请求和你团队的安全策略是否允许发送不加密的 HTTP 请求。
例如，如果你的应用程序使用了某些客户端库，用这些库来对流量进行加密，但是它无法取消加密，你就不能使用发送不加密 HTTP 流量的选项。万一你团队的安全策略无法让你**在 pod 内**发送不加密的 HTTP 请求也是一样的（pod 外的流量由 Istio 来加密）。

如果应用程序发送 HTTP 请求，并且由出口网关发起执行 TLS，你就可以监控 HTTP 信息，像 HTTP 方法、HTTP 头和 URL 路径。也可以根据上面说的 HTTP 信息来[定义策略](/zh/blog/2018/egress-monitoring-access-control)。如果是由应哟过程序发起执行 TLS，你就可以对源 pod 的 TLS 流量的[ SNI 和服务账号进行监控](/zh/docs/tasks/traffic-management/egress/egress_sni_monitoring_and_policies/)，并且基于 SNI 和服务账号定义策略。

你必须确保你集群到外部的流量不能绕过出口网关。Istio 不能给你确保这一点，所以你必需使用一些[附加的安全机制](/zh/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)，比如 [Kubernetes 网络策略](https://kubernetes.io/docs/concepts/services-networking/network-policies/)或者 L3 防火墙。 看一个 [Kubernetes 网络策略配置](/zh/docs/tasks/traffic-management/egress/egress-gateway/#apply-Kubernetes-network-policies)的例子。
根据[纵深防御](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) 的概念，为同一个目标使用的安全机制越多越安全。

你必需也要确保 Istio 控制面和出口网关不能被破坏。你的集群里面可能有成百上千的应用程序 pod，而只有十几个 Istio 控制面 pod 和网关。
你可以也应该聚焦在保护控制面 pod 和网关，因为这比较容易（需要保护的 pod 数量很少），并且这对集群的安全性是最关键的。
如果攻击者破坏了控制面和出口网关，他们可以违反任何策略。

根据环境的不同，你可能有多种工具来保护控制面 pod。合理的安全策略如下：

- 把运行控制面 pod 的节点和应用程序节点隔离开。
- 把控制面的 pod 运行在它们自己独立的命名空间中。
- 启用 Kubernetes 的 RBAC 和网络策略来保护控制面的 pod。
- 监控控制面 pod 要比监控应用程序 pod 更紧密。

一旦你通过出口网关引导了出口流量，并且应用了附加的安全机制，就可以进行安全的监控和施加对流量的安全策略。

下图展示了 Istio 的安全架构，用 L3 防火墙进行了加强， L3 防火墙就是[附加安全机制](/zh/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)的一部分，它应该在 Istio 的外面。

{{< image width="80%" link="./SecurityArchitectureWithL3Firewalls.svg" caption="带有出口网关和 L3 防火钱的 Istio 安全架构" >}}

可以简单的配置 L3 防火墙，使它只允许通过 Istio 入口网关来的流量，并且只允许通过 Istio 出口网关出去的流量。网关的 Istio 代理执行策略，并且和在网格中其它所有代理一样上报检测信息。

现在我们来测试一下可能的攻击，并且我会给你们展示 Istio 中的出口流量安全管控是怎么防止攻击的。

## 防止可能的攻击 {#preventing-possible-attacks}

参考以下出口流量的安全策略：

- 允许应用程序 **A** 访问 `*.ibm.com`，这包含了所有外部服务中匹配 `*.ibm.com` 的 URL。
- 允许应用程序 **B** 访问 `mongo1.composedb.com`。
- 监控所有的出口流量。

假设攻击者有以下目标：

- 从你的集群中访问 `*.ibm.com`。
- 从你的集群中访问 `*.ibm.com`，并且不被监控到。攻击者不想他的流量被监控到，如果被监控到你将会发觉这个禁止的访问。
- 从你的集群中访问 `mongo1.composedb.com`。

现在假设攻击者设法在攻破应用程序 **A** 的其中一个 pod，并且试图使用这个攻破的 pod 来执行被禁止的访问。攻击者可能试试运气直接访问外部服务。你会对这个直接的尝试做出如下反应：

- 最开始，是没有办法阻止被攻破的 应用程序 **A** 去访问 `*.ibm.com`，因为被攻破的 pod 很难和原来的 pod 区分开。
- 幸运的是，你可以监控所有对外部服务的访问，检测可疑流量，并且阻止攻击者获得对 `*.ibm.com` 的无监控访问。例如，你可以用异常检测工具检测出口流量的日志。
- 阻止攻击者从集群中访问 `mongo1.composedb.com`，Istio 会正确的检测流量的源，如这个例子中应用程序 **A**，根据上面提到的安全策略验证它是不是被允许访问 `mongo1.composedb.com`。

Having failed to achieve their goals in a straightforward way, the malicious actors may resort to advanced attacks:

- **Bypass the container's sidecar proxy** to be able to access any external service directly, without the sidecar's
  policy enforcement and reporting. This attack is prevented by a Kubernetes Network Policy or by an L3 firewall that
  allow egress traffic to exit the mesh only from the egress gateway.
- **Compromise the egress gateway** to be able to force it to send fake information to the monitoring system or to
  disable enforcement of the security policies. This attack is prevented by applying the special security measures to
  the egress gateway pods.
- **Impersonate as application B** since application **B** is allowed to access `mongo1.composedb.com`. This attack,
  fortunately, is prevented by Istio's [strong identity support](/zh/docs/concepts/security/#istio-identity).

As far as we can see, all the forbidden access is prevented, or at least is monitored and can be prevented later.
If you see other attacks that involve egress traffic or security holes in the current design, we would be happy
[to hear about it](https://discuss.istio.io).

## Summary

Hopefully, I managed to convince you that Istio is an effective tool to prevent attacks involving egress
traffic. In [the next part of this series](/zh/blog/2019/egress-traffic-control-in-istio-part-3/), I compare secure control of egress traffic in Istio with alternative
solutions such as
[Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) and legacy
egress proxies/firewalls.
