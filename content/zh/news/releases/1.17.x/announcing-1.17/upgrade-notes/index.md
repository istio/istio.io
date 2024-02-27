---
title: Istio 1.17 升级说明
description: 升级到 Istio 1.17 时要考虑的重要变更。
publishdate: 2023-02-14
weight: 20
---

当您从 Istio 1.16.x 升级到 Istio 1.17 时，您需要考虑本页所述的变更。
这些说明详述了故意破坏 Istio `1.16.x` 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
仅当新特性对 Istio `1.16.x` 的用户来说在意料之外时，才会包含这些变更。
对于从 Istio 1.15.x 升级到 Istio 1.17 的用户，
还应参考 [1.16 变更说明](/zh/news/releases/1.16.x/announcing-1.16/change-notes/)。

## 更新了 Gateway 命名方案{#gateway-naming-scheme-updated}

如果您使用 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway)
来管理 Istio Gateway，`Kubernetes Deployment` 和 `Service` 的名称将被修改。
使用的默认 `Service Account` 也已切换为使用自己的令牌。
要在升级期间继续使用旧的约定，可以使用注解 `gateway.istio.io/name-override` 和 `gateway.istio.io/service-account`。

## 移除了 Client-go 鉴权插件{#client-go-auth-plugins-removed}

istioctl 1.17 包含**已移除** `gcp` 和 `azure` 鉴权插件的 client-go 升级版本，
（类似于 kubectl 1.26 [版本](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.26.md#deprecation)）。
请参阅 [kubelogin](https://github.com/Azure/kubelogin) 和 [Kubectl Auth Changes in GKE](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke)
了解替代特定云的详情。
迁移之后，请确保在使用 istioctl 之前更新/重新生成您的 kubeconfig 文件。
