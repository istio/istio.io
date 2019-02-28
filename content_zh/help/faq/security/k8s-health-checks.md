---
title: 当启用双向 TLS 认证时应该如何使用 Kubernetes liveness 和 readiness 对服务进行健康检查？
weight: 50
---
如果启用了双向 TLS 认证，则来自 kubelet 的 http 和 tcp 健康检查将不能正常工作，因为 kubelet 没有 Istio 颁发的证书。

从 Istio 1.0 开始，针对服务新增了 [`PERMISSIVE` 模式](/docs/tasks/security/mtls-migration)
，因此当这个模式打开时他们可以接受 http 和双向 TLS 流量。这可以解决健康检查问题。
请记住，双向 TLS 没有强制执行，因为其他服务可以使用 http 流量与该服务进行通信。

您可以使用单独的端口进行健康检查，并只在常规服务端口上启用双向 TLS。请参阅 [Istio 服务的健康检查](/help/ops/setup/app-health-check/)了解更多信息。

另一种解决方法是对健康检查使用 [liveness 命令](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/#define-a-liveness-command)，例如，可以在服务 Pod 中安装 `curl` 并在 Pod 内对自身执行 `curl` 操作。

一个 readiness 探针的例子：

{{< text yaml >}}
livenessProbe:
exec:
  command:
  - curl
  - -f
  - http://localhost:8080/healthz # Replace port and URI by your actual health check
initialDelaySeconds: 10
periodSeconds: 5
{{< /text >}}
