---
title: GatewayAPICRDVersionBelowMinimum
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当安装的 Kubernetes Gateway API CRD 版本低于当前 Istio 版本所要求的最低版本时，会出现此消息。
Istio 不会处理此类资源。

分析器从 CRD 的 `gateway.networking.k8s.io/bundle-version` 注解中获取已安装的版本。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Warning [IST0176] (CustomResourceDefinition tlsroutes.gateway.networking.k8s.io) Gateway API CRD "tlsroutes.gateway.networking.k8s.io" is at version "1.2.0" but Istio requires at least "1.5.0"; resources of this kind will not be processed. Upgrade the Gateway API CRDs to satisfy the minimum version.
{{< /text >}}

## 如何修复 {#how-to-resolve}

升级 Gateway API CRD。有关安装命令，请参阅
[Kubernetes Gateway API](/zh/docs/tasks/traffic-management/ingress/gateway-api/)。
