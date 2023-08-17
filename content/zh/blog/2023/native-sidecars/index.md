---
title: 在 Istio 中使用 Kubernetes 原生 Sidecar
description: 使用 Istio 演示新的 SidecarContainers 功能。
publishdate: 2023-08-15
attribution: "John Howard (Google); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,sidecars,kubernetes]
---

如果您曾经听说过有关服务网格的些许信息，
那就会知道它是以 Sidecar 模式工作的：与应用代码并列部署一个代理服务器。
Sidecar 就是这样：它是一种模式。在今日（8 月 15 日，即 Kubernetes 1.28 正式发版之日）之前，Kubernetes 对 Sidecar 容器从未有任何形式的正式支持。

这导致了许多问题：如果您有一个按照预期终止的 Job，
但由于 Sidecar 容器却不能达到这个预期，该怎么办？这是
[Kubernetes Issue 跟踪器上最受欢迎的](https://github.com/kubernetes/kubernetes/issues/25908)具体使用场景。

在 Kubernetes 中添加 Sidecar 支持的提案于 2019 年正式提出。
一路走来，经历了许多停顿，在去年该项目重新启动后，对 Sidecar
的正式支持将以 Alpha 功能发布在 Kubernetes 1.28 中。
Istio 已经实现了对此功能的支持，在本文中您可以了解如何利用其优势。

## Sidecar 的困境 {#sidecar-woes}

Sidecar 容器提供了强大的功能，但也存在一些问题。
虽然 Pod 内的容器可以共享一些资源，但这些资源的**生命周期**是完全解耦的。
对于 Kubernetes 来说，这两种容器在功能上是相同的。

然而，在 Istio 中，它们并不相同 — Istio 容器必须以主应用程序容器正常运行为前提，
如果没有主应用程序容器，那么 Istio 容器就没有任何价值。

这种期望的不匹配会导致各种问题：

* 如果应用程序容器启动速度比 Istio 容器快，则应用程序容器将无法访问网络。
  这在 Istio 的 GitHub 上以压倒性优势赢得了[最多 +1](https://github.com/istio/istio/issues/11130)。
* 如果 Istio 容器先于应用程序容器关闭，则应用程序容器无法访问网络。
* 如果应用程序容器有意退出（通常是在 `Job` 中使用），Istio 容器仍将运行并保持 Pod 无限期运行。
  这也是一个 [GitHub 中的顶级 Issue](https://github.com/istio/istio/issues/11659)。
* 在 Istio 容器启动之前运行的 `InitContainers` 将无法访问网络。

虽然 Istio 社区内外花费了无数时间来解决这些问题，但取得的成果仍然有限。

## 从根源解决 {#fixing-the-root-cause}

虽然 Istio 中日益复杂的变通方案可以帮助减轻 Istio 用户的痛苦，
但理想情况下，所有相关情况下都应该正常运转 - 而不仅仅是针对 Istio。
幸运的是，Kubernetes 社区一直努力直接在 Kubernetes 中解决这些问题。

在 Kubernetes 1.28 中，合并了一项为 Sidecar 添加原生支持的新功能，
这为 5 年多的持续工作画上了句号。通过该功能，我们的所有问题都可以得到解决，而无需其他变通方案！

当我们进入“GitHub Issue 名人堂”时，
[这些](https://github.com/kubernetes/kubernetes/issues/25908)在所有 Kubernetes Issue
中的 #1 和 #6 的两个 [Issue](https://github.com/kubernetes/kubernetes/issues/65502) - 终于被关闭了！

特别感谢让这个功能冲过终点线的众多贡献者。

## 尝试一下 {#trying-it-out}

虽然 Kubernetes 1.28 刚刚发布，新的 `SidecarContainers` 功能还处于
Alpha 阶段（因此默认情况下处于关闭状态），而且 Istio
中对该功能的支持尚未发布，
但我们今天仍然可以尝试一下 - 只是不要在生产环境中尝试！

首先，我们需要启动 Kubernetes 1.28 集群，并启用 `SidecarContainers` 功能：

{{< text shell >}}
$ cat <<EOF | kind create cluster --name sidecars --image gcr.io/istio-testing/kind-node:v1.28.0 --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  SidecarContainers: true
EOF
{{< /text >}}

然后我们可以下载最新的 Istio 1.19 预发布版（因为 1.19 尚未发布）。
我使用的是 Linux。这是 Istio 的预发行版，因此再次强调 - 不要在生产环境中尝试此操作！
当我们安装 Istio 时，我们将启用原生 Sidecar 功能的支持标志，并打开访问日志用于帮助后续演示。

{{< text shell >}}
$ TAG=1.19.0-beta.0
$ curl -L https://github.com/istio/istio/releases/download/$TAG/istio-$TAG-linux-amd64.tar.gz | tar xz
$ ./istioctl install --set values.pilot.env.ENABLE_NATIVE_SIDECARS=true -y --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

最后我们可以部署一个工作负载：

{{< text shell >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml
{{< /text >}}

让我们看看 Pod 情况：

{{< text shell >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-7656cf8794-8fhdk   2/2     Running   0          51s
{{< /text >}}

乍一看，一切都很正常……，但如果我们深入观察，就能看到其中的魔力。

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME                     INIT                     CONTAINERS
sleep-7656cf8794-8fhdk   istio-init,istio-proxy   sleep
{{< /text >}}

在这里我们可以看到 Pod 中的所有 `containers` 和 `initContainers`。

令人惊喜的是！`istio-proxy` 现在以一个 `initContainer` 方式存在。

更具体地说，它是一个被设置了 `restartPolicy: Always` 的 `initContainer`
（一个新字段，随着 `SidecarContainers` 功能被启用）。
该设置告诉 Kubernetes 将其视为 Sidecar。

这意味着在代理容器准备好之前，`initContainers` 以及 `containers` 中的所有后续容器将不会被启动。
此外，即使代理容器仍在运行，Pod 也可以被终止。

### Init 容器流量 {#init-container-traffic}

为了测试这一点，我们让 Pod 真正做一些事情。这里我们部署了一个简单的 Pod，
它在 `initContainer` 中发送请求。通常情况下，这会失败。

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  initContainers:
  - name: check-traffic
    image: istio/base
    command:
    - curl
    - httpbin.org/get
  containers:
  - name: sleep
    image: istio/base
    command: ["/bin/sleep", "infinity"]
{{< /text >}}

检查代理容器，我们可以看到请求均成功并通过了 Istio Sidecar：

{{< text shell >}}
$ kubectl logs sleep -c istio-proxy | tail -n1
[2023-07-25T22:00:45.703Z] "GET /get HTTP/1.1" 200 - via_upstream - "-" 0 1193 334 334 "-" "curl/7.81.0" "1854226d-41ec-445c-b542-9e43861b5331" "httpbin.org" ...
{{< /text >}}

如果我们检验 Pod，我们可以看到 Sidecar 当前在 `check-traffic` `initContainer` 之前运行：

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME    INIT                                  CONTAINERS
sleep   istio-init,istio-proxy,check-traffic   sleep
{{< /text >}}

### 退出 Pod {#exiting-pods}

之前，我们提到当应用程序退出时（常见于 `Job`），Pod 将永远存在。
幸运的是，这个问题也得到了解决！

首先我们部署一个 Pod，它将在一秒后退出并且不会重新启动：

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  name: sleep
spec:
  restartPolicy: Never
  containers:
- name: sleep
  image: istio/base
  command: ["/bin/sleep", "1"]
{{< /text >}}

我们可以观察它的进展：

{{< text shell >}}
$ kubectl get pods -w
NAME    READY   STATUS     RESTARTS   AGE
sleep   0/2     Init:1/2   0          2s
sleep   0/2     PodInitializing   0          2s
sleep   1/2     PodInitializing   0          3s
sleep   2/2     Running           0          4s
sleep   1/2     Completed         0          5s
sleep   0/2     Completed         0          12s
{{< /text >}}

在这里我们可以看到应用程序容器退出了，不久之后 Istio 的 Sidecar 容器也退出了。
在此之前，Pod 会停留在 `Running` 状态，而现在它可以转换为 `Completed`。不再有僵尸 Pod 存在！

## Ambient 模式又当如何？ {#what-about-ambient-mode}

去年，Istio 宣布了 [Ambient 模式](/zh/blog/2022/introducing-ambient-mesh/) - Istio
的一种新数据平面模式，不依赖 Sidecar 容器。那么随着 Ambient 模式的到来，这一切还重要吗？

我会大声地告诉大家“重要”！

虽然当 Ambient 模式用于工作负载时，Sidecar 的影响会减轻，
但我预计几乎所有大规模 Kubernetes 集群的用户在其部署中都会存在某种 Sidecar。
这可能是他们不想迁移到 Ambient 模式的 Istio 工作负载、尚未完成迁移的工作负载或与 Istio 无关的内容。
因此，虽然这种情况可能较少，但对于使用 Sidecar 的情况来说，这仍然是一个巨大的改进。

您可能想了解的相反情况 - 如果我们所有的 Sidecar 问题都得到解决，
为什么我们还需要 Ambient 模式？解决了这些边车限制后，Ambient 仍然带来了多种好处。
例如，[这篇博文](/zh/blog/2023/waypoint-proxy-made-simple/)详细介绍了将代理与工作负载分离的必要性。

## 自己尝试一下 {#try-it-out-yourself}

我们鼓励有冒险精神的读者在测试环境中亲自尝试！对这些实验性和 Alpha
功能的反馈对于确保它们稳定并在推广之前满足预期至关重要。如果您做了尝试，
请让我们通过 [Istio Slack](/zh/get-involved/) 得知您的想法！

Kubernetes 团队特别有兴趣了解更多有关以下内容的信息：

* 当涉及多个 Sidecar 时，对关闭序列的处理。
* Sidecar 容器崩溃时的退避重启处理。
* 他们尚未考虑的边缘情况。
