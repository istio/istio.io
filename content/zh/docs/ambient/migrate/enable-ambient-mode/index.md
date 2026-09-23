---
title: 启用 Ambient 模式
description: 标记命名空间、激活 waypoint、移除 Sidecar 注入，并验证迁移。
weight: 4
owner: istio/wg-networking-maintainers
test: no
prev: /zh/docs/ambient/migrate/migrate-policies
---

逐个命名空间启用 Ambient 模式。这使您能够在继续操作之前对每个命名空间进行验证，
并在出现问题时回滚单个命名空间。

{{< warning >}}
**如果您配置了 L7 策略，目前尚无支持零停机迁移的路径。**
在过渡期间，Sidecar 客户端将完全绕过 waypoint；因此，
对于源自 Sidecar 的流量，附着在 waypoint 上的 L7 策略将无法生效。
此外，基于旧式选择器（Selector）的 L7 策略必须在 Pod 重启时被移除，
并替换为基于 waypoint 的等效策略——在这两项操作之间存在一个短暂的时间窗口，
期间 L7 规则将处于未执行状态。这是一个已知的缺陷。如果您要求 L7 策略必须持续生效，
请务必规划相应的维护窗口。这一缺陷属于已知的局限性，我们已将其列入追踪列表，
并计划在未来的版本中加以改进。
{{< /warning >}}

## 迁移命名空间 {#migrating-a-namespace}

### 顺序要求 {#ordering-requirements}

{{< warning >}}
此步骤的操作顺序至关重要。请严格按照以下顺序执行：

1. 在启用 Ambient 模式**之前**激活 waypoint。
1. 启用 Ambient 模式（标记命名空间）。
1. 在确认 Ambient 模式正常工作**之后**移除 Sidecar 注入。
1. **最后**重启 Pod。
{{< /warning >}}

Failing to follow this sequence can result in traffic being processed by neither sidecar nor ztunnel, causing disruption in your workloads.
若未能遵循此顺序，可能导致流量既未被 Sidecar 处理，
也未被 ztunnel 处理，从而引发工作负载中断。

### 步骤 1：激活 waypoint {#step-1-activate-waypoints}

{{< tip >}}
如果您不使用 waypoint，请跳过此步骤。
{{< /tip >}}

通过添加 `istio.io/use-waypoint` 标签，激活在上一步中部署的 waypoint。

若要为整个命名空间激活 waypoint：

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

若仅为特定服务激活 waypoint：

{{< text syntax=bash snip_id=none >}}
$ kubectl label service <service-name> -n <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

验证 waypoint 是否就绪：

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
{{< /text >}}

`READY` 列应显示为 `True`。

### 步骤 2：为命名空间启用 Ambient 模式 {#step-2-enable-ambient-mode-for-the-namespace}

为该命名空间添加 `istio.io/dataplane-mode=ambient` 标签。
这会告知 CNI 插件，该命名空间内新建及重启的 Pod 应使用 ztunnel，
而非（或同时）使用 Sidecar：

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/dataplane-mode=ambient
{{< /text >}}

验证该命名空间现已加入 Ambient 网格：

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

该命名空间下的工作负载将显示以 `HBONE` 作为其协议。
此时，Pod 仍保留其 Sidecar。对于同时拥有 Sidecar 和 ztunnel 的 Pod，Sidecar 具有优先权。

### 步骤 3：移除 Sidecar 注入 {#step-3-remove-sidecar-injection}

从命名空间中移除 Sidecar 注入标签：

如果您使用默认注入标签：

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio-injection-
{{< /text >}}

如果您使用修订标签：

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/rev-
{{< /text >}}

{{< warning >}}
仅移除注入标签并不能移除现有的 Sidecar。必须重启 Pod，更改才会生效。
请勿在确认 Ambient 模式已激活（即上述第 2 步）之前重启 Pod。
{{< /warning >}}

### 步骤 4：重启 Pod {#step-4-restart-pods}

重启该命名空间下的工作负载。随着 Pod 重启，它们将不再包含 Sidecar 容器，
转而使用 ztunnel（若已配置，还将使用 waypoint）：

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

### 步骤 5：移除旧的 Sidecar 策略 {#step-5-remove-old-sidecar-policies}

{{< warning >}}
请在 Pod 重启后立即执行此操作，且须在运行任何验证之前完成。
一旦 Sidecar 被移除，ztunnel 便会接管策略执行工作。
ztunnel 仅能识别 L4 属性，并会默默忽略 `AuthorizationPolicy`
规则中包含的任何 L7 条件（如 HTTP 方法、路径、标头及请求主体）。
其具体效果取决于策略所指定的动作：

- **包含 L7 规则的 `ALLOW` 策略**：ztunnel 会忽略其中的 L7 条件。
  如果策略中的所有规则均仅依赖于 L7 属性，则最终生成的策略将不包含任何规则，
  从而无法匹配任何流量；这将导致 ztunnel **拒绝流向该工作负载的所有流量**
  （因为一条不含任何匹配规则的 `ALLOW` 策略实际上不放行任何流量）。
- **包含 L7 规则的 `DENY` 策略**：ztunnel 会丢弃其中的 L7 条件。
  如果某条规则原本就不包含 L4 条件（例如，仅基于请求主体或 HTTP 路径进行匹配），
  那么在移除 L7 部分后，剩余的匹配条件将变为空集，从而匹配所有流量——这实际上相当于**拒绝了流向该工作负载的所有流量**。

在这两种情况下，若在移除 Sidecar 后仍保留基于选择器的旧 L7 策略处于激活状态，
将会导致流量受阻。请立即将其删除。
{{< /warning >}}

请删除所有使用了包含 L7 规则的负载工作流 `selector` 的 `AuthorizationPolicy` 资源，
因为它们现已被基于 `targetRefs` 的等效资源所取代。

{{< text syntax=bash snip_id=none >}}
$ kubectl delete authorizationpolicy <sidecar-policy-name> -n <namespace>
{{< /text >}}

Also remove `VirtualService` and `DestinationRule` resources replaced by `HTTPRoute`:
此外，请移除已被 `HTTPRoute` 替换的 `VirtualService` 和 `DestinationRule` 资源：

{{< text syntax=bash snip_id=none >}}
$ kubectl delete virtualservice <name> -n <namespace>
$ kubectl delete destinationrule <name> -n <namespace>
{{< /text >}}

使用 `selector` 的 L4 `AuthorizationPolicy` 资源（不含 L7 规则）可安全保留，
ztunnel 能够正确地对其进行强制执行。

### 步骤 6：验证 {#step-6-validate}

验证 Pod 正在运行且不包含 Sidecar 容器：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n <namespace>
{{< /text >}}

确认 ztunnel 正在管理工作负载：

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

如果您已部署 waypoint，请通过测试您的 `HTTPRoute` 和 `AuthorizationPolicy`
资源所定义的特定行为（例如基于标头的路由、HTTP 方法限制等），
来验证 L7 策略和路由规则是否正在生效。

## 对每个命名空间重复此操作 {#repeat-for-each-namespace}

针对您想要迁移的每个命名空间，重复执行[迁移命名空间](#migrating-a-namespace)中的步骤。
未标记 `istio.io/dataplane-mode=ambient` 的命名空间将继续使用其 Sidecar，且不受影响。

## 回滚 {#rollback}

每个步骤均可独立撤销。请根据您已完成的进度，执行相应的回滚操作：

| 步骤 | 回滚操作 |
|---|---|
| 完成步骤 1 后（waypoint 已激活） | `kubectl label namespace <ns> istio.io/use-waypoint-` |
| 完成步骤 2 后（已启用 Ambient 模式） | `kubectl label namespace <ns> istio.io/dataplane-mode-` |
| 完成步骤 3 后（注射已移除） | 重新添加注入标签：`kubectl label namespace <ns> istio-injection=enabled` |
| 完成步骤 4 后（Pod 已重启） | 重新添加注入标签，然后执行 `kubectl rollout restart deployment -n <ns>` |
| 完成步骤 5 后（旧策略已删除） | 运行 `kubectl apply -f istio-config-backup.yaml` 从备份进行恢复。 |

在执行任何涉及 Pod 重启的回滚操作后，请验证 Pod 状态是否显示为 2/2 容器
（表明 Sidecar 已被重新注入），并在继续操作前确认流量传输正常。

{{< warning >}}
在完成第 5 步后，若使用 `kubectl apply -f istio-config-backup.yaml` 执行回滚操作，
虽然能够恢复原有的 Sidecar 风格资源，但同时也会**覆盖**迁移过程中创建的、
且名称相同的**所有新增 Ambient 风格资源**（例如 `HTTPRoute`
规则以及基于 `targetRefs` 的 `AuthorizationPolicy` 资源）。
因此，在应用备份文件之前，请务必先删除这些 Ambient 资源；
或者，建议针对单个资源执行选择性的 `kubectl apply` 操作，而非直接应用完整的备份文件。
{{< /warning >}}

## 迁移后的可观测性变更 {#post-migration-observability-changes}

迁移至 Ambient 模式后，请留意遥测方面的以下变更：

**指标**：在 Sidecar 模式下，指标通过 `reporter="source"` 和 `reporter="destination"` 进行上报。
在 Ambient 模式下，来自 ztunnel 的指标使用 `reporter="source"`，
而来自 waypoint 代理的指标使用 `reporter="waypoint"`。
请更新所有依赖于 `reporter` 标签的仪表板或告警规则。

**指标合并**：在 Sidecar 模式下，代理代理（proxy agent）支持[指标合并](/zh/docs/ops/integrations/prometheus/#option-1-metrics-merging)功能，
该功能利用标准的 `prometheus.io` 注解，将 Istio 指标与应用程序指标合并为一个抓取目标。
此功能在 Ambient 模式下不可用。迁移后，您必须将 Prometheus 配置为分别抓取
Istio 组件（ztunnel 和 waypoint Pod）以及您的应用程序 Pod，
将其作为独立的目标进行处理。请更新所有依赖于单一合并端点的 `PodMonitor` 或 `ServiceMonitor` 资源。

**链路追踪**：在 Sidecar 模式下，每一跳（hop）会生成两个 Span（一个来自源端 Sidecar，
一个来自目标端 Sidecar）。在带有 waypoint 的 Ambient 模式下，
每个 waypoint 生成一个 Span。请据此相应地更新基于追踪的 SLO。

**`istioctl proxy-status`**：此命令不显示 ztunnel 工作负载。
请改用 `istioctl ztunnel-config workloads` 来检查 Ambient 代理状态。

欲了解更多信息，请参阅：

- [Troubleshooting ztunnel](/zh/docs/ambient/usage/troubleshoot-ztunnel/)
- [Troubleshooting waypoints](/zh/docs/ambient/usage/troubleshoot-waypoint/)
