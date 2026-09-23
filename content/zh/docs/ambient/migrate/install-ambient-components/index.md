---
title: 安装 Ambient 组件
description: 添加 ztunnel 并更新 CNI，以在现有 Sidecar 的基础上支持 Ambient 模式。
weight: 2
owner: istio/wg-networking-maintainers
test: no
prev: /zh/docs/ambient/migrate/before-you-begin
next: /zh/docs/ambient/migrate/migrate-policies
---

此步骤会将您的 Istio 安装升级，以包含 Ambient 数据平面组件（ztunnel 和更新后的 CNI），
同时保持所有现有的 Sidecar 工作负载不变。在此步骤的整个过程中，您的 Sidecar 将继续正常处理流量。

{{< warning >}}
在完成[启用 Ambient 模式](/zh/docs/ambient/migrate/enable-ambient-mode/)步骤之前，
请勿移除 Sidecar 注入，也不要向任何命名空间添加 `istio.io/dataplane-mode=ambient` 标签。
{{< /warning >}}

## 升级至 Ambient 模式 {#upgrade-to-the-ambient-profile}

### 使用 istioctl {#using-istioctl}

将您现有的 Istio 安装升级为使用 `ambient` 配置文件。
此操作将添加 ztunnel DaemonSet，并更新 CNI 插件以支持 Ambient 模式：

{{< text syntax=bash snip_id=none >}}
$ istioctl upgrade --set profile=ambient
{{< /text >}}

{{< tip >}}
如果您是使用自定义的 `IstioOperator` 或 `--set` 标志安装 Istio 的，
可以将它们与 ambient 配置文件结合使用。例如：`istioctl upgrade --set profile=ambient --set values.pilot.resources.requests.cpu=500m`
{{< /tip >}}

### 使用 Helm {#using-helm}

如果您是使用 Helm 安装的 Istio，请升级每个组件以添加 Ambient 支持：

{{< text syntax=bash snip_id=none >}}
$ helm upgrade istio-base istio/base -n istio-system
$ helm upgrade istiod istio/istiod -n istio-system --set profile=ambient
$ helm upgrade istio-cni istio/cni -n istio-system --set profile=ambient
$ helm install ztunnel istio/ztunnel -n istio-system  # new component, not previously installed
{{< /text >}}

## 验证 Ambient 组件 {#verify-the-ambient-components}

升级完成后，请验证 ztunnel 和已更新的 CNI 正在运行：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n istio-system
{{< /text >}}

除了现有的 Istiod 和 CNI Pod 之外，您应该还能看到 `ztunnel` DaemonSet Pod 正在每个节点上运行：

{{< text syntax=plain snip_id=none >}}
NAME                                   READY   STATUS    RESTARTS   AGE
istio-cni-node-...                     1/1     Running   0          2m
istiod-...                             1/1     Running   0          2m
ztunnel-...                            1/1     Running   0          2m
{{< /text >}}

确认 ztunnel 正在所有节点上作为 DaemonSet 运行：

{{< text syntax=bash snip_id=none >}}
$ kubectl get daemonset ztunnel -n istio-system
{{< /text >}}

## 在现有 Sidecar 中启用 HBONE 支持 {#enable-hbone-support-in-existing-sidecars}

Sidecar 代理需要重启，以便加载 Ambient 配置文件在 `MeshConfig`
中设置的新的 `ISTIO_META_ENABLE_HBONE=true` 配置。
此举使 Sidecar 能够利用 HBONE 协议与 Ambient 模式下的工作负载进行通信。

重启每个已启用 Sidecar 注入的命名空间，或者根据您的部署策略重启各个工作负载。
例如，若要重启某个命名空间：

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

对每个包含已注入 Sidecar 的工作负载的命名空间重复此操作。

若要验证重启后的 Pod 上 HBONE 支持是否已启用：

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod <pod-name> -n <namespace> -o json | \
    jq '.spec.initContainers[] | select(.name=="istio-proxy") | .env[] | select(.name=="ISTIO_META_ENABLE_HBONE")'
{{< /text >}}

输出应显示：

{{< text syntax=json snip_id=none >}}
{
  "name": "ISTIO_META_ENABLE_HBONE",
  "value": "true"
}
{{< /text >}}

{{< tip >}}
在此阶段重启 Pod 对流量没有可观测的影响。HBONE 仅在目标为
Ambient 模式工作负载时才会激活，而目前尚无命名空间已完成注册。
{{< /tip >}}

## 迁移过程中的 Sidecar 与 Ambient 互操作性 {#sidecar-and-ambient-interoperability-during-migration}

当注入了 Sidecar 的 Pod 与已迁移至 Ambient 模式的工作负载进行通信时，
该 Sidecar 会利用 HBONE 协议，将流量直接隧道传输至目标 Pod 的 ztunnel。

实际后果是，在迁移期间，针对来自 Sidecar 模式工作负载的流量，
waypoint 上配置的 L7 策略（例如 `HTTPRoute` 规则或包含 `targetRefs` 的 `AuthorizationPolicy`）将**不予执行**。
Sidecar 会在发送流量前应用其自身的 L7 逻辑，而 waypoint 则完全不会对这部分流量进行路由。
这意味着 L7 策略不会被重复应用，因为 Sidecar 已经自行处理了路由决策，
且 HBONE 隧道会将流量直接交付至目的地，无需在 waypoint 处再次进行处理。

{{< warning >}}
如果您启用了航点绕行防范策略（即一种 DENY 策略，用于拒绝并非源自航点的流量），
该策略也将拒绝来自 Sidecar 模式工作负载的流量，因为这些工作负载绕过了航点。
关于在增量迁移过程中如何处理此问题，请参阅防止 waypoint 绕行。
{{< /warning >}}

## 部署 waypoint 代理（可选） {#deploy-waypoint-proxies-optional}

{{< tip >}}
如果您仅需要 L4 mTLS 和授权策略，请跳过本节。
仅在使用 L7 功能时才需要 waypoint。请参阅迁移策略以确定您是否需要它们。
{{< /tip >}}

对于需要 L7 功能的命名空间，请立即部署 waypoint 代理。
该 waypoint 将处于已配置状态，但**尚未激活**；流量将继续流经 Sidecar。

使用 `istioctl` 部署命名空间范围的 waypoint：

{{< text syntax=bash snip_id=none >}}
$ istioctl waypoint apply -n <namespace>
{{< /text >}}

验证 waypoint Pod 正在运行：

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
$ kubectl get pods -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller
{{< /text >}}

{{< warning >}}
**请勿**在此时向任何命名空间或服务添加 `istio.io/use-waypoint` 标签。
如果在移除 Sidecar 之前激活 waypoint，可能会导致流量被重复处理。
请等到启用 Ambient 模式这一步再进行操作。
{{< /warning >}}

有关航点配置选项（服务级、工作负载级或跨命名空间航点）的更多详细信息，
请参阅[使用 waypoint 代理](/zh/docs/ambient/usage/waypoint/)。

## 后续步骤 {#next-steps}

请继续前往迁移策略，以更新适用于 Ambient 模式的流量和授权策略。

如果您没有 `VirtualService` 或 `DestinationRule` 资源，
且您的 `AuthorizationPolicy` 资源仅使用 L4 规则（不包含 HTTP 方法、路径或标头匹配），
请跳过本页，直接前往启用 Ambient 模式。
