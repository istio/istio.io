---
title: ServiceEntry 可见性
description: 控制哪些命名空间可以发现和解析各个 ServiceEntry。
weight: 40
keywords: [ambient,serviceentry,visibility]
owner: istio/wg-networking-maintainers
test: no
---

[`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/)
用于将服务添加到 Istio 的内部服务注册表中。默认情况下，`ServiceEntry`
对网格中的每个工作负载都可见：任何能够在**任何**命名空间中创建 `ServiceEntry`
的用户都可以定义**任何**主机名（例如 `example.com`），并影响整个网格如何解析和路由到该主机名。

[`exportTo`](/zh/docs/ops/configuration/mesh/configuration-scoping/)
字段无法防止这种情况，因为它是由 `ServiceEntry` 的作者自行声明的：
它允许服务所有者控制其发布内容的范围，但并未施加任何严格的限制。
以往，网格管理员需要使用外部准入控制（例如 Kubernetes 的 `ValidatingAdmissionPolicy` 或 Webhook）来限制 `ServiceEntry` 的创建。

从 Istio 1.31 开始，网格配置设置 [`serviceEntryVisibility`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)
允许网格管理员从单一位置进行控制。
{{< gloss >}}Ambient{{< /gloss >}} 数据平面（{{< gloss >}}ztunnel{{< /gloss >}} 和 {{< gloss "waypoint" >}}waypoints{{< /gloss >}}）在配置后会遵循可见性设置；
边车和网关可以[选择启用](#extending-visibility-to-sidecars-and-gateways)。
此功能默认处于非活动状态，除非进行配置：如果未设置 `serviceEntryVisibility`，则不会发生任何变化。

该设计刻意模仿了 Kubernetes 中常见的模式：`RoleBinding` 仅在其自身命名空间内生效，
而使用 `ClusterRoleBinding` 创建集群范围的效果则保留给集群管理员。
`serviceEntryVisibility` 允许网格管理员将相同的模型应用于 `ServiceEntry`：
通过设置 `defaultVisibility: NAMESPACE`，管理员可以使每个 `ServiceEntry`
的行为与其他命名空间范围内的资源相同，而超出 `ServiceEntry` 自身命名空间范围的可见性则成为管理员显式授予的权限。

## 如何解决可见性问题 {#how-visibility-is-resolved}

配置了 `serviceEntryVisibility` 之后，istiod 会为每个 `ServiceEntry` 解析一个可见性：

1. 按顺序评估 `policies` 列表。第一个所有 `matchingRules` 都匹配（AND 语义）的策略决定其可见性。
1. 如果没有匹配的策略，则应用 `defaultVisibility`。

目前唯一匹配的规则是 `namespaceSelector`：一个标准的 Kubernetes 标签选择器，
用于评估 **`ServiceEntry` 所在的命名空间**的标签。

{{< tip >}}
每个命名空间都会自动带有 `kubernetes.io/metadata.name` 标签，
因此 `namespaceSelector` 可以通过名称匹配命名空间。
{{< /tip >}}

`ServiceEntry` 解析为以下三种可见性之一：

| 可见性 | 意义 |
| --- | --- |
| `PUBLIC` | 连接到此控制平面的所有工作负载均可见。这是现有行为，也是未设置 `defaultVisibility` 时的默认行为。 |
| `NAMESPACE` | 仅在定义 `ServiceEntry` 的命名空间内可见。 |
| `NONE` | 对任何人都不可见：`ServiceEntry` 可以被写入，但 Istio 不会为其配置任何数据平面。明确禁止使用 `ServiceEntry` 类非常有用。 |

有关完整的字段文档，请参阅[网格配置参考](/zh/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)。

## 配置可见性 {#configure-visibility}

以下配置将每个 `ServiceEntry` 保持在自己的命名空间内私有，
同时允许将 `istio-system` 中的 `ServiceEntry` 资源（只有网格管理员才能写入该命名空间）发布到整个网格：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      # 未匹配以下任何策略的 ServiceEntry 将保留在它们自己的命名空间中。
      defaultVisibility: NAMESPACE
      policies:
        # istio 系统中的 ServiceEntry 在整个网格范围内可见。
        - visibility: PUBLIC
          matchingRules:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: istio-system
{{< /text >}}

策略还可以授予命名空间组的可见性。例如，匹配 `trusted: "true"`
命名空间标签的策略允许您通过标记命名空间来委派发布网格范围的 `ServiceEntry` 资源的权限。

## Ambient 模式下的可见性 {#visibility-in-ambient-mode}

配置了 `serviceEntryVisibility` 后，Ambient 数据平面始终遵循该设置。
istiod 会解析每个 `ServiceEntry` 的可见性，并将其与服务定义一起分发；
然后，ztunnel 会根据发出请求的工作负载的命名空间，在客户端应用该可见性：

* `PUBLIC` 服务的行为与之前完全相同。
* `NAMESPACE` 服务可以被其自身命名空间中的工作负载发现和解析。
  对于其他命名空间中的工作负载，就好像 `ServiceEntry` 不存在一样。
* `NONE` 服务永远不会被传递到任何数据平面。

### 隐藏是指不存在，而非被阻挡 {#hidden-means-absent-not-blocked}

{{< warning >}}
可见性设置会隐藏一个 `ServiceEntry`，但不会阻止流量。命名空间之外的客户端不会收到
`NXDOMAIN` 响应或连接拒绝——它们的行为与从未创建过 `ServiceEntry` 时完全相同。
{{< /warning >}}

这是有意为之：如果 ztunnel 对隐藏主机名的 DNS 查询失败，
那么在一个命名空间中声明 `example.com` 的 `ServiceEntry` 将会破坏整个网格中的
`example.com` —— 这正是此功能旨在控制的问题。具体来说，对于 `ServiceEntry` 命名空间之外的客户端：

* **DNS**：对隐藏主机名的查询会被转发到上游解析器，返回真实答案（如果该名称不存在，则返回真实的 `NXDOMAIN`）。
* **地址**：发往仅由隐藏的 `ServiceEntry` 声明的 IP 地址的流量将被视为未知流量，并转发到其原始目的地。
* **共享主机名**：如果隐藏的 `ServiceEntry` 和 `PUBLIC` 定义了相同的主机名，
  则隐藏条目命名空间之外的客户端始终由 `PUBLIC` 定义提供服务。

### Waypoint {#waypoints}

将来自其他命名空间的 waypoint 附加到具有 `NAMESPACE`
可见性的 `ServiceEntry` 会导致流量和配置超出命名空间边界，
因此控制平面会拒绝此类[跨命名空间 waypoint](/zh/docs/ambient/usage/waypoint/#usewaypointnamespace) 绑定。
此拒绝会在 `ServiceEntry` 状态中报告，条件为 `istio.io/WaypointBound: False`，
原因为 `CrossNamespaceWaypointForbidden`。

在**同一**命名空间中绑定路径点可以正常工作，并且 `PUBLIC` `ServiceEntry` 资源不受影响。

## 将可视范围扩展到边车和网关 {#extending-visibility-to-sidecars-and-gateways}

在 {{< gloss >}}sidecar{{< /gloss >}} 模式下，服务所有者已经使用 `exportTo` 来限定其 `ServiceEntry` 资源的范围，
因此 Sidecar 的可见性是可选的，允许在 Ambient 迁移期间逐步采用，而无需更改正在运行的 Sidecar 部署：

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    serviceEntryVisibility:
      defaultVisibility: NAMESPACE
      applyToSidecars: true
{{< /text >}}

启用 `applyToSidecars` 后，解析后的可见性将作为 `ServiceEntry` 的 `exportTo` 的上限：
有效范围是声明的 `exportTo` 和解析后的可见性的交集。尽管字段名称如此，
但这适用于所有基于 Envoy 的代理，包括入口网关和出口网关。

可见性可以缩小 `exportTo` 声明的范围，但绝不会扩大它。
在 Sidecar 模式下，`exportTo` 是一种[配置作用域](/zh/docs/ops/configuration/mesh/configuration-scoping/)机制，
用于控制 istiod 向每个代理发送的配置量。如果扩大其范围以匹配更广泛的可见性，
则会将 `ServiceEntry` 的配置推回其所有者已特意将其排除在外的代理中。
因此，可见性始终是一个上限：`exportTo` 小于其可见性的 `ServiceEntry` 将保持其较小的作用域。

{{< tip >}}
只有在启用 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)的情况下，
Sidecar 客户端才能路由到具有自动分配地址的 `ServiceEntry`。
在 Ambient 模式下，ztunnel 会自动提供此 DNS 处理。
{{< /tip >}}

## 验证可见性 {#verify-visibility}

配置 `serviceEntryVisibility` 时，istiod 会将数据平面接收到的可见性报告为类型为
`istio.io/VisibilityApplied` 的 `ServiceEntry` 状态条件，其中原因指示已应用的可见性：

{{< text syntax=bash >}}
$ kubectl get serviceentry my-service -n team-a -o jsonpath='{.status.conditions[?(@.type=="istio.io/VisibilityApplied")].reason}'
Namespace
{{< /text >}}

该条件的状态始终为 `True`；`reason` 字段包含已解析的可见性（`Public` 或 `Namespace`）。
如果未配置 `serviceEntryVisibility`，则不会写入该条件。

{{< warning >}}
目前，`NONE` `ServiceEntry` 完全不接收任何条件。
这是一个已知限制：请勿仅因缺少条件就断定可见性未生效。
{{< /warning >}}

您还可以检查 ztunnel 为其已知的每个服务应用的可见性设置。`istioctl ztunnel-config service`
命令的 JSON 和 YAML 输出中包含一个 `visibility` 字段：

{{< text syntax=bash >}}
$ istioctl ztunnel-config service --service-namespace team-a -o yaml
{{< /text >}}

Kubernetes 的 `Service` 始终报告为 `Public`；由 `ServiceEntry` 支持的 Service
会报告其解析后的可见性。此外，ztunnel 会在解析过程中，
每当对客户端隐藏某个 Service 时，都会以 `debug` 级别记录日志。

## 可见性不能做什么 {#what-visibility-does-not-do}

* **可见性不等同于授权。**可见性控制客户端是否可以**发现并解析**服务；它并不决定是否允许入站请求。
  使用 [`AuthorizationPolicy`](/zh/docs/reference/config/security/authorization-policy/)
  来控制哪些客户端可以访问工作负载——请参阅[四层安全策略](/zh/docs/ambient/usage/l4-policy/)。
* **可见性不等同于保密。**降低 `ServiceEntry` 的可见性控制哪些客户端工作负载可以解析；
  它不会隐藏服务的存在。根据 RBAC，该资源仍然可以通过 Kubernetes API 读取，
  并且该服务仍然会出现在数据平面配置转储中，例如 `istioctl ztunnel-config service`。
* **仅适用于 `ServiceEntry`。**在 Ambient 模式下，Kubernetes `Service` 始终在整个网格范围内可见。
* **没有审计模式或仅警告模式。**配置后，可见性始终生效。

## 参见 {#see-also}

* [`ServiceEntryVisibility` 网格配置参考](/zh/docs/reference/config/istio.mesh.v1alpha1/#ServiceEntryVisibility)
* [配置作用域](/zh/docs/ops/configuration/mesh/configuration-scoping/) — Sidecar 模式下的 `exportTo` 和 `Sidecar`，以及适用于所有数据平面模式的 `discoverySelectors`
* [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)
* [配置 waypoint 代理](/zh/docs/ambient/usage/waypoint/)
