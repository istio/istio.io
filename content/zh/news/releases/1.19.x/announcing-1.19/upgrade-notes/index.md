---
title: Istio 1.19 升级说明
description: 升级到 Istio 1.19 时要考虑的重要变更。
weight: 20
publishdate: 2023-09-05
---

当您从 Istio 1.18.x 升级到 Istio 1.19.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio `1.18.x` 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio `1.18.x` 用户意料的新特性变更。

## 使用 EnvoyFilter 的规范过滤器名称 {#use-the-canonical-filter-names-for-envoyfilter}

如果您使用 EnvoyFilter API，请使用规范的过滤器名称。
不支持使用已弃用的过滤器名称。有关更多详细信息，
请参阅 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated)。

## 删除 `base` Helm Chart {#base-helm-chart-removals}

之前存在于 `base` Helm Chart 中的许多配置**已复制**到之前版本中的 `istiod` Chart 中。

在此版本中，重复的配置已从 `base` Chart 中完全删除。

下面显示了旧配置到新配置的映射：

| 旧                                     | 新                                     |
| --------------------------------------- | --------------------------------------- |
| `ClusterRole istiod`                    | `ClusterRole istiod-clusterrole`        |
| `ClusterRole istiod-reader`             | `ClusterRole istio-reader-clusterrole`  |
| `ClusterRoleBinding istiod`             | `ClusterRoleBinding istiod-clusterrole` |
| `Role istiod`                           | `Role istiod`                           |
| `RoleBinding istiod`                    | `RoleBinding istiod`                    |
| `ServiceAccount istiod-service-account` | `ServiceAccount istiod`                 |

注意：大多数资源都会另外自动添加后缀。在旧 Chart 中是 `-{{ .Values.global.istioNamespace }}`。
在新 Chart 中，对于命名空间范围的资源为
`{{- if not (eq .Values.revision "") }}-{{ .Values.revision }}{{- end }}`，而对于集群范围的资源为
`{{- if not (eq .Values.revision "")}}-{{ .Values.revision }}{{- end }}-{{ .Release.Namespace }}`。

## EnvoyFilter 必须指定 Envoy 扩展注入的类型 URL {#envoyfilter-must-specify-the-type-url-for-an-envoy-extension-injection}

之前，Istio 允许仅通过其内部 Envoy 名称在 `EnvoyFilter` 中查找扩展。
要查看您是否受到影响，请运行 `istioctl analyze` 并检查是否有弃用警告
`using deprecated types by name without typed_config`。
此外，请确保 `EnvoyFilter` 内的任何嵌套扩展列表都包含 `name:` 和 `typed_config:` 字段。

## Gateway API：附加服务的 `parentRefs` 必须指定空组 {#gateway-api-service-attached-parentrefs-must-specify-empty-group}

由于 Gateway API 一致性测试的更新，Istio 将不再接受 Gateway API
路由中服务 `parentRef` 的默认组 `gateway.networking.k8s.io`
（例如 `HTTPRoute`、`TCPRoute` 等）。相反，您必须显式设置 `group: ""`，如下所示：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: productpage
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: productpage
    port: 9080
{{< /text >}}
