---
title: Istio 使用网络策略
description: Istio 的策略如何关联 Kubernetes 的网络策略 。
publishdate: 2017-08-10
subtitle:
attribution: Spike Curtis
weight: 97
---

使用网络策略去保护运行在 Kubernetes 上的应用程序现在是一种广泛接受的行业最佳实践。 鉴于 Istio 也支持策略，我们希望花一些时间来解释 Istio 策略和 Kubernetes 网络策略的相互作用和互相支持提供应用程序的安全。

让我们从基础开始：为什么你想要同时使用 Istio 和 Kubernetes 网络策略？ 简短的回答是它们处理不同的事情。 表格列出 Istio 和网络策略之间的主要区别（我们将描述“典型”实现，例如：Calico，但具体实现细节可能因不同的网络提供商而异）：

|                      | Istio 策略        |网络策略           |
| -------------------- | ----------------- | ------------------ |
| **层级**              |"服务" --- L7     |"网络" --- L3-4    |
| **实现**              |用户空间          |内核               |
| **执行点**            |Pod               |节点               |

## 层级

从 OSI 模型的角度来看7层（应用程序），Istio 策略运行在网络应用程序的“服务”层。但事实上云原生应用程序模型是7层实际上至少包含两层：服务层和内容层。服务层通常是 HTTP ，它封装了实际的应用程序数据（内容层）。Istio 的 Envoy 代理运行的 HTTP 服务层。相比之下，网络策略在 OSI 模型中的第3层（网络）和第4层（传输）运行。

运行在服务层为 Envoy 代理提供了一组丰富的属性，以便基础协议进行策略决策，其中包括 HTTP/1.1 和 HTTP/2（ gRPC 运行在 HTTP/2 上）。因此，您可以基于虚拟主机、URL或其他 HTTP 头部应用策略。在未来，Istio 将支持广泛的7层协议、以及通用的 TCP 和 UDP 传输。

相比之下，Istio 策略运行在网络层具有通用的优势，因为所有网络应用程序都使用IP。无论7层协议如何，您都可以在网络层应用策略：DNS 、SQL 数据库、实时流以及许多不使用 HTTP 的其他服务都可以得到保护。网络策略不仅限于经典防火墙的 IP 地址、 协议和端口三元组， Istio 和网络策略都可以使用丰富的 Kubernetes 标签来描述 pod 端点。

## 实现

Istio 的代理基于 [`Envoy`](https://envoyproxy.github.io/envoy/)，它作为数据平面的用户空间守护进程实现的，使用标准套接字与网络层交互。这使它在处理方面具有很大的灵活性，并允许它在容器中分发（和升级！）。

网络策略数据平面通常在内核空间中实现（例如：使用 iptables 、eBPF 过滤器、或甚至自定义内核模块）。在内核空间使它们性能很好，但不像 Envoy 代理那样灵活。

## 执行点

Envoy 代理的策略执行是在 pod 中，作为同一网络命名空间中的 sidecar 容器。这使得部署模型简单。某些容器赋予权限可以重新配置其 pod 中的网络（CAP_NET_ADMIN）。如果此类服务实例绕过代理受到损害或行为不当（如：在恶意租户中）。

虽然这不会让攻击者访问其他启用了 Istio 的 pod ，但通过配置，会打开几种攻击：

- 攻击未受保护的 pods
- 尝试通过发送大量流量为受保护的 pods 造成访问拒绝
- 在 pod 中收集的漏出数据
- 攻击集群基础设施（ 服务器或 Kubernetes 服务）
- 攻击网格外的服务，如数据库，存储阵列或遗留系统。

网络策略通常在客户机的网络命名空间之外的主机节点处执行。 这意味着必须避免受损或行为不当的 pod 进入根命名空间的执行。 通过在 Kubernetes 1.8 中添加 egress 策略，这是网络策略成为保护基础设施免受工作负载受损的关键部分。

## 举例

让我们来看一些Istio应用程序使用 Kubernetes 网络策略的示例。 下面我们以 Bookinfo 应用程序为例，介绍网络策略功能的用例：

- 减少应用程序入口的攻击面
- 在应用程序中实现细粒度隔离

### 减少应用程序入口的攻击面

应用程序的 ingress 控制器是外部世界进入我们应用程序的主要入口。 快速查看 `istio.yaml` （用于安装 Istio ）定义了 Istio-ingress，如下所示：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: istio-ingress
  labels:
    istio: ingress
spec:
  type: LoadBalancer
  ports:
  - port: 80
    name: http
  - port: 443
    name: https
  selector:
    istio: ingress
{{< /text >}}

istio-ingress 暴露端口 80 和 443 . 我们需要将流入流量限制在这两个端口上。 Envoy 有[`内置管理接口`](https://www.envoyproxy.io/docs/envoy/latest/operations/admin.html#operations-admin-interface)，我们不希望错误配置 istio-ingress 镜像而导致意外地将我们的管理接口暴露给外界。这里深度防御的示例：正确配置的镜像应该暴露接口，正确配置的网络策略将阻止任何人连接到它，要么失败，要么配置错误，受到保护。

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: istio-ingress-lockdown
  namespace: default
spec:
  podSelector:
    matchLabels:
      istio: ingress
  ingress:
  - ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
{{< /text >}}

### 在应用程序中实现细粒度隔离

如下是 Bookinfo 应用程序的服务示意图：

{{< image width="80%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="Bookinfo Service Graph"
    >}}

此图显示了一个正确功能的应用程序应该允许的每个连接。 所有其他连接，例如从 Istio Ingress 直接到 Rating 服务，不是应用程序的一部分。 让我们排除那些无关的连接，它们不能被攻击者所用。 例如：想象一下，Ingress pod 受到攻击者的攻击，允许攻击者运行任意代码。 如果我们使用网络策略只允许连接到 `productpage`（`http://$GATEWAY_URL/productpage`）的 Pod ，则攻击者不再获得对我的应用程序后端的访问权限，尽管它们已经破坏了服务网格的成员。

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: product-page-ingress
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: productpage
  ingress:
  - ports:
    - protocol: TCP
      port: 9080
    from:
    - podSelector:
        matchLabels:
          istio: ingress
{{< /text >}}

推荐你可以而且应该为每个服务编写类似的策略，允许其他 pod 访问执行。

## 总结

我们认为 Istio 和网络策略在应用策略方面有不同的优势。 Istio 具有应用协议感知和高度灵活性，非常适合应用策略来支持运营目标，如：服务路由、重试、熔断等，以及在应用层开启的安全性，例如：令牌验证。 网络策略是通用的、高效的、与 pod 隔离，使其成为应用策略以支持网络安全目标的理想选择。 此外，拥有在网络堆栈的不同层运行的策略是一件非常好的事情，因为它为每个层提供特定的上下文而不会混合状态并允许责任分离。

这篇文章是基于 Spike Curtis 的三部分博客系列，他是 Tigera 的 Istio 团队成员之一。 完整系列可以在这里找到：<https://www.projectcalico.org/using-network-policy-in-concert-with-istio/>
