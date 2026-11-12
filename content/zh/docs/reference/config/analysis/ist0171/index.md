---
title: NegativeConditionStatus
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当资源的状态中包含表明存在问题的条件时，会出现此消息。

分析器会检查以下条件：

| 类型 | 条件 | 负面状态 |
|------|-----------|-----------------|
| `Service`、`ServiceEntry`、`WorkloadEntry` | `istio.io/WaypointBound` | `False` |
| `AuthorizationPolicy` | `ZtunnelAccepted`、`WaypointAccepted` | `False` |
| `AuthorizationPolicy` | 原因为 `PartiallyInvalid` 的 `WaypointAccepted` | `True` |
| `Gateway`、`HTTPRoute`、`GRPCRoute`（Kubernetes Gateway API） | `Accepted`、`Programmed`、`ResolvedRefs` | `False` |

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0171] (HTTPRoute default/httpbin) A condition with a negative status is present: type=ResolvedRefs, reason=BackendNotFound, message=backend(httpbin.default.svc.cluster.local) not found.
{{< /text >}}

## 如何修复 {#how-to-resolve}

阅读该条件的原因和消息，它们会说明问题所在。修复该资源或其引用的资源。
