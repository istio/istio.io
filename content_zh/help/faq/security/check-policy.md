---
title: 如何检查服务是否启动了双向 TLS？
weight: 11
---

 `istioctl` 工具为此提供了一个选项，你可以像下面那样做：

{{< text bash >}}
$ istioctl authn tls-check httpbin.default.svc.cluster.local
HOST:PORT                                  STATUS     SERVER     CLIENT     AUTHN POLICY        DESTINATION RULE
httpbin.default.svc.cluster.local:8000     OK         mTLS       mTLS       default/            default/default
{{< /text >}}

更多详细信息，请参见[检查双向 TLS 配置](/zh/docs/tasks/security/mutual-tls/#检查-istio-双向-tls-认证的配置)。

