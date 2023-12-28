---
title: DeploymentAssociatedToMultipleServices
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当 Deployment 的 Pod 被关联到多个使用相同端口但使用不同协议的 Service 时，
会出现此消息。

## 示例 {#example}

例如包含以下 Service 的 Istio 网格：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: productpage-tcp-v1
spec:
  ports:
    - port: 9080
      name: tcp
      protocol: TCP
  selector:
    app: productpage
---
apiVersion: v1
kind: Service
metadata:
  name: productpage-http-v1
spec:
  ports:
    - port: 9080
      name: http
      protocol: HTTP
  selector:
    app: productpage
{{< /text >}}

这个示例展示了使用 HTTP 和 TCP 协议的同时关联到了 9080 端口。

不可以存在两个 Service 在同一个端口上使用不同协议。
