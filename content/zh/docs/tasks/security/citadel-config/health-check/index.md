---
title: Citadel 健康检查
description:  如何在 Kubernetes 中启用Citadel健康检查
weight: 20
keywords: [security,health-check]
aliases:
    - /docs/tasks/security/health-check/
---

您可以通过启用 Citadel 的健康检查特性来探测 Citadel CSR(证书签名请求)服务的故障。当故障被探测到后，Kubelet 就会自动重启 Citadel 容器。

当健康检查特性启用后， Citadel 中的 **prober client** 模块会定期检查 Citadel 的 CSR gRPC server 的健康状态。
通过发送 CSRs 到 gRPC server ，验证它的响应信息。
如果 Citadel 是健康的，那么 _prober client_ 就会更新 _health status file_ 的 _modification time_ 。
否则，什么也不做。Citadel 依赖 [Kubernetes liveness and readiness probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)，使用命令检查 pod 中  _modification time_ 的  _health status file_ 。
如果文件一定时间内没有被更新，Kubelet 将会重启 Citadel 容器。

{{< tip >}}
目前 Citadel 健康检查只监控 CSR 服务 API 的健康状态，如果生产环境设置没有用到 [SDS](/docs/tasks/security/citadel-config/auth-sds/) or [adding virtual machines](/docs/examples/virtual-machines/) ，那么就不需要这个特性。
{{< /tip >}}

## 开始之前{#before-you-begin}

按照  [Istio installation guide](/docs/setup/install/istioctl/) 安装 Istio 并启用双向 TLS 。

## 部署Citadel和健康检查{#deploying-citadel-with-health-checking}

重新部署 Citadel ，使健康检查生效:

{{< text bash >}}
$ istioctl manifest generate --set values.global.mtls.enabled=true,values.security.citadelHealthCheck=true > citadel-health-check.yaml
$ kubectl apply -f citadel-health-check.yaml
{{< /text >}}

## 验证健康检查是否生效{#verify-that-health-checking-works}

Citadel 会记录健康检查结果日志。运行如下命令：

{{< text bash >}}
$ kubectl logs `kubectl get po -n istio-system | grep istio-citadel | awk '{print $1}'` -n istio-system | grep "CSR signing service"
{{< /text >}}

您将会看到类似下面的输出：

{{< text plain >}}
... CSR signing service is healthy (logged every 100 times).
{{< /text >}}

上面的日志表明健康检查正在周期运行。
健康检查默认间隔是15秒且每100次检查记录一次日志。

## (可选)配置健康检查 {#configuring-the-health-checking}

这部分讨论如何修改健康检查配置。打开 `citadel-health-check.yaml` 文件并定位下面的行。

{{< text plain >}}
...
  - --liveness-probe-path=/tmp/ca.liveness # path to the liveness health checking status file
  - --liveness-probe-interval=60s # interval for health checking file update
  - --probe-check-interval=15s    # interval for health status check
livenessProbe:
  exec:
    command:
    - /usr/local/bin/istio_ca
    - probe
    - --probe-path=/tmp/ca.liveness # path to the liveness health checking status file
    - --interval=125s               # the maximum time gap allowed between the file mtime and the current sys clock.
  initialDelaySeconds: 60
  periodSeconds: 60
...
{{< /text >}}

与健康状态文件相关的 path 项有 `liveness-probe-path`  和 `probe-path`。
您应该在更新 Citadel 中的这些 paths 的同时，更新` livenessProbe` 。
如果 Citadel 是健康的，那么 `liveness-probe-interval` 项的值指定了更新健康状态文件的时间间隔。
Citadel 健康检查控制器使用 `probe-check-interval` 项的值指定调用 Citadel CSR 服务的时间间隔。
这个时间间隔是最近一次探针认为 Citadel 处于健康状态并更新健康状态文件后过去的最大时间。
`initialDelaySeconds` 和 `periodSeconds` 这两项的值分别指定了初始延迟时间和`livenessProbe` 每次触发的时间间隔；

延长 `probe-check-interval`  会减少健康检查的系统开支，但是这也会延长探针感知非健康状态的滞后时间。
为了防止探针因为暂时不可用重启 Citadel ，探针的间隔时间可以配置成大于 `liveness-probe-interval` 的 N 倍。这将会允许探针容忍N-1次持续失败的健康检查。

## 清除{#cleanup}

* 停用 Citadel 的健康检查：

    {{< text bash >}}
    $ istioctl manifest apply --set values.global.mtls.enabled=true
    {{< /text >}}

