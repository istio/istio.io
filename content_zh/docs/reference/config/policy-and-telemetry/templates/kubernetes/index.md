---
title: Kubernetes
description: 用于生成 Kubernetes 的特定属性。
weight: 50
---

`kubernetes` 模板控制 Kubernetes 特有的属性生成过程。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: kubernetes
metadata:
  name: attributes
  namespace: istio-system
spec:
  # 向适配器传递必要的属性数据
  source_uid: source.uid | ""
  source_ip: source.ip | ip("0.0.0.0") # 缺省为不确定的 IP 地址
  destination_uid: destination.uid | ""
  destination_ip: destination.ip | ip("0.0.0.0") # 缺省为不确定的 IP 地址
  attribute_bindings:
    # 用适配器生成的输出数据填充新属性。
    # $out 指代 OutputTemplate 消息中的实例。
    source.ip: $out.source_pod_ip
    source.labels: $out.source_labels
    source.namespace: $out.source_namespace
    source.service: $out.source_service
    source.serviceAccount: $out.source_service_account_name
    destination.ip: $out.destination_pod_ip
    destination.labels: $out.destination_labels
    destination.namespace: $out.destination_mamespace
    destination.service: $out.destination_service
    destination.serviceAccount: $out.destination_service_account_name
{{< /text >}}

## `OutputTemplate`

`OutputTemplate` 代表从适配器中生成的输出，它在 `attribute_binding` 字段中使用，使用格式为 `$out.<field name of the OutputTemplate>`，用来给属性填充数据。

|字段|类型|说明|
|---|---|---|
|`sourcePodUid`|`string`|Pod 的 `source.uid`。TCP 用例中没有这一属性。在 `attribute_binding` 用表达式 `$out.source_pod_uid` 来使用该字段
|`sourcePodIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|源 Pod 的 IP 地址。在 `attribute_binding` 用表达式 `$out.source_pod_ip` 来使用该字段
|`sourcePodName`|`string`|源 Pod 的名称。在 `attribute_binding` 用表达式 `$out.source_pod_name` 来使用该字段
|`sourceLabels`|`map<string, string>`|源 Pod 的标签。在 `attribute_binding` 用表达式 `$out.source_labels` 来使用该字段
|`sourceNamespace`|`string`|源 Pod 所属的命名空间。在 `attribute_binding` 用表达式 `$out.source_namespace` 来使用该字段
|`sourceServiceAccountName`|`string`|源 Pod 的 `ServiceAccount` 名称。在 `attribute_binding` 用表达式 `$out.source_service_account_name` 来使用该字段
|`sourceHostIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|源 Pod 所在主机的 IP 地址。在 `attribute_binding` 用表达式 `$out.source_host_ip` 来使用该字段
|`sourceWorkloadUid`|`string`|源 Pod 所在的 Istio 工作负载标识符。在 `attribute_binding` 用表达式 `$out.source_workload_uid` 来使用该字段
|`sourceWorkloadName`|`string`|源 Pod 所在的 Istio 工作负载的名称。在 `attribute_binding` 用表达式 `$out.source_workload_name` 来使用该字段
|`sourceWorkloadNamespace`|`string`|源 Pod 所在的 Istio 工作负载的命名空间。在 `attribute_binding` 用表达式 `$out.source_workload_namespace` 来使用该字段
|`sourceOwner`|`string`|源 Pod 的属主（控制器）。在 `attribute_binding` 用表达式 `$out.source_owner` 来使用该字段
|`destinationPodUid`|`string`|Pod 的 `destination.uid`。TCP 用例中没有这一属性。在 `attribute_binding` 用表达式 `$out.destination_pod_uid` 来使用该字段
|`destinationPodIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|目的 Pod 的 IP 地址。在 `attribute_binding` 用表达式 `$out.destination_pod_ip` 来使用该字段
|`destinationPodName`|`string`|目的 Pod 的名称。在 `attribute_binding` 用表达式 `$out.destination_pod_name` 来使用该字段
|`destinationContainerName`|`string`|目的 Pod 的容器名称。在 `attribute_binding` 用表达式 `$out.destination_container_name` 来使用该字段
|`destinationLabels`|`string`|目的 Pod 的标签。在 `attribute_binding` 用表达式 `$out.destination_labels` 来使用该字段
|`destinationNamespace`|`string`|目的 Pod 所属的命名空间。在 `attribute_binding` 用表达式 `$out.destination_namespace` 来使用该字段
|`destinationServiceAccountName`|`string`|目的 Pod 的 `ServiceAccount` 名称。在 `attribute_binding` 用表达式 `$out.destination_service_account_name` 来使用该字段
|`destinationHostIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|目的 Pod 所在主机的 IP 地址。在 `attribute_binding` 用表达式 `$out.destination_host_ip` 来使用该字段
|`destinationOwner`|`string`|目标 Pod 的属主（控制器）。在 `attribute_binding` 用表达式 `$out.destination_owner` 来使用该字段
|`destinationWorkloadUid`|`string`|目的 Pod 所在的 Istio 工作负载标识符。在 `attribute_binding` 用表达式 `$out.destination_workload_uid` 来使用该字段
|`destinationWorkloadName`|`string`|目的 Pod 所在的 Istio 工作负载的名称。在 `attribute_binding` 用表达式 `$out.destination_workload_name` 来使用该字段
|`destinationWorkloadNamespace`|`string`|目的 Pod 所在的 Istio 工作负载的命名空间。在 `attribute_binding` 用表达式 `$out.destination_workload_namespace` 来使用该字段

## 模板

`kubernetes` 模板中呈现了用于生成 Kubernetes 特定属性的数据。

|字段|类型|描述|
|---|---|---|
|`sourceUid`|`string`|源 Pod 的 uid，格式为 `kubernetes://pod.namespace`|
|`sourceIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|源 Pod 的 IP 地址|
|`destinationUid`|`string`|目标 Pod 的 uid，格式为 `kubernetes://pod.namespace`|
|`destinationIp`|[`istio.policy.v1beta1.IPAddress`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|目标 Pod 的 IP 地址|
|`destinationPort`|`int64`|目标容器的端口号|