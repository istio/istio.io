---
title: ImageAutoWithoutInjectionWarning
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当某个 `Deployment` 包含使用 `image: auto` 的 `istio-proxy` 容器，
但没有任何 Istio 注入 Webhook 选择该 `Deployment` 的 Pod 时，会出现此消息。

`auto` 镜像是一个占位符，Sidecar 注入器会将其替换为正确的镜像。
这是[安装网关](/zh/docs/setup/additional-setup/gateway/)的常用方法。
如果没有发生注入，Pod 将无法拉取镜像 `auto`，也无法启动。

## 示例 {#example}

假设在未启用注入的命名空间中有如下 `Deployment`：

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingressgateway
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  template:
    metadata:
      labels:
        istio: ingressgateway
    spec:
      containers:
      - name: istio-proxy
        image: auto
{{< /text >}}

您将收到以下消息：

{{< text plain >}}
Warning [IST0146] (Deployment default/istio-ingressgateway) Deployment istio-ingressgateway contains `image: auto` but does not match any Istio injection webhook selectors.
{{< /text >}}

## 如何修复 {#how-to-resolve}

为 Pod 启用注入。例如，为命名空间添加 `istio-injection=enabled` 标签，
或为 Pod 模板添加 `sidecar.istio.io/inject: "true"` 标签。
如果您使用了修订版本，请使用带有正确修订版本的 `istio.io/rev` 标签。
