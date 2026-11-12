---
title: FutureUnsupportedGatewayAPIVersion
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 [`istioctl x precheck`](/zh/docs/reference/commands/istioctl/#istioctl-experimental-precheck)
发现 Istio 未来版本将不再支持的 Kubernetes Gateway API CRD 时，会出现此消息。

Istio 未来版本将要求 `Gateway`、`GatewayClass`、`HTTPRoute` 和 `GRPCRoute` CRD 提供 `v1` 版本。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0172] (CustomResourceDefinition httproutes.gateway.networking.k8s.io) The Gateway API CRD version v1beta1 is lower than the minimum version: v1
{{< /text >}}

## 如何修复 {#how-to-resolve}

将 Gateway API CRD 升级到提供 `v1` 的版本。有关安装命令，请参阅
[Kubernetes Gateway API](/zh/docs/tasks/traffic-management/ingress/gateway-api/)。
