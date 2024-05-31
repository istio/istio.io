---
title: 使用四层安全策略
description: 仅使用 L4 安全覆盖时支持的安全特性。
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Istio [安全策略](/zh/docs/concepts/security)的四层（L4）特性由
{{< gloss >}}ztunnel{{< /gloss >}} 提供支持，这些 L4 特性可用于
{{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}。如果您的集群有支持
[Kubernetes 网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)的
{{< gloss >}}CNI{{< /gloss >}} 插件，则这些策略也可以继续发挥作用，并可用于提供深度防御。

ztunnel 和 {{< gloss "waypoint" >}}waypoint 代理{{< /gloss >}}的分层结构使您可以选择是否为特定工作负载启用七层（L7）处理。
要使用 L7 策略和 Istio 的流量路由特性，您可以为工作负载[部署 waypoint](/zh/docs/ambient/usage/waypoint)。
由于策略现在可以在两个地方强制执行，所以您需要了解一些[注意事项](#considerations)。

## 使用 ztunnel 强制执行策略 {#policy-enforcement-using-ztunnel}

当某个工作负载注册到{{< gloss "Secure L4 Overlay" >}}安全覆盖模式{{< /gloss >}}时，
ztunnel 代理可以强制执行鉴权策略。强制执行点是在连接路径中接收（服务器端）ztunnel 代理之时。

基本的 L4 鉴权策略如下所示：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
{{< /text >}}

此策略既可用于 {{< gloss "sidecar" >}}Sidecar 模式{{< /gloss >}}，也能用于 Ambient 模式。

Istio `AuthorizationPolicy` API 的四层（TCP）特性在 Ambient 模式中的行为与在 Sidecar 模式中的行为相同。
当没有配置鉴权策略时，默认的操作是 `ALLOW`。一旦配置了某个策略，此策略指向的目标 Pod 只允许显式允许的流量。
在上述示例中，带有 `app: httpbin` 标签的 Pod 只允许源自身份主体为
`cluster.local/ns/ambient-demo/sa/sleep` 的流量。来自所有其他源的流量都将被拒绝。

## 目标指向策略 {#targeting-policies}

Sidecar 模式和 Ambient 模式中的 L4 策略采用相同的方式来**指向目标**：
策略的作用域由策略对象所在的命名空间和 `spec` 中可选的 `selector` 进行限定。
如果某个策略位于 Istio 根命名空间（传统上为 `istio-system`），那么该策略将指向所有命名空间。
如果该策略位于任何其他命名空间，则只针对其所在的命名空间。

Ambient 模式中的 L7 策略由通过 {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}
配置的 waypoint 强制执行。这些 waypoint 通过 `targetRef` 字段来**附加**。

## 允许的策略属性 {#allowed-policy-attributes}

鉴权策略规则可以包含 [source](/zh/docs/reference/config/security/authorization-policy/#Source)（`from`）、
[operation](/zh/docs/reference/config/security/authorization-policy/#Operation)（`to`）
和 [condition](/zh/docs/reference/config/security/authorization-policy/#Condition)（`when`）等条款。

以下属性列表决定了策略是否仅针对 L4：

| 类型 | 属性 | 正向匹配 | 反向匹配 |
| --- | --- | --- | --- |
| Source | Peer identity | `principals` | `notPrincipals` |
| Source | Namespace | `namespaces` | `notNamespaces` |
| Source | IP block | `ipBlocks` | `notIpBlocks` |
| Operation | Destination port | `ports` | `notPorts` |
| Condition | Source IP | `source.ip` | 不适用 |
| Condition | Source namespace | `source.namespace` | 不适用 |
| Condition | Source identity | `source.principal` | 不适用 |
| Condition | Remote IP | `destination.ip` | 不适用 |
| Condition | Remote port | `destination.port` | 不适用 |

### 具有七层条件的策略 {#policies-with-layer-7-conditions}

ztunnel 无法强制执行 L7 策略。如果一个策略中的规则与 L7 属性（即上表中未列出的属性）匹配，
并且该策略成为被指向的目标，则此策略将由接收的 ztunnel 强制执行，此策略将由于不够安全而变成 `DENY` 策略。

以下示例增加了针对 HTTP GET 方法的检查：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-sleep-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/sleep
   to:
   - operation:
       methods: ["GET"]
EOF
{{< /text >}}

即使客户端 Pod 的身份正确，如果存在 L7 属性，也会导致 ztunnel 拒绝连接：

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## 引入 waypoint 时选择强制执行点 {#considerations}

当将 waypoint 代理添加到工作负载时，您现在有两个地方可以强制执行 L4 策略。
（L7 策略只能在 waypoint 代理处执行。）

仅使用安全覆盖时，流量会在目标 ztunnel 处以**源**工作负载的身份出现。

waypoint 代理不会伪装源工作负载的身份。一旦您将 waypoint 引入流量路径，
目标 ztunnel 将看到带有 **waypoint** 身份的流量，而不是源身份。

这意味着当您安装了 waypoint 时，**强制执行策略的理想位置发生了变化**。
即使您只希望针对 L4 属性强制执行策略，如果依赖于源身份，您也应该将策略附加到 waypoint 代理。
您可以针对目标工作负载设置第二个策略，以使其 ztunnel 强制执行这样的策略：
“网格内流量必须来自我的 waypoint 才能到达我的应用”。

## 对等身份验证 {#peer-authentication}

Istio 的 [对等身份验证策略](/zh/docs/concepts/security/#peer-authentication)，
用于配置双向 TLS（mTLS）模式，得到了 ztunnel 的支持。

Ambient 模式的默认策略是 `PERMISSIVE`，这允许 Pod 既接受来自网格内的 mTLS
加密流量，也接受来自外部的明文流量。启用 `STRICT` 模式意味着 Pod 只会接受 mTLS 加密流量。

由于 ztunnel 和 {{< gloss >}}HBONE{{< /gloss >}} 隐式使用 mTLS，
所以在策略中无法使用 `DISABLE` 模式。这类策略将被忽略。
