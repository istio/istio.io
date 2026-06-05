---
title: 升级说明
description: 升级到 Istio 1.30.0 时要考虑的重要变更。
weight: 20
---

当您从 Istio 1.29.x 升级到 Istio 1.30.0 时，需要注意此页面上的变更。
这些说明详细说明了有意破坏与 Istio 1.29.x 向后兼容性的变更。
此外，这些说明还提及了在保持向后兼容性的同时引入新行为的变更。
只有当新行为对 Istio 1.29.x 用户而言是意料之外的，才会包含这些变更。

## Gateway API CRD 必须升级至 `v1.5.x` {#gateway-api-crds-must-be-upgraded-to-v1.5.x}

Istio 1.30 将其 Gateway API 依赖升级至 `v1.5.1`，
并从标准通道（`gateway.networking.k8s.io/v1`）读取 `TLSRoute` 和 `ReferenceGrant`。

如果您将 Istio 升级至 1.30 版本，却未同时将集群中的 Gateway API CRD 升级至 `v1.5.x`，
那么 `TLSRoute` 和 `ReferenceGrant` 资源将对 istiod 不可见。
现有的 TLS 直通 `Gateway` 监听器将静默报告 `status.listeners[].attachedRoutes: 0`，
且 Envoy 监听器将无法被正确配置。

在升级至 Istio 1.30 之前，请从标准通道安装 Gateway API `v1.5.x` CRD：

{{< text bash >}}
$ kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.5.1"
{{< /text >}}

或者，如果您使用的是实验性通道：

{{< text bash >}}
$ kubectl apply -k "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.5.1"
{{< /text >}}

## CNI 配置文件权限已更改为 0600 {#cni-config-file-permissions-changed-to-0600}

Istio 写入的 CNI 配置文件，其默认文件权限已从 0644 更改为 0600。
此项变更符合 CIS Kubernetes 基准测试 `v1.12` 版本的相关要求。
鉴于 CNI 配置文件仅由以 root 权限运行的容器运行时读取，
因此这一变更应不会产生任何功能性影响。如果您使用的工具需要以非
root 用户组的成员身份读取 CNI 配置文件，您可以通过在 `istio-cni-node` `DaemonSet`
中设置环境变量 `values.cni.env.CNI_CONF_GROUP_READ=true`，将文件权限调整为 0640。

## CNI Agent 遵守 `excludeNamespaces` 配置 {#cni-agent-respects-excludeNamespaces-configuration}

此前，仅 CNI 插件会遵循 `excludeNamespaces` 配置，通过跳过对被排除命名空间内 Pod 的处理来实现排除；
而 CNI Agent 仍会执行协调操作，将被排除命名空间内带有 Ambient 标签的 Pod 加入到服务网格中。
如今，CNI Agent 也已支持遵循被排除命名空间配置；这意味着，
对于位于被排除命名空间内的现有已注册 Pod，系统将对其执行注销操作；
而对于该命名空间内新出现的带有 Ambient 标签的 Pod，系统将不再对其执行注册操作。

## 移除污点控制器 {#untaint-controller}

当 `istiod` 部署的 Helm Chart 中设置了 `taint.enabled` 时，
环境变量 `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` 现在会自动配置。
因此，不再需要在 `istiod` 部署中手动启用该变量。

## Sidecar 代理服务命名空间选择已更改 {#sidecar-proxy-service-namespace-selection-changed}

在配置 Sidecar 代理时，如果同一主机名存在于多个命名空间中，
Istio 现在会优先选用 Kubernetes 的 `Service` 资源；
若无此类资源，则会回退选用创建时间最早的非 Kubernetes 服务。
在此之前，系统是按字母顺序选取首个可见的命名空间。

如果您在多个命名空间中使用了相同的 hostname，且涉及混合的服务类型
（例如 Kubernetes 的 `Service` 和 `ServiceEntry`），
这可能会导致流量被路由至不同的服务实例。

如果不需要此行为，请在 Istiod 中将环境变量 `PILOT_SIDECAR_PICK_BEST_SERVICE_NAMESPACE`
设置为 `false`，或者使用 `compatibilityVersion` 1.28 或更早版本以恢复之前的行为。

## XDS 调试端点现需进行身份验证 {#xds-debug-endpoints-now-require-authentication}

端口 15010 上的 XDS 调试端点（`syncz`、`config_dump`）现已要求进行身份验证。
此变更会影响使用 `--plaintext` 标志的 `istioctl` 命令，
以及使用明文 XDS 的自定义工具。若要恢复此前的行为，
请将 `ENABLE_DEBUG_ENDPOINT_AUTH` 设置为 `false`。
