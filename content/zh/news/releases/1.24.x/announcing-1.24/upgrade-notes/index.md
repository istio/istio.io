---
title: Istio 1.24 升级说明
description: 升级到 Istio 1.24.0 时要考虑的重要变更。
weight: 20
publishdate: 2024-11-07
---

从 Istio 1.23.x 升级到 Istio 1.24.x 时，请考虑此页面上的更改。
这些说明详述了故意打破 Istio 1.23.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.23.x 用户意料的新特性变更。

## 更新了兼容性配置文件 {#updated-compatibility-profiles}

为了支持与旧版本的兼容性，Istio 1.24 引入了新的 1.23
[兼容性配置文件](/zh/docs/setup/additional-setup/compatibility-versions/)，
并更新了其其他配置文件以考虑 Istio 1.24 中的变化。

此配置文件设置了以下值：

{{< text yaml >}}
ENABLE_INBOUND_RETRY_POLICY: "false"
EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY: "false"
PREFER_DESTINATIONRULE_TLS_FOR_EXTERNAL_SERVICES: "false"
ENABLE_ENHANCED_DESTINATIONRULE_MERGE: "false"
PILOT_UNIFIED_SIDECAR_SCOPE: "false"
ENABLE_DEFERRED_STATS_CREATION: "false"
BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS: "false"
{{< /text >}}

请参阅单独的变更和升级说明以了解更多信息。

## 使用 DNS 代理升级 Ambient {#ambient-upgrade-with-dns-proxy}

在使用 Ambient 模式升级到 Istio 1.24.0 时，如果配置了 `cni.ambient.dnsCapture=true`，
用户需要遵循一组特定的升级步骤：

1. 升级 Istio CNI
1. 重启已在 Ambient 模式运行的所有工作负载
1. 升级 Ztunnel

否则将导致 DNS 解析失败。
如果发生这种情况，您可以重新启动工作负载来解决问题。

预计在未来的补丁版本中将会改进这个问题；请关注
[Issue](https://github.com/istio/ztunnel/issues/1360)以获取更多信息。

## Istio CRD 默认是模板化的，可以通过 `helm install istio-base` 安装和升级 {#istio-crds-are-templated-by-default-and-can-be-installed-and-upgraded-via-helm-install-istio-base}

这改变了 CRD 的升级方式。之前，我们建议并记录了以下内容：

- 安装：`helm install istio-base`
- 升级：`kubectl apply -f manifests/charts/base/files/crd-all.gen.yaml` 或类似命令。
- 卸载：`kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

此更改允许：

- 安装：`helm install istio-base`
- 升级：`helm upgrade istio-base`
- 卸载：`kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete`

以前，这仅在某些条件下才有效，并且当使用某些安装标志时，
可能会导致生成不可 Helm 升级的 CRD，需要手动干预才能修复。

经过此更改后，在使用 Helm 运行 `kubectl` 命令进行带有外部安装和升级 Istio CRD **不再被需要**。

如果您不使用 Helm 来安装、模板化或管理 Istio 资源，
您可以继续使用 `kubectl apply -f manifests/charts/base/files/crd-all.gen.yaml` 手动安装 CRD。

如果您之前仅使用 `helm install istio-base` 或 `kubectl apply` 安装了 CRD，
则可以在运行以下 kubectl 命令作为一次性迁移后，
从此版本以及所有后续版本开始使用 `helm upgrade istio-base` 安全地升级 Istio CRD：

- `kubectl label $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "app.kubernetes.io/managed-by=Helm"`
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-name=istio-base"`（用真实的 `istio-base` Helm 版本名称替换）
- `kubectl annotate $(kubectl get crds -l chart=istio -o name && kubectl get crds -l app.kubernetes.io/part-of=istio -o name) "meta.helm.sh/release-namespace=istio-system"`（用真实的 istio 命名空间替换）

如果需要，可以在 `helm install base` 期间通过设置
`base.enableCRDTemplates=false` 来生成旧标签，但此选项将在未来的版本中被删除。

## `istiod-remote` Chart 被 `remote` 配置文件替换 {#istiod-remote-chart-replaced-with-remote-profile}

通过 Helm 安装带有远程/外部控制平面的 istio 集群从未正式记录或稳定。
这改变了使用远程 istio 实例的集群的安装方式，以便为此做准备。

`istiod-remote` Helm Chart 已与常规 `istio-discovery` Helm Chart 合并。

之前：
- `helm install istiod-remote istio/istiod-remote`

经过这一变更：
- `helm install helm install istiod istio/istiod --set profile=remote`

请注意，根据上述升级说明，现在需要在本地和远程集群中安装 `istio-base` Chart。

## `Sidecar` 范围变更 {#sidecar-scoping-changes}

在处理服务期间，Istio 有多种冲突解决策略。从历史上看，当用户定义了 `Sidecar` 资源时，
与未定义 `Sidecar` 资源时相比，这些策略略有不同。
即使 `Sidecar` 资源只有 `egress: "*/*"`，这也适用，这应该与未定义 `Sidecar` 资源相同。

在这个版本中，两者之间的行为已经统一：

**使用相同主机名定义的多个服务**之前的行为，没有 `Sidecar`：
首选 Kubernetes`Service`（而不是 `ServiceEntry`），
否则选择任意一个。之前的行为，有 `Sidecar`：首选与代理位于同一命名空间中的服务，
否则选择任意一个。新行为：首选与代理位于同一命名空间中的服务，
然后是 Kubernetes 服务（不是 ServiceEntry），否则选择任意一个。

**为同一服务定义多个 Gateway API Route** 之前的行为，
没有 `Sidecar`：首选本地代理命名空间，以允许消费者覆盖。之前的行为，
有 `Sidecar`：任意顺序。新行为：首选本地代理命名空间，以允许消费者覆盖。

可以通过设置 `PILOT_UNIFIED_SIDECAR_SCOPE=false` 暂时保留旧行为。

## 对等元数据属性的标准化 {#standardization-of-the-peer-metadata-attributes}

遥测 API 中的 CEL 表达式必须使用标准
[Envoy 属性](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/advanced/attributes)，
而不是自定义的 Wasm 扩展属性。

对等元数据现在存储在 `filter_state.downstream_peer` 和 `filter_state.upstream_peer` 中，
而不是 `filter_state["wasm.downstream_peer"]` 和 `filter_state["wasm.upstream_peer"]` 中。
节点元数据存储在 `xds.node` 中，而不是 `node` 中。Wasm 属性必须是完全限定的，
例如使用 `filter_state["wasm.istio_responseClass"]` 而不是 `istio_responseClass`。

存在运算符可用于混合代理场景中的向后兼容表达式，
例如 `has(filter_state.downstream_peer) ? filter_state.downstream_peer.namespace : filter_state["wasm.downstream_peer"].namespace`
来读取对等方的命名空间。

对等元数据使用具有以下字段属性的包编码：

- `namespace`
- `cluster`
- `service`
- `revision`
- `app`
- `version`
- `workload`
- `type`（例如 `"deployment"`）
- `name`（例如 `"pod-foo-12345"`）

## 与 cert-manager `istio-csr` 兼容

在此版本中，Istio 在与控制平面的 gRPC 通信中引入了增强的验证检查。
请注意，这只会影响 Istio 自己的内部 gRPC 使用情况，而不会影响用户的流量。

虽然 Istio 的控制平面不会受到影响，但流行的第三方 CA 实现
[`istio-csr`](https://github.com/cert-manager/istio-csr) 会受到影响。
虽然这个问题已经[在上游修复](https://github.com/cert-manager/istio-csr/pull/422)，
但在撰写本文时尚未发布修复版本（`v0.12.0` 没有修复）。

可以通过使用以下设置安装 Istio 来解决此问题：

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      GRPC_ENFORCE_ALPN_ENABLED: "false"
{{< /text >}}

如果您受到此问题的影响，您将看到一条错误消息，例如
 `"transport: authentication handshake failed: credentials: cannot check peer: missing selected ALPN property"`。
