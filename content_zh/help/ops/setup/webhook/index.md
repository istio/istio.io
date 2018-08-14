---
title: 动态准入 Webhooks 概述
description: 概述了 Istio 使用 Kubernetes webhook 及可能出现的相关问题。
weight: 10
---

来自 [Kubernetes 派生和验证 webhook 机制](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)：

> 准入 webhook 是 HTTP 方式的回调，接收准入请求并对其进行相关操作。可定义两种类型的准入 webhook，验证准入 webhook 和派生准入 webhook。 通过验证准入 webhook，可以通过自定义的增强准入策略来拒绝请求。通过派生准入 webhook，可以通过自定义默认值来修改请求。

Istio 使用 `ValidatingAdmissionWebhooks` 验证 Istio 配置，使用 `MutatingAdmissionWebhooks` 自动将 sidecar 代理注入至用户 pod。

Webhook 设置指南基于 Kubernetes 动态准入 webhook 相关的知识。有关派生和验证 webhook 配置的详细文档，请参考 [Kubernetes API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/)。

## 验证动态准入 webhook 前置条件

请参阅 Kubernetes 特定提供者设置指令的[前置条件快速入门](/zh/docs/setup/kubernetes/quick-start/#前置条件) 。如果群集配置错误，webhook 将无法正常工作。如集群配置后，动态 webhook 和依赖的相关功能不能够正常工作，可以通过以下步骤进行检查。

1. 验证 `kubectl` 是否是[最新版本](https://kubernetes.io/docs/tasks/tools/install-kubectl/)（>= 1.10），并且 Kubernetes 服务器版本 >= 1.9。

    {{< text bash >}}
    $ kubectl version --short
    Client Version: v1.10.2
    Server Version: v1.10.4-gke.0
    {{< /text >}}

1. `admissionregistration.kubernetes.io/v1beta1` 应是启用状态

    {{< text bash >}}
    $ kubectl api-versions |grep admissionregistration.Kubernetes.io/v1beta1
    admissionregistration.Kubernetes.io/v1beta1
    {{< /text >}}

1. 验证 `MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook` 在`kube-apiserver --enable-admission-plugins` 配置中被启用。通过[特定提供者](/zh/docs/setup/kubernetes/quick-start/#前置条件)提供步骤来检查此标志。

1. 验证 Kubernetes api-server 与 webhook pod 的网络连通是否正常。例如不正确的 `http_proxy` 设置可能会使  api-server 操作不正常（有关详细信息，请参阅[这里](https://github.com/kubernetes/kubernetes/pull/58698#discussion_r163879443)和[这里](https://github.com/kubernetes/kubeadm/issues/666)的相关问题)。
