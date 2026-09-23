---
title: 开始之前
description: 验证您的环境并准备迁移。
weight: 1
owner: istio/wg-networking-maintainers
test: no
prev: /zh/docs/ambient/migrate
next: /zh/docs/ambient/migrate/install-ambient-components
---

在从 Sidecar 模式迁移至 Ambient 模式之前，
请验证您的环境是否满足要求，并对当前配置进行备份。

{{< warning >}}
**如果您的工作负载使用了 L7 策略，迁移过程将不那么直接，且目前存在已知的限制：**

- 在迁移过程中，存在一个时间窗口：在此期间，L7 策略可能无法得到执行；
  原有的基于选择器（selector-based）的策略必须被移除，
  并由新的基于 waypoint 的等效策略取而代之。这两种策略之间不存在原子性的切换交接。
- 当部分源工作负载仍处于 Sidecar 模式时，源自这些工作负载的流量将完全绕过 waypoint。
  对于此类流量路径，waypoint 上的 L7 策略将不会生效，直至相应的源工作负载也完成迁移为止。

**目前不支持利用 L7 策略实现零停机迁移。** 请规划维护窗口。
这是一项已知限制，我们已将其列入追踪列表，计划在未来的版本中予以改进。

如果您的工作负载仅使用 L4 级别的 `AuthorizationPolicy`
规则（即仅涉及源主体、命名空间或 IP 匹配，不涉及 HTTP 方法、路径或标头），
则本条规则不适用，且迁移过程无需对策略进行任何更改。
{{< /warning >}}

## 背景：政策执行方式的演变 {#background-how-policy-enforcement-changes}

理解 Sidecar 与 Ambient 策略执行之间的关键差异，将有助于您理解迁移步骤，并预判何处需要进行变更。

**在 Sidecar 模式下：**
- 策略通过 `selector`（选择器）利用标签来定位 Pod。
- 目标端 Sidecar 代理负责执行 L4 和 L7 策略。
- 单个 `AuthorizationPolicy` 即可基于源主体（Principal）、
  HTTP 方法、路径或请求头进行匹配，并在目标 Pod 上强制执行。

**在 Ambient 模式下：**
- L4 策略的执行由 **ztunnel** 负责，该组件运行在每一个节点上。
- L7 策略的执行需要为每个命名空间或服务部署一个 **waypoint 代理**。
- 由 waypoint 执行的策略必须使用 `targetRefs` 来指向 `Service` 或 `Gateway`，
  而不能使用 Pod 的 `selector`。因此，您无法直接原封不动地复用基于 `selector` 的 L7 策略。
- 在 Ambient 模式下，`VirtualService` 处于 Alpha 阶段。
  若要实现稳定的 L7 流量管理，必须迁移至 `HTTPRoute`。

## 要求 {#requirements}

- 一个[受支持的 Istio 版本](/zh/docs/releases/supported-releases/)
- Kubernetes [受支持的版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases) ({{< supported_kubernetes_versions >}})
- 已安装 Gateway API CRD（waypoint 代理所需）

如果您尚未安装 Gateway API CRD，请立即安装：

{{< boilerplate gateway-api-install-crds >}}

## 验证您当前的安装 {#verify-your-current-installation}

运行以下命令，以确认现有 Sidecar 安装的状态：

{{< text syntax=bash snip_id=none >}}
$ istioctl version
$ kubectl get pods -n istio-system
$ kubectl get namespaces -l istio-injection=enabled
{{< /text >}}

检查是否存在基于修订版本的安装（如果您使用的是 `istio.io/rev` 标签而非 `istio-injection`）：

{{< text syntax=bash snip_id=none >}}
$ kubectl get namespaces -l 'istio.io/rev'
{{< /text >}}

## 审计现有资源 {#audit-existing-resources}

列出集群中正在使用的 Istio 资源：

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,envoyfilter,wasmplugin -A
{{< /text >}}

检查哪些 `AuthorizationPolicy` 资源包含 L7 规则。
在 Ambient 模式下，这些资源需要 waypoint 代理才能正常工作。

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

请检查是否存在 `mode: DISABLE` 的 `PeerAuthentication` 资源，
这些资源与 Ambient 模式不兼容：

{{< text syntax=bash snip_id=none >}}
$ kubectl get peerauthentication -A -o yaml | grep -A2 "mtls:"
{{< /text >}}

在迁移之前，必须移除或修改任何包含 `mode: DISABLE`
的 `PeerAuthentication` 资源，因为 Ambient 模式始终在网格工作负载之间强制执行 mTLS。

配置了 `mode: STRICT` 或 `mode: PERMISSIVE` 的 `PeerAuthentication` 资源不会阻碍迁移，
但在迁移完成后，它们将变得冗余：Ambient 模式通过 ztunnel 强制执行 mTLS，
而无需依赖这些策略。您可以在迁移完成后安全地将其移除。

## 备份您的配置 {#back-up-your-configuration}

在进行任何更改之前，请导出当前的 Istio 配置：

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,gateway,httproute,telemetry -A -o yaml > istio-config-backup.yaml
$ kubectl get namespaces -o yaml > namespace-backup.yaml
{{< /text >}}

将这些备份存储在集群外部的安全位置。

## 设置流量监控（可选） {#set-up-traffic-monitoring-optional}

在进行更改之前，请使用 Kiali 或其他可观测性工具来捕获当前流量模式的基线。
有关设置说明，请参阅 [Kiali](/zh/docs/ops/integrations/kiali/)。

## 后续步骤 {#next-steps}

继续前往安装 Ambient 组件。
