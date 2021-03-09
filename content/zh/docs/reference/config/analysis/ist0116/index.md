---
title: DeploymentAssociatedToMultipleServices
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: no
---

当一个 Deployment 的 Pod 资源的多个服务使用了相同端口但使用了不同的协议会出现该问题。

## 示例 {#An example}

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

不可以存在两个 Service 使用不同协议监听同一 Pod 的同一端口。
