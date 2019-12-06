---
title: 延长自签名证书的寿命
description: 学习如何延长 Istio 自签名根证书的寿命。
weight: 90
keywords: [security, PKI, certificate, Citadel]
aliases:
  - /zh/help/ops/security/root-transition
  - /zh/docs/ops/security/root-transition
---

Istio 自签名证书历来具有 1 年的默认寿命。
如果您使用 Istio 自签名证书，您需要注意根证书的到期日期。
根证书的过期可能会导致集群范围内的意外中断。

请参考[下列步骤](#root-transition-procedure)的第一步来计算您的根证书的剩余寿命。

下列步骤将向您展示如何转换到一个新的根证书。
转换完成后，新的根证书将有 10 年的寿命。
注意 Envoy 实例将会热重启来重新加载新的根证书，这可能会对长连接造成影响。
请参考[这里](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart)和[这里](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)来了解这些影响和 Envoy 热重启的原理。

## 方案{#scenarios}

如果您目前在 Istio 中没使用双向 TLS 功能，并且将来也没打算用，您将不受影响，也无需任何动作。

如果您将来可能会使用双向 TLS 功能，您应该按照下列步骤来转换根证书。

如果您选择已经在 Istio 中使用了带有自签名证书的双向 TLS 功能，请按照下列步骤检查您是否会受到影响。

## 根转换过程{#root-transition-procedure}

1. 检查根证书的过期时间：

    在一台有能访问集群的 `kubectl` 工具的机器上下载[脚本](https://raw.githubusercontent.com/istio/tools/{{< source_branch_name >}}/bin/root-transition.sh)。

    {{< text bash>}}
    $ wget https://raw.githubusercontent.com/istio/tools/{{< source_branch_name >}}/bin/root-transition.sh
    $ chmod +x root-transition.sh
    $ ./root-transition.sh check-root
    ...
    =====YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRES!=====
    {{< /text >}}

    在根证书过期之前执行剩下的步骤，以避免系统中断。

1. 检查您的 sidecars 的版本，如果需要就将它升级：

    一些早期的 Istio sidecar 版本不会自动重载新的根证书。
    请运行以下命令检查您的 Istio sidecars 的版本。

    {{< text bash>}}
    $ ./root-transition.sh check-version
    Checking namespace: default
    Istio proxy version: 1.3.5
    Checking namespace: istio-system
    Istio proxy version: 1.3.5
    Istio proxy version: 1.3.5
    ...
    {{< /text >}}

    如果您的 sidecars 的版本低于 1.0.8 和 1.1.8，请升级 Istio 控制面板和 sidecars 的版本到不低于 1.0.8 和 1.1.8。
    请参考 Istio [升级步骤](/zh/docs/setup/upgrade/)或您的云服务提供商提供的步骤来升级。

1. 执行根证书转换：

    在转换的过程中，Envoy sidecars 可能会热重启来重载新证书。
    这可能会影响您的流量。请参考 [Envoy 热重启](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart)并阅读[这篇博客](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)来获得更多细节。

    {{< warning >}}
    如果您的 Pilot 没有配置 Envoy sidecar，考虑为它安装一个。
    因为 Pilot 在使用旧的根证书验证新的工作负载证书时有问题，这可能会导致 Pilot 与 Envoy 断开连接。
    如何检测该条件请参考[这儿](#how-can-i-check-if-pilot-has-a-sidecar)。
    [Istio 升级指南](/zh/docs/setup/upgrade/)默认会为 Pilot 安装 Envoy sidecar。
    {{< /warning >}}

    {{< text bash>}}
    $ ./root-transition.sh root-transition
    Create new ca cert, with trust domain as cluster.local
    Wed Jun  5 19:11:15 PDT 2019 delete old ca secret
    secret "istio-ca-secret" deleted
    Wed Jun  5 19:11:15 PDT 2019 create new ca secret
    secret/istio-ca-secret created
    pod "istio-citadel-8574b88bcd-j7v2d" deleted
    Wed Jun  5 19:11:18 PDT 2019 restarted Citadel, checking status
    NAME                             READY     STATUS    RESTARTS   AGE
    istio-citadel-8574b88bcd-l2g74   1/1       Running   0          3s
    New root certificate:
    Certificate:
        Data:
            ...
            Validity
                Not Before: Jun  6 03:24:43 2019 GMT
                Not After : Jun  3 03:24:43 2029 GMT
            Subject: O = cluster.local
            ...
    Your old certificate is stored as old-ca-cert.pem, and your private key is stored as ca-key.pem
    Please save them safely and privately.
    {{< /text >}}

1. 确认新的工作负载证书已经创建：

    {{< text bash>}}
    $ ./root-transition.sh verify-certs
    ...
    Checking the current root CA certificate is propagated to all the Istio-managed workload secrets in the cluster.
    Root cert MD5 is 8fa8229ab89122edba73706e49a55e4c
    Checking namespace: default
      Secret default.istio.default matches current root.
      Secret default.istio.sleep matches current root.
    Checking namespace: istio-system
      Secret istio-system.istio.default matches current root.
      ...

    =====All Istio mutual TLS keys and certificates match the current root!=====

    {{< /text >}}

    如果命令执行失败，请等一会重新执行。Citadel 传播证书需要一些时间。

1. 确认 Envoy 已经加载了新的工作负载证书：

    您可以确认 Envoy 是否已经收到新的证书。
    下面是如何检查 Envoy 中某个 pod 的证书的命令示例。

    {{< text bash>}}
    $ kubectl exec [YOUR_POD] -c istio-proxy -n [YOUR_NAMESPACE] -- curl http://localhost:15000/certs | head -c 1000
    {
     "certificates": [
      {
       "ca_cert": [
          ...
          "valid_from": "2019-06-06T03:24:43Z",
          "expiration_time": ...
       ],
       "cert_chain": [
        {
          ...
        }
    {{< /text >}}

    请检查 `ca\_cert` 的 `valid\_from` 的值。
    如果它能匹配上步骤 3 中显示的新证书的 `_Not_ _Before_` 的值，那么您的 Envoy 已经加载了新的根证书。

## 问题排查{#troubleshooting}

### 为何工作负载无法获得新的证书？{#why-are-not-workloads-picking-up-the-new-certificates-in-step-5}

请确定您已经在步骤 2 中将 `istio-proxy` sidecars 更新至 1.0.8，1.1.8 或更新版本。

{{< warning >}}
如果您使用 Istio 1.1.3 - 1.1.7 版本，Envoy 可能不会在新证书创建后热重启。
{{< /warning >}}

### 为何 Pilot 无法工作并输出 “handshake error” 日志？{#why-does-pilot-not-work-and-log-handshake-error}

这可能是因为启用 `controlPlaneSecurity` 后，Pilot [没有使用 Envoy sidecar](#how-can-i-check-if-pilot-has-a-sidecar)。
这种情况下，重启 Galley 和 Pilot 以保证他们加载了新的证书。
下列命令会通过删除 pod 来重新部署 Galley 和 Pilot 的 pod 作为示例。

{{< text bash>}}
$ kubectl delete po <galley-pod> -n istio-system
$ kubectl delete po <pilot-pod> -n istio-system
{{< /text >}}

### 如何判断 Pilot 有 sidecar？{#how-can-i-check-if-pilot-has-a-sidecar}

如果下列命令显示 `1/1`，意味着您的 Pilot 没有 Envoy sidecar，
否则，如果它显示 `2/2`，您的 Pilot 正在使用 Envoy sidecar。

{{< text bash>}}
$ kubectl get po -l istio=pilot -n istio-system
istio-pilot-569bc6d9c-tfwjr   1/1     Running   0          11m
{{< /text >}}

### 为何我无法用 sidecar-injector 部署新的工作负载？{#why-cant-i-deploy-new-workloads-with-the-sidecar-injector}

这可能是因为您没有升级到 1.0.8，1.1.8 或更新版本。
试着重启 sidecar injector。
重启后 sidecar injector 会重新加载证书：

{{< text bash>}}
$ kubectl delete po -l istio=sidecar-injector -n istio-system
pod "istio-sidecar-injector-788bd8fc48-x9gdc" deleted
{{< /text >}}
