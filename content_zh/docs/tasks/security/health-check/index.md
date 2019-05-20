---
title: Citadel 的健康检查
description:  如何在 Kubernetes 中启用 Citadel 的健康检查。
weight: 70
keywords: [security,health-check]
---

您可以启用 Citadel 的健康检查功能来检测 Citadel CSR（证书签名请求）服务的故障。
Citadel 定期向其 CSR 服务端发送 CSR 请求并验证响应。

Citadel 中的 `_prober client_` 探测客户端模块会周期性地检查 Citadel CSR gRPC 服务的健康状态。如果 Citadel 是健康的，探测客户端会更新 `_health status file_` 健康状态文件的 `_modification time_` 更新时间。否则就什么都不做。Citadel 依赖 [Kubernetes 的健康和就绪检测](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)功能，会周期性的使用命令行检查健康状态文件的更新时间。如果这个文件有一段时间不更新了，Citadel 容器就会被 Kubelet 重新启动。

注意：Citadel 的健康检查目前只提供了对 CSR 服务 API 的支持，如果没有使用 [SDS](/zh/docs/tasks/security/auth-sds/) 或 [Istio Mesh Expansion](/zh/docs/setup/kubernetes/additional-setup/mesh-expansion/) 就没有必要使用这个功能了。

## 开始之前

要完成此任务，您可以使用以下方式之一安装 Istio：

* 不使用 Helm 安装，请遵照 [Kubernetes 安装指南](/zh/docs/setup/kubernetes/install/kubernetes/)的指引部署。 请记得启用全局双向 TLS 支持：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

* 使用 [Helm](/zh/docs/setup/kubernetes/install/helm/) 进行部署，设置 `global.mtls.enabled` 为 `true`。

{{< tip >}}
使用[认证策略](/zh/docs/concepts/security/#认证策略)可以为命名空间内的部分或者全部服务配置双向 TLS 支持。为了全局生效，你必须在所有命名空间重复执行策略。请参考[认证策略任务](/zh/docs/tasks/security/authn-policy/)获取详情。
{{< /tip >}}

## 部署启用健康检查的 Citadel

为了启用健康检查，使用 `istio-citadel-with-health-check.yaml` 的配置重新部署 Citadel：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-citadel-with-health-check.yaml
{{< /text >}}

## 确认健康检查器是否工作

Citadel 会记录健康检查的结果，运行下面的命令行：

{{< text bash >}}
$ kubectl logs `kubectl get po -n istio-system | grep istio-citadel | awk '{print $1}'` -n istio-system | grep "CSR signing service"
{{< /text >}}

会看到类似下面这样的输出：

{{< text plain >}}
... CSR signing service is healthy (logged every 100 times).
{{< /text >}}

上面的日志表明周期性的健康检查已经启动。可以看到，缺省的健康检查的时间周期是 15 秒，而且每 100 次检查记录一次日志。

## (可选) 配置健康检查

本节讨论如何修改健康检查的配置。打开文件 `install/kubernetes/istio-citadel-with-health-check.yaml`，找到下面的内容（注释已汉化，非原文）：

{{< text plain >}}
...
  - --liveness-probe-path=/tmp/ca.liveness # 健康检查状态文件的路径
  - --liveness-probe-interval=60s # 健康状态文件的更新周期
  - --probe-check-interval=15s    # 健康检查的周期
livenessProbe:
  exec:
    command:
    - /usr/local/bin/istio_ca
    - probe
    - --probe-path=/tmp/ca.liveness # 健康状态文件的路径
    - --interval=125s               # 文件修改时间和当前系统时钟的最大时间差
  initialDelaySeconds: 60
  periodSeconds: 60
...
{{< /text >}}

`liveness-probe-path` 和 `probe-path` 是到健康状态文件的路径。
你应该同时更新 Citadel 以及 `livenessProbe` 上配置的路径。
如果 Citadel 是健康的，`liveness-probe-interval` 的值决定了更新健康状态文件的时间间隔。
Citadel 健康检查控制器使用 `probe-check-interval` 的值作为 Citadel 健康检查的间隔时间。
`interval` 是从上次更新健康状态文件到检测器认为 Citadel 健康的最长时间。
`initialDelaySeconds` 和 `periodSeconds` 是初始化延迟以及 `livenessProbe` 检测运行周期。

延长 `probe-check-interval` 会减少健康检查的开销，但是一旦遇到故障情况，健康监测器也会更晚地得到故障信息。为了避免检测器因为临时故障重启 Citadel，检测器的 `interval` 应该设置为 `liveness-probe-interval` 的 `N` 倍，这样就让检测器能够容忍持续 `N-1` 次的检查失败。

## 清理

* 在 Citadel 上禁用健康检查：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

* 移除 Citadel：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-citadel-with-health-check.yaml
    {{< /text >}}
