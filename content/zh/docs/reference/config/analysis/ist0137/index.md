---
title: DeploymentConflictingPorts
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当两个 Service 选择了同一个工作负载的同一个目标端口（`targetPort`）
但却指定了不同的服务端口 `port`，会出现此消息。

## 示例 {#example}

以提供以下 Service 的 Istio 网格为例：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: nginx-a
spec:
  ports:
    - port: 8080
      protocol: TCP
      targetPort: 80
  selector:
    app: nginx
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-b
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: nginx
{{< /text >}}

在这个示例中，Service `nginx-a` 和 `nginx-b` 选择了工作负载 `nginx`
的同一个目标端口 `80`，但是它们对应的服务端口（`port`）却不一致。

## 如何修复 {#how-to-resolve}

修复此问题有两个选择：

- 两个 Service 使用相同的端口（`port`）。需要重新配置客户端以连接到修改之后的服务端口。
- 两个 Service 使用不同的目标端口（`targetPort`）。
  需要修改工作负载的 Pod 监听到修改之后的目标端口以提供服务。
