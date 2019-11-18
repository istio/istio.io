---
title: 如何检查一个服务是否启动了双向 TLS？
weight: 11
---

您可以通过 [`istioctl`](/zh/docs/reference/commands/istioctl) 提供的一个选项来进行确认，请执行以下命令：

{{< text bash >}}
$ istioctl authn tls-check $CLIENT_POD httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         mTLS       mTLS       /default            istio-system/default
{{< /text >}}

其中 `$CLIENT_POD` 是作为客户端服务运行的 pod 中的任意一个的 ID。

请参见[验证双向 TLS 配置](/zh/docs/tasks/security/mutual-tls/#verify-mutual-TLS-configuration)以获取更多细节。
