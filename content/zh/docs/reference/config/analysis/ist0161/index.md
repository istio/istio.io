---
title: InvalidGatewayCredential
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 Gateway 资源引用具有 TLS 配置的 Secret，
且该 Secret 未包含或包含无效的 TLS 证书时，
`InvalidGatewayCredential` 消息将出现。
此消息有助于识别 Gateway 资源的 TLS 配置问题，
这些问题可能会导致安全问题或无法正常连接等情况的发生。

满足以下条件时会生成此消息：

1. Gateway 资源有一个带有 TLS 配置的服务器。

1. TLS 配置引用了 `credentialName`。

1. 未找到具有指定 `credentialName` 的 Secret，
   或者在找到的 Secret 中发现无效 TLS 证书。

要解决此问题，请确保具有指定 `credentialName` 的 Secret
存在于与 Gateway 工作负载相同的命名空间中，
并且该 Secret 包含有效的 TLS 证书。
您可能需要创建或更新 Secret 才能解决此问题。

如果 Secret 丢失，请使用正确的 TLS 证书和私钥创建一个新的 Secret。
例如，通过使用 `kubectl`：

{{< text bash >}}
$ kubectl create secret tls my-tls-secret --cert=path/to/cert.pem --key=path/to/key.pem -n <namespace>
{{< /text >}}

确保将 `<namespace>` 替换为运行 Gateway 工作负载的实际命名空间，
并更新文件路径以指向正确的证书和密钥文件。

如果 Secret 存在但其中的 TLS 证书无效，
请使用正确的 TLS 证书和私钥来更新 Secret。
