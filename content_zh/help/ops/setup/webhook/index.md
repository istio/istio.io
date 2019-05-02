---
title: 动态准入 Webhook 概述
description: 概述了 Istio 使用 Kubernetes Webhook 及可能出现的相关问题。
weight: 10
---

来自 [Kubernetes 准入控制机制](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)：

{{< tip >}}
准入 Webhook 是 HTTP 方式的回调，接收准入请求并对其进行相关操作。可定义两种类型的准入 Webhook，Validating 准入 Webhook 和 Mutating 准入 Webhook。 使用 Validating Webhook，可以通过自定义的准入策略来拒绝请求；使用 Mutating Webhook，可以通过自定义默认值来修改请求。
{{< /tip >}}

Istio 使用 `ValidatingAdmissionWebhooks` 验证 Istio 配置，使用 `MutatingAdmissionWebhooks` 自动将 Sidecar 代理注入至用户 Pod。

Webhook 设置过程需要了解 Kubernetes 动态准入 Webhook 相关的知识。有关 Validating 和 Mutating Webhook 配置的详细文档，请参考 [Kubernetes API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/)。

## 验证动态准入 Webhook 前置条件

请参阅 Kubernetes 快速入门中的[前置条件章节](/zh/docs/setup/kubernetes/install/kubernetes/#前置条件)。如果群集配置错误，Webhook 将无法正常工作。如集群配置后，动态 Webhook 和依赖的相关功能无法正常工作，可以通过以下步骤进行检查。

1. 验证 `kubectl` 是否是[最新版本](https://kubernetes.io/docs/tasks/tools/install-kubectl/)（>= 1.10），并且 Kubernetes 服务器版本 >= 1.9。

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.10.2
    Server Version: v1.10.4-gke.0
    {{< /text >}}

1. `admissionregistration.k8s.io/v1beta1` 应是启用状态

    {{< text bash >}}
    $ kubectl api-versions | grep admissionregistration.k8s.io/v1beta1
    admissionregistration.k8s.io/v1beta1
    {{< /text >}}

1. 验证 `MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook` 在`kube-apiserver --enable-admission-plugins` 配置中是否被启用。通过[特定提供者](/zh/docs/setup/kubernetes/install/kubernetes/#前置条件)提供的步骤来检查此标志。

1. 验证 Kubernetes api-server 与 Webhook 所在 Pod 的网络连通是否正常。例如不正确的 `http_proxy` 设置可能会使  api-server 操作无法正常完成（有关详细信息，请参阅[这里](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)和[这里](https://github.com/kubernetes/kubeadm/issues/666)的相关问题)。
