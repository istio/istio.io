---
title: ImageAutoWithoutInjectionError
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当某个 `Pod` 包含使用 `image: auto` 的 `istio-proxy` 容器时，会出现此消息。

`auto` 镜像是一个占位符，Sidecar 注入器会在创建 Pod 时将其替换为正确的镜像。
如果 Pod 仍然使用 `image: auto`，说明没有发生注入。该 Pod 将无法拉取镜像 `auto`，也无法启动。

## 示例 {#example}

您将收到如下消息：

{{< text plain >}}
Error [IST0147] (Pod default/istio-ingressgateway-5bdb6f9c8b-xk2vz) Pod istio-ingressgateway-5bdb6f9c8b-xk2vz contains `image: auto` but does not match any Istio injection webhook selectors.
{{< /text >}}

## 如何修复 {#how-to-resolve}

1. 为 Pod 启用注入。例如，为命名空间添加 `istio-injection=enabled` 标签，
   或为 Pod 添加 `sidecar.istio.io/inject: "true"` 标签。
   如果您使用了修订版本，请使用带有正确修订版本的 `istio.io/rev` 标签。

1. 确保注入器 Webhook 已安装且正在运行。

1. 重新创建 Pod。对于 `Deployment`，请使用 `kubectl rollout restart`。
