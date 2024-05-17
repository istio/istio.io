---
title: 使用 Layer 4 安全策略
description: 仅使用 L4 安全覆盖时支持的安全功能。
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

在 Istio Ambient 模式中，{{< gloss >}}ztunnel{{< /gloss >}} 和
{{< gloss >}}waypoint{{< /gloss >}} 代理采用分层机制，
让您可以选择是否希望为给定的工作负载启用 Layer 7（L7）进行处理。

Istio [安全策略](/zh/docs/concepts/security)的 Layer 4（L4）功能得到了 ztunnel 的支持，
并且可用于 Ambient 模式。如果您的集群具有支持这些功能的 {{< gloss "cni" >}}CNI{{< /gloss >}} 插件，
那 [Kubernetes 网络策略](https://kubernetes.io/zh-cn/docs/concepts/services-networking/network-policies/)也可以继续发挥作用，
可用于提供深度防护。

要使用 L7 策略和 Istio 的流量路由功能，
您可以为您的工作负载[部署一个 waypoint](/zh/docs/ambient/usage/waypoint)。

## Layer 4 鉴权策略 {#layer-4-authorization-policies}

当工作负载在安全覆盖模式下注册时，ztunnel 代理会实施鉴权策略。

实际的执行点位于连接路径中的接收（服务端）ztunnel 代理的位置。

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
EOF
{{< /text >}}

L4 `AuthorizationPolicy` API 在 Istio Ambient
模式下与 Sidecar 模式下具有相同的功能行为。当没有配置 `AuthorizationPolicy` 时，
默认操作是 `ALLOW`。在配置策略后，与策略中的选择器匹配的 Pod 仅允许明确允许的流量。
在此示例中，带有 `app: httpbin` 标签的 Pod 仅允许来自身份主体为
`cluster.local/ns/ambient-demo/sa/sleep` 源的流量。
来自所有其他来源的流量将被拒绝。

### 未安装 waypoint 的 Layer 7 鉴权策略 {#layer-7-authorization-policies-without=waypoints-installed}

{{< warning >}}
如果配置的 `AuthorizationPolicy` 需要 L4 之外的任何流量处理，
并且没有为流量的目标配置 waypoint 代理，则 ztunnel 代理将简单地丢弃所有流量作为防护措施。
因此，请检查以确保所有规则仅涉及 L4 处理，否则如果非 L4 规则不可避免，则配置 waypoint 代理。
{{< /warning >}}

此示例添加了对 HTTP GET 方法的检查：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
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

即使 Pod 的身份在其他方面是正确的，
L7 策略的存在以及并非源自 waypoint 代理的流量也会导致 ztunnel 拒绝连接：

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## 对等身份验证 {#peer-authentication}

ztunnel 支持配置双向 TLS（mTLS）模式的 Istio
[对等身份验证策略](/zh/docs/concepts/security/#peer-authentication)。

由于 ztunnel 和 {{< gloss >}}HBONE{{< /gloss >}} 中隐式使用了 mTLS，
因此无法在策略中使用 `DISABLE` 模式。此类策略将被忽视。

如果您需要禁用整个命名空间的 mTLS，则必须禁用 Ambient 模式：

{{< text bash >}}
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}
