---
title: Citadel 的健康检查
description:  如何在 Kubernetes 中启用 Citadel 的健康检查。
weight: 70
keywords: [security,health-check]
---

本文中的任务展示了如何在 Kubernetes 中为 Citadel 启动健康检查，注意，这一功能仍处于 Alpha 阶段。

从 Istio 0.6 开始，Citadel 具备了一个可选的健康检查功能。缺省情况下的 Istio 部署过程没有启用这一特性。目前健康检查功能通过周期性的向 API 发送 CSR 的方式，来检测 Citadel CSR 签署服务的故障。很快会实现更多的健康检查方法。

Citadel 包含了一个检测器模块，它会周期性的检查 Citadel 的状态（目前只是 gRPC 服务器的健康情况）。如果 Citadel 是健康的，检测器客户端会更新健康状态文件（文件内容始终为空）的更新时间。否则就什么都不做。Citadel 依赖 [Kubernetes 的健康和就绪检测](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)功能，会周期性的使用命令行检查健康状态文件的更新时间。如果这个文件有一段时间不更新了，Citadel 容器就会被 Kubelet 的重新启动。

注意：Citadel 的健康检查目前只提供了对 CSR 服务 API 的支持，如果没有使用 [Istio Mesh Expansion](/docs/setup/kubernetes/mesh-expansion/) （这个特性需要 CSR 服务接口的支持）就没有必要使用这个功能了。

## 开始之前

* 根据[快速开始](/docs/setup/kubernetes/quick-start/)的指引部署 Istio 并启用全局双向 TLS 支持。

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

    _**或者**_

    用 [Helm](/docs/setup/kubernetes/helm-install/) 进行部署，设置 `global.mtls.enabled` 为 `true`。

> Istio 0.7 开始，可以使用[认证策略](/docs/concepts/security/authn-policy/)为命名空间内的部分或者全部服务配置双向 TLS 支持（在所有命名空间重复一遍就算是全局配置了）。请参考[认证策略任务](/docs/tasks/security/authn-policy/)

## 部署启用健康检查的 Citadel

下面的命令用来部署启用健康检查的 Citadel：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-citadel-with-health-check.yaml
{{< /text >}}

部署 `istio-citadel` 服务，这样健康检查器才能找到 CSR 服务.

{{< text bash >}}
$ cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: istio-citadel
  namespace: istio-system
  labels:
    istio: citadel
spec:
  ports:
    - port: 8060
  selector:
    istio: citadel
EOF
{{< /text >}}

## 确认健康检查器的是否工作

Citadel 会记录健康检查的结果，运行下面的命令行：

{{< text bash >}}
$ kubectl logs `kubectl get po -n istio-system | grep istio-citadel | awk '{print $1}'` -n istio-system
{{< /text >}}

会看到类似下面这样的输出：

{{< text plain >}}
...
2018-02-27T04:29:56.128081Z     info    CSR successfully signed.
...
2018-02-27T04:30:11.081791Z     info    CSR successfully signed.
...
2018-02-27T04:30:25.485315Z     info    CSR successfully signed.
...
{{< /text >}}

上面的日志表明周期性的健康检查已经启动。可以看到，缺省的健康检查的时间周期是 15 秒。

## (可选) 健康检查的配置

还可以根据需要调整健康检查的配置。打开文件 `install/kubernetes/istio-citadel-with-health-check.yaml`，找到下面的内容（注释已汉化，非原文）：

{{< text plain >}}
...
  - --liveness-probe-path=/tmp/ca.liveness # 健康检查状态文件的路径
  - --liveness-probe-interval=60s # 健康状态文件的更新周期
  - --probe-check-interval=15s    # 健康检查的周期
  - --logtostderr
  - --stderrthreshold
  - INFO
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

* `liveness-probe-path` 和 `probe-path`：到健康状态文件的路径，在 Citadel 以及检测器上进行配置；
* `liveness-probe-interval`：是更新健康状态文件的周期；
* `probe-check-interval`：是 Citadel 健康检查的周期；
* `interval`：从上次更新健康状态文件至今的时间，也就是检测器认为 Citadel 健康的时间段；
* `initialDelaySeconds` 以及 `periodSeconds`：初始化延迟以及检测运行周期；

延长 `probe-check-interval` 会减少健康检查的开销，但是一旦遇到故障情况，健康监测器也会更晚的得到故障信息。为了避免检测器因为临时故障重启 Citadel，检测器的 `interval` 应该设置为 `liveness-probe-interval` 的 `N` 倍，这样就让检测器能够容忍持续 `N-1` 次的检查失败。

## 清理

* 在 Citadel 上禁用健康检查：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
    $ kubectl delete svc istio-citadel -n istio-system
    {{< /text >}}

* 移除 Citadel：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-citadel-with-health-check.yaml
    $ kubectl delete svc istio-citadel -n istio-system
    {{< /text >}}
