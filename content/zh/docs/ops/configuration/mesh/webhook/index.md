---
title: 动态准入 Webhook 概述
description: 简要描述 Istio 对 Kubernetes webhook 的使用以及可能出现的相关问题。
weight: 10
aliases:
  - /zh/help/ops/setup/webhook
  - /zh/docs/ops/setup/webhook
owner: istio/wg-user-experience-maintainers
test: no
---

来自 [Kubernetes 准入控制机制](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/extensible-admission-controllers/)：

{{< tip >}}
准入 Webhook 是 HTTP 方式的回调，接收准入请求并对其进行相关操作。
可定义两种类型的准入 Webhook，Validating 准入 Webhook 和 Mutating
准入 Webhook。使用 Validating Webhook，可以通过自定义的准入策略来拒绝请求；
使用 Mutating Webhook，可以通过自定义默认值来修改请求。
{{< /tip >}}

Istio 使用 `ValidatingAdmissionWebhooks` 验证 Istio 配置，使用
`MutatingAdmissionWebhooks` 自动将 Sidecar 代理注入至用户 Pod。

Webhook 设置过程需要了解 Kubernetes 动态准入 Webhook 相关的知识。
查阅 Kubernetes API 的相关资料，请参
[Mutating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io)
和 [Validating Webhook Configuration](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#validatingwebhookconfiguration-v1-admissionregistration-k8s-io)。

## 验证动态准入 Webhook 前置条件 {#verify-dynamic-admission-webhook-prerequisites}

请参阅[平台设置说明](/zh/docs/setup/platform-setup/)了解 Kubernetes
提供的详细的设置说明。如果集群配置错误，Webhook 将无法正常工作。集群配置后，
当动态 Webhook 和相关特性不能正常工作时，您可以通过以下步骤进行检查。

1. 验证当前使用正确的 [`kubectl`](https://kubernetes.io/zh-cn/docs/tasks/tools/#kubectl)
   和 Kubernetes 服务[支持的版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)({{< supported_kubernetes_versions >}})：

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.19.0
    Server Version: v1.19.1
    {{< /text >}}

1. `admissionregistration.k8s.io/v1beta1` 应是启用状态

    {{< text bash >}}
    $ kubectl api-versions | grep admissionregistration.k8s.io/v1
    admissionregistration.k8s.io/v1
    admissionregistration.k8s.io/v1beta1
    {{< /text >}}

1. 验证 `kube-apiserver --enable-admission-plugins` 配置中插件
   `MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook`
   是否被启用。通过检查[指定规范](/zh/docs/setup/platform-setup/)中的标志（`--enable-admission-plugins`）。

1. 验证 Kubernetes API Server 与 Webhook 所在 Pod 的网络连通是否正常。
   例如错误配置 `http_proxy` 可能干扰 API Server 正常运行（详细信息请参阅
   [PR](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)
   和 [Issue](https://github.com/kubernetes/kubeadm/issues/666)）。
