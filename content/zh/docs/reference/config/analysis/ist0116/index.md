---
title: DeploymentAssociatedToMultipleServices
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当一个 Deployment 的 Pod 对应的多个 Service 在相同端口上定义了不同的协议会出现此消息。

## 示例 {#example}

例如包含以下 Service：

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

这个示例展示了使用 HTTP 和 TCP 协议同时关联 9080 端口。

不可以存在两个 Service 在同一个端口上使用不同协议。
