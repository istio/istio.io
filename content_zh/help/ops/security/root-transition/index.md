---
title: 延长自签发证书的有效期
description: 学习如何延长 Istio 自签发根证书的有效期。
weight: 90
keywords: [security, PKI, certificate, Citadel]
---

因为历史原因，Istio 的自签发证书只有一年的有效期。如果你选择使用 Istio 的自签发证书，就需要在它们过期之前订好计划进行根证书的更迭。根证书过期可能会导致集群范围内的意外中断。

{{< tip >}}
我们认为每年更换根证书和密钥是一个安全方面的最佳实践，我们会在后续内容中介绍如何完成根证书和密钥的轮换过程。
{{< /tip >}}

为了了解根证书的剩余有效期，请参考下面[过程中的第一步](#root-transition-procedure)。

我们提供了下面的过程，用于完成根证书更新工作。Envoy 进程不需要进行重启来载入新的根证书，也就不会影响长链接了。要了解 Envoy 的热重启过程及其影响范围，请参考相关的[文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart)和[博客](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)。

## 场景 {#scenarios}

如果目前没有使用双向 TLS 功能，未来也不准备使用，那么无需进行任何操作。可以选择升级到 1.0.8、1.1.8 或者更晚的版本，避免未来产生这一问题。

如果目前没有使用双向 TLS，但是未来准备采用，建议跟随下列步骤进行更新。

如果目前正在使用自签署证书支持的双向 TLS，请跟随下面的步骤进行操作，并检查当前部署是否受到影响。

## 根证书迁移过程 {#root-transition-procedure}

1. 检查根证书是否过期：

    下载[脚本](https://raw.githubusercontent.com/istio/tools/master/bin/root-transition.sh)到一个包含有 `kubectl` 并能以此访问集群的机器上。

    {{< text bash>}}
    $ wget https://raw.githubusercontent.com/istio/tools/master/bin/root-transition.sh
    $ chmod +x root-transition.sh
    $ ./root-transition.sh check
    ...
    ===YOU HAVE 30 DAYS BEFORE THE ROOT CERT EXPIRES!=====
    {{< /text >}}

    在根证书到期之前执行剩余步骤，以防系统停机。

1. 执行根证书更新过程：

    在更新过程中，Envoy 会用热重启的方式来载入新的证书。这可能对流量产生一定影响。
    可以阅读 Envoy 热启动方面的相关[文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/hot_restart)和[博客](https://blog.envoyproxy.io/envoy-hot-restart-1d16b14555b5)，来了解更多细节。

    {{< warning >}}
    如果你的 Pilot 没有 Envoy Sidecar，则应该给 Pilot 安装一个 Sidecar。这是因为 Pilot 在使用旧的根证书来验证新的工作负载证书时会出现问题，导致 Pilot 和 Evnoy 之间断开连接。请参考[相关步骤](#how-to-check-if-pilot-has-an-envoy-sidecar)，以了解如何进行检查。[Istio 升级指南](/zh/docs/setup/kubernetes/upgrade/steps/)中缺省会为 Pilot 安装 Envoy Sidecar。
    {{< /warning >}}

    {{< text bash>}}
    $ ./root-transition.sh transition
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

1. 检查为工作负载新生成的证书：

    {{< text bash>}}
    $ ./root-transition.sh verify
    ...
    Checking the current root CA certificate is propagated to all the Istio-managed workload secrets in the cluster.
    Root cert MD5 is 8fa8229ab89122edba73706e49a55e4c
    Checking namespace: default
      Secret default.istio.default is updated.
      Secret default.istio.sleep is updated.
    Checking namespace: istio-system
      Secret istio-system.istio.default is updated.
      ...
    ------All Istio keys and certificates are updated in secret!
    {{< /text >}}

    Citadel 的证书分发过程需要一段时间来完成，因此命令失败，可以在几分钟之后再次尝试。

1. 升级到 Istio 1.0.8、1.1.8 或更新的版本:

    {{< warning >}}
    这一步骤能够确保控制平面组件和 Envoy Sidecar 全部载入新的证书和密钥
    {{< /warning >}}

    将控制平面和 `istio-proxy` 升级到 1.0.8、1.1.8 或更新的版本。请依照 [Istio 更新过程](/docs/setup/kubernetes/upgrade/steps/)的介绍来完成这一步骤。

1. 检查 Envoy 是否已经载入新的工作负载证书：

    可以检查一下，Envoy 是否收到了新的证书。要检查命名空间 `bar` 之中一个名为 `foo` 的 Pod，验证它的 Envoy 证书的过程：

    {{< text bash>}}
    $ kubectl exec -it foo -c istio-proxy -n bar -- curl http://localhost:15000/certs | head -c 1000
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

    查看 `ca_cert` 中的 `valid_from`。如果它符合步骤 2 中新证书的 `Not Before` 内容，则说明 Envoy 已经载入了新的根证书。

## 常见问题

### 我是不是可以先升级到 Istio 1.0.8、1.1.8 或者更新的版本之后，然后再更新根证书？

是的。可以照常升级到 Istio 1.0.8、1.1.8 或者更新的版本。在升级之后，根据步骤 4 中的内容完成根证书更新，手工重启 Galley、Pilot 以及 sidecar-injector，从而载入新的根证书。

### 为什么我的工作负载没有载入新证书（步骤 5）？

首先确认在步骤 4 中把 `istio-proxy` 升级到了 Istio 1.0.8、1.1.8 或者更新的版本。

{{< warning >}}
如果使用的是 Istio 1.1.3-1.1.7，Envoy 可能不会因为新证书的生成而进行热重启。
{{< /warning >}}

### 为什么我的 Pilot 不工作，并在日志中输出 “handshake error”？

这可能是因为启用 `controlPlaneSecurity` 的同时，Pilot 没有配置 [Envoy Sidecar](#how-to-check-if-pilot-has-an-envoy-sidecar)。这种情况下，需要重启 Galley 和 Pilot 来保证它们载入了新证书。例如下面的命令通过删除 Pod 的方式重新部署 Galley 和 Pilot：

    {{< text bash>}}
    $ kubectl delete po <galley-pod> -n istio-system
    $ kubectl delete po <pilot-pod> -n istio-system
    {{< /text >}}

### 如何检查 Pilot 的 Sidecar {#how-to-check-if-pilot-has-an-envoy-sidecar}

如果下面的命令中显示 `1/1`，说明 Pilot 没有 Sidecar；如果是 `2/2`，就表明 Pilot 是带有 Sidecar 的。

    {{< text bash>}}
    $ kubectl get po -l istio=pilot -n istio-system
    istio-pilot-569bc6d9c-tfwjr   1/1     Running   0          11m
    {{< /text >}}

### 无法使用 sidecar-injector 部署新的工作负载

如果没有更新到 Istio 1.0.8、1.1.8 或者更新的版本，就有可能出现这种情况。请试着重新启动 Sidecar injector，重启之后就会载入证书：

{{< text bash>}}
$ kubectl delete po -l istio=sidecar-injector -n istio-system
pod "istio-sidecar-injector-788bd8fc48-x9gdc" deleted
{{< /text >}}
