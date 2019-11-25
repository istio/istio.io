---
title: Citadel 的健康检查
description:  如何在 Kubernetes 中启用 Citadel 的健康检查。
weight: 70
keywords: [security,health-check]
---

你可以启用 Citadel 的健康检查功能去检测 Citadel CSR（证书签名请求）服务是否有故障。当检测到服务发生故障，Kubelet 将自动重启 Citadel 容器。

当健康检查功能被开启，Citadel 中的 **检测器** 模块会定期向 Citadel 的 CSR gRPC 服务发送 CSRs 并校验响应信息以此判断服务的健康状况。如果 Citadel 服务是健康状态，_检测器_ 会更新 _健康状态文件_ 的 _更新时间_ ，否则什么都不做。Citadel 依赖 [Kubernetes 的健康和就绪检测](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)功能，使用命令行检查 pod 中 _健康状态文件_ 的 _更新时间_ 。如果这个文件有一段时间不更新了，Kubelet 将会重启 Citadel 容器。

注意：Citadel 的健康检查目前只提供了对 CSR 服务 API 的支持，如果没有使用 [SDS](/zh/docs/tasks/security/citadel-config/auth-sds/) 或者 [Mesh Expansion](/zh/docs/examples/mesh-expansion/) 就没有必要使用这个功能。

## 开始之前{#before-you-begin}

为了完成这个任务，你可以[安装 Istio](/zh/docs/setup/install/istioctl/)，并设置 `global.mtls.enabled` 为 `true`。

{{< tip >}}
使用[认证策略](/zh/docs/concepts/security/#authentication-policies)为命名空间内的部分或者全部服务配置双向 TLS 支持。在进行全局设置配置时必须对所有命名空间重复一遍。细节可参考[认证策略任务](/zh/docs/tasks/security/authn-policy/)。
{{< /tip >}}

## 部署启用健康检查的 Citadel{#deploying-citadel-with-health-checking}

重新部署 Citadel 启用健康检查：

{{< text bash >}}
$ istioctl manifest generate --set values.global.mtls.enabled=true,values.security.citadelHealthCheck=true > citadel-health-check.yaml
$ kubectl apply -f citadel-health-check.yaml
{{< /text >}}

## 确认健康检查器是否工作{#verify-that-health-checking-works}

Citadel 会记录健康检查的结果，运行下面的命令行：

{{< text bash >}}
$ kubectl logs `kubectl get po -n istio-system | grep istio-citadel | awk '{print $1}'` -n istio-system | grep "CSR signing service"
{{< /text >}}

会看到类似下面这样的输出：

{{< text plain >}}
... CSR signing service is healthy (logged every 100 times).
{{< /text >}}

上面的日志表明周期性的健康检查已经启动。默认的健康检查间隔为 15 秒，每 100 个检查记录一次。

## （可选）健康检查的配置{#optional-configuring-the-health-checking}

这部分的讨论关于如何修改健康检查的配置。打开 `citadel-health-check.yaml` 文件，并定位到下面的内容：

{{< text plain >}}
...
  - --liveness-probe-path=/tmp/ca.liveness # 存活健康检查状态文件的路径
  - --liveness-probe-interval=60s # 存活健康状态文件的更新周期
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

健康状态文件的路径为 `liveness-probe-path` 和 `probe-path`。你应该同时更新在 Citadel 和 `livenessProbe` 中的路径。如果 Citadel 是健康的，`liveness-probe-interval` 的值用于更新健康状态文件的周期。Citadel 的健康检查控制器使用 `probe-check-interval` 的值作为请求 Citadel CSR 服务的周期。`interval` 是自上次更新健康状况文件至今的最长时间，供检测器判断 Citadel 是否健康。`initialDelaySeconds` 和 `periodSeconds` 的值确定初始化延迟以及每次激活 `livenessProbe` 的时间间隔。

延长 `probe-check-interval` 会减少健康检查的开销，但是一旦遇到故障情况，健康监测器也会更晚的得到故障信息。为了避免检测器因为临时故障重启 Citadel，检测器的 `interval` 应该设置为 `liveness-probe-interval` 的 `N` 倍，这样就让检测器能够容忍持续 `N-1` 次的检查失败。

## 清理{#cleanup}

* 在 Citadel 上禁用健康检查：

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.mtls.enabled=true
    {{< /text >}}

