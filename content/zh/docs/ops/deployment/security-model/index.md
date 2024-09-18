---
title: 安全模型
description: 描述 Istio 的安全模型。
weight: 10
owner: istio/wg-security-maintainers
test: n/a
---

本文档旨在描述 Istio 各个组件的安全态势，以及可能的攻击如何影响系统。

## 组件 {#components}

Istio 附带各种可选组件，本文将介绍这些组件。有关高级概述，
请参阅 [Istio 架构](/zh/docs/ops/deployment/architecture/)。
请注意，Istio 部署非常灵活；下面，我们将主要假设最坏的情况。

### Istiod {#istiod}

Istiod 是 Istio 的核心控制平面组件，
通常充当 [XDS 服务组件](/zh/docs/concepts/traffic-management/)以及网格
[mTLS 证书颁发机构](/zh/docs/concepts/security/)的角色。

Istiod 被视为高权限组件，类似于 Kubernetes API 服务器本身。

* 它具有较高的 Kubernetes RBAC 权限，通常包括 `Secret` 读取权限和 Webhook 写入权限。
* 当充当 CA 时，它可以提供任意证书。
* 当充当 XDS 控制平面时，它可以对代理进行编程以执行任意行为。

因此，集群的安全性与 Istiod 的安全性紧密相关。遵循有关 Istiod 访问的
[Kubernetes 安全最佳实践](https://kubernetes.io/zh-cn/docs/concepts/security/)至关重要。

### Istio CNI 插件 {#istio-cni-plugin}

Istio 可以选择性地与 [Istio CNI 插件 `DaemonSet`](/zh/docs/setup/additional-setup/cni/) 一起部署。
此 `DaemonSet` 负责在 Istio 中设置网络规则，以确保根据需要透明地重定向流量。
这是[下文](#sidecar-proxies)讨论的 `istio-init` 容器的替代方案。

由于 CNI `DaemonSet` 会修改节点上的网络规则，因此它需要提升的 `securityContext`。
但是，与 [Istiod](#istiod) 不同，这是一种 **node-local** 权限。
此权限的含义将在[下文](#node-compromise)中讨论。

因为这将设置网络所需的提升权限整合到单个 Pod 中，而不是**每个** Pod，所以通常建议使用此选项。

### Sidecar 代理 {#sidecar-proxies}

Istio 可以[可选的](/zh/docs/overview/dataplane-modes/)在应用程序旁边部署一个 Sidecar 代理。

Sidecar 代理需要对网络进行编程，以引导所有流量通过代理。
这可以通过 [Istio CNI 插件](#istio-cni-plugin)或在 Pod 上部署 `initContainer`（`istio-init`）来实现（如果未部署 CNI 插件，则会自动完成）。
`istio-init` 容器需要 `NET_ADMIN` 和 `NET_RAW` 功能。
但是，这些功能仅在初始化期间存在 - 主 Sidecar 容器完全没有特权。

此外，Sidecar 代理根本不需要任何相关的 Kubernetes RBAC 权限。

每个 Sidecar 代理都被授权为相关的 Pod 服务账户请求证书。

### Gateway 和 waypoint {#gateways-and-waypoints}

{{< gloss "gateway" >}}Gateway{{< /gloss >}} 和
{{< gloss "waypoint">}}waypoint{{< /gloss >}}
充当独立代理部署。与 [Sidecar](#sidecar-proxies) 不同，它们不需要任何网络修改，因此不需要任何权限。

这些组件使用自己的服务账户运行，与应用程序身份不同。

### ztunnel {#ztunnel}

{{< gloss "ztunnel" >}}ztunnel{{< /gloss >}} 充当节点级代理。
此任务需要 `NET_ADMIN`、`SYS_ADMIN` 和 `NET_RAW` 功能。
与 [Istio CNI 插件](#istio-cni-plugin) 一样，这些只是**节点本地**权限。
ztunnel 没有任何关联的 Kubernetes RBAC 权限。

ztunnel 有权为在同一节点上运行的 Pod 的任何服务帐户请求证书。
与 [kubelet](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/node/) 类似，
这明确不允许请求任意证书。这再次确保这些权限仅限于**节点本地**。

## 流量捕获属性 {#traffic-capture-properties}

当 Pod 注册到网格中时，所有传入的 TCP 流量都将重定向到代理。
这包括 mTLS/{{< gloss >}}HBONE{{< /gloss >}} 流量和明文流量。
在将流量转发到工作负载之前，将强制执行适用于工作负载的任何[策略](/zh/docs/tasks/security/authorization/)。

但是，Istio 目前无法保证将**传出**流量重定向到代理。
请参阅[流量捕获限制](/zh/docs/ops/best-practices/security/#understand-traffic-capture-limitations)。
因此，如果需要出站策略，则必须小心遵循[保护出口流量](/zh/docs/ops/best-practices/security/#securing-egress-traffic)步骤。

## 双向 TLS 属性 {#mutual-tls-properties}

[双向 TLS](/zh/docs/concepts/security/#mutual-tls-authentication)
为 Istio 的大部分安全态势提供了基础。下面介绍了双向 TLS 为 Istio 的安全态势提供的各种属性。

### 证书颁发机构 {#certificate-authority}

Istio 有自己的证书颁发机构（CA）。

默认情况下，CA 允许根据以下任一选项对客户端进行身份验证：

* Kubernetes JWT 令牌，受众为 `istio-ca`，使用 Kubernetes `TokenReview` 进行验证。
  这是 Kubernetes Pod 中的默认方法。
* 现有的双向 TLS 证书。
* 自定义 JWT 令牌，使用 OIDC 进行验证（需要配置）。

CA 只会颁发针对客户端已验证身份而请求的证书。

Istio 还可以与各种第三方 CA 集成；有关其行为方式的更多信息，请参阅其安全文档。

### 客户端 mTLS {#client-mtls}

{{< tabset category-name="dataplane" >}}
{{< tab name="Sidecar 模式" category-value="sidecar" >}}
在 Sidecar 模式下，客户端 Sidecar 在连接到检测到支持
mTLS 的服务时将[自动使用 TLS](/zh/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls)。
这也可以[显式配置](/zh/docs/ops/configuration/traffic-management/tls-configuration/#sidecars)。
请注意，此自动检测依赖于 Istio 将流量与服务关联。
[不支持的流量类型](/zh/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic)或[配置范围](/zh/docs/ops/configuration/mesh/configuration-scoping/)可能会阻止这种情况。

当[连接到后端](/zh/docs/concepts/security/#secure-naming)时，
允许的身份集是在服务级别基于所有后端身份的联合来计算的。
{{< /tab >}}

{{< tab name="Ambient 模式" category-value="ambient" >}}
在 Ambient 模式下，Istio 将在连接到任何支持 mTLS 的后端时自动使用 mTLS，
并验证目标的身份是否与预期运行工作负载的身份相匹配。

这些属性与 Sidecar 模式的不同之处在于，它们是单个工作负载的属性，而不是服务的属性。
这样可以实现更细粒度的身份验证检查，并支持更多种类的工作负载。
{{< /tab >}}
{{< /tabset >}}

### 服务器 mTLS {#server-mtls}

默认情况下，Istio 将接受 mTLS 和非 mTLS 流量（通常称为“宽容模式”）。
用户可以通过编写需要 mTLS 的 `PeerAuthentication` 或 `AuthorizationPolicy` 规则来选择严格执行。

建立 mTLS 连接后，将验证对等证书。此外，还将验证对等身份是否在同一信任域内。
要验证仅允许特定身份，可以使用 `AuthorizationPolicy`。

## 探索妥协类型 {#compromise-types-explored}

基于以上概述，我们将考虑系统各个部分受到攻击时对集群的影响。
在现实世界中，任何安全攻击都存在各种不同的变量：

* 执行起来有多容易
* 需要哪些先前权限
* 被利用的频率
* 影响是什么（完全远程执行、拒绝服务等）。

在本文中，我们将主要考虑最坏的情况：组件被破坏意味着攻击者拥有完整的远程代码执行能力。

### 工作负载妥协 {#workload-compromise}

在这种情况下，应用程序工作负载（Pod）受到影响。

Pod [**可能**有权访问其服务帐户令牌](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#opt-out-of-api-credential-automounting)。
如果是这样，工作负载入侵可能会从单个 Pod 横向扩展到入侵整个服务帐户。

{{< tabset category-name="dataplane" >}}
{{< tab name="Sidecar 模式" category-value="sidecar" >}}
在 Sidecar 模型中，代理与 Pod 位于同一位置，并在同一信任边界内运行。
被入侵的应用程序可以通过管理 API 或其他界面篡改代理，包括泄露私钥材料，
从而允许另一个代理冒充工作负载。应该假设被入侵的工作负载还包括对 Sidecar 代理的入侵。

鉴于此，受损的工作负载可能会：

* 发送任意流量，无论是否使用双向 TLS。这些流量可能会绕过任何代理配置，
  甚至完全绕过代理。请注意，Istio 不提供基于出口的授权策略，因此不会发生出口授权策略绕过。
* 接受已经发往应用程序的流量。它可能会绕过在 Sidecar 代理中配置的策略。

这里的关键点是，虽然受损的工作负载可能表现恶意，但这并不意味着它们能够绕过其他工作负载中的策略。
{{< /tab >}}

{{< tab name="Ambient 模式" category-value="ambient" >}}
在 Ambient 模式下，节点代理不与 Pod 位于同一位置，而是作为独立 Pod 的一部分在另一个信任边界中运行。

受感染的应用程序可能会发送任意流量。但是，它们无法控制节点代理，而节点代理将选择如何处理传入和传出流量。

此外，由于 Pod 本身无法访问服务帐户令牌来请求相互 TLS 证书，因此横向移动的可能性降低了。
{{< /tab >}}
{{< /tabset >}}

Istio 提供了多种功能来限制此类攻击的影响：

* [可观察性](/zh/docs/tasks/observability/)功能可用于识别攻击。
* [策略](/zh/docs/tasks/security/authorization/)可用于限制工作负载可以发送或接收的流量类型。

### 代理妥协 - Sidecars {#proxy-compromise---sidecars}

在此场景中，Sidecar 代理被攻陷。由于 Sidecar 和应用程序位于同一信任域中，
因此这在功能上等同于[工作负载攻陷](#workload-compromise)。

### 代理妥协 - Waypoint {#proxy-compromise---waypoint}

在这种情况下，[waypoint 代理](#gateways-and-waypoints)受到攻击。
虽然 waypoint 没有任何可供黑客利用的权限，但它们确实（可能）提供许多不同的服务和工作负载。
受到攻击的 waypoint 将接收这些服务和工作负载的所有流量，并可以查看、修改或丢弃这些流量。

Istio 提供了[配置 waypoint 部署粒度](/zh/docs/ambient/usage/waypoint/#useawaypoint)的灵活性。
如果用户需要更强的隔离性，可以考虑部署更多隔离 waypoint。

由于 waypoint 运行时具有与其所服务的应用程序不同的身份，因此受损的 waypoint 并不意味着可以模仿用户的应用程序。

### 代理妥协 - ztunnel {#proxy-compromise---ztunnel}

在这种情况下，[ztunnel](#ztunnel) 代理受到了损害。

受损的 ztunnel 会让攻击者控制节点的网络。

ztunnel 可以访问在其节点上运行的每个应用程序的私钥材料。
被入侵的 ztunnel 可能会泄露这些材料并在其他地方使用。但是，无法横向移动到共置工作负载之外的身份；
每个 ztunnel 仅被授权访问在其节点上运行的工作负载的证书，从而确定被入侵的 ztunnel 的受影响范围。

### 节点妥协 {#node-compromise}

在此场景中，Kubernetes 节点受到攻击。
[Kubernetes](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/node/)
和 Istio 都旨在限制单个节点攻击的影响半径，
这样单个节点的攻击不会导致[集群范围的攻击](#cluster-api-server-compromise)。

但是，该攻击确实可以完全控制该节点上运行的所有工作负载。
例如，它可以破坏任何同地 [waypoint](#proxy-compromise---waypoint)、
本地 [ztunnel](#proxy-compromise---ztunnel)、
任何 [Sidecar](#proxy-compromise---sidecars)、
任何同地 [Istiod 实例](#istiod-compromise)等。

### 集群（API 服务器）受损 {#cluster-api-server-compromise}

Kubernetes API 服务器被攻陷实际上意味着整个集群和网格都被攻陷。
与大多数其他攻击媒介不同，Istio 无法控制此类攻击的受影响范围。
被攻陷的 API 服务器让黑客可以完全控制集群，包括在任意 Pod 中运行 `kubectl exec`、
删除任何 Istio `AuthorizationPolicies` 甚至完全卸载 Istio 等操作。

### Istiod 妥协 {#istiod-compromise}

Istiod 被攻陷通常会导致与 [API 服务器被攻陷](#cluster-api-server-compromise)相同的结果。
Istiod 是一个高权限组件，应受到强力保护。
遵循[安全最佳实践](/zh/docs/ops/best-practices/security)对于维护安全集群至关重要。
