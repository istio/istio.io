---
title: Istio 1.3 Secret 服务发现的更改
description: 利用 Kubernetes 可信任的 JWT 来更安全地为工作负载实例颁发证书。
publishdate: 2019-09-10
attribution: Phillip Quy Le (Google)
keywords: [security, PKI, certificate, nodeagent, sds]
target_release: 1.2
---

在 Istio 1.3 中，我们正在利用 Kubernetes 的改进功能来更安全地为工作负载实例颁发证书。

当 Citadel 代理向 Citadel 发送证书签名请求以获取工作负载实例的证书时，它包含了 Kubernetes API 服务器颁发的代表工作负载实例的服务帐户的 JWT。如果 Citadel 可以对 JWT 进行身份验证，则提取为工作负载实例颁发证书所需的服务帐户名。

在 Kubernetes 1.12 之前，Kubernetes API 服务器的 JWT 存在以下问题：

1. 令牌没有重要字段来限制其使用范围，例如 `aud` 或 `exp`。有关更多信息，请参见[绑定服务令牌](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/auth/bound-service-account-tokens.md)。
1. 令牌安装在所有 Pod 上，无法退出。请参见[服务帐户令牌数量](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/svcacct-token-volume-source.md)了解其机制。

Kubernetes 1.12 引入了 `可信任` JWT 来解决这些问题。但是，直到 [Kubernetes 1.13](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.13.md) 才支持 `aud` 字段与 API 服务器受众具有不同的值。为了更好地保护网格，Istio 1.3 仅支持 `可信任` JWT，并且在启用 SDS 时要求 `aud` 字段的值为 `istio-ca`。在启用 SDS 的情况下将 Istio 部署升级到 1.3 之前，请验证您是否使用了 Kubernetes 1.13 或更高版本。

根据您选择的平台进行以下考虑：

- **GKE：** 至少将群集版本升级到 1.13。
- **本地 Kubernetes** 和 **私有 GKE：** 将 [额外配置](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection) 添加到您的 Kubernetes。
您也可以参考 [API 服务页面](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kube-apiserver/) 以获取最新的标志名称。
- 对于其他平台，请与您的提供商联系。如果您的提供商不支持可信任 JWT，则您将需要使用文件挂载的方式来传播 Istio 1.3 中的工作负载密钥和证书。
