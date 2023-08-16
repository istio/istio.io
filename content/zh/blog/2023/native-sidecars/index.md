---
title: Istio 中的 Kubernetes Native Sidecar
description: 使用 Istio 演示新的 SidecarContainer 功能。
publishdate: 2023-08-15
attribution: "John Howard (Google)"
keywords: [istio,sidecars,kubernetes]
---

If you have heard anything about service meshes, it is that they work using the sidecar pattern: a proxy server is deployed alongside your application code. The sidecar pattern is just that: a pattern. Up until this point, there has been no formal support for sidecar containers in Kubernetes at all.
如果您听说过有关服务网格的任何信息，那就是它们使用 sidecar 模式工作：代理服务器与您的应用程序代码一起部署。 Sidecar 模式就是这样：一种模式。 到目前为止，Kubernetes 中还没有对 sidecar 容器的正式支持。

This has caused a number of problems: what if you have a job that terminates by design, but a sidecar container that doesn't? This exact use case is the [most popular ever on the Kubernetes issue tracker](https://github.com/kubernetes/kubernetes/issues/25908).
这导致了许多问题：如果您有一个按设计终止的作业，但一个 sidecar 容器却没有，该怎么办？ 这个确切的用例是 [Kubernetes 问题跟踪器上最受欢迎的用例](https://github.com/kubernetes/kubernetes/issues/25908)。

A formal proposal for adding sidecar support in Kubernetes was raised in 2019. With many stops and starts along the way, and after a reboot of the project last year, formal support for sidecars is being released to Alpha in Kubernetes 1.28. Istio has implemented support for this feature, and in this post you can learn how to take advantage of it.
在 Kubernetes 中添加 Sidecar 支持的正式提案于 2019 年提出。一路走来，经历了许多停顿，去年项目重新启动后，对 Sidecar 的正式支持将在 Kubernetes 1.28 中发布到 Alpha。 Istio 已经实现了对此功能的支持，在这篇文章中您可以了解如何利用它。

## Sidecar woes
## Sidecar 的困境

Sidecar containers give a lot of power, but come with some issues. While containers within a pod can share some things, their *lifecycle's* are entirely decoupled. To Kubernetes, both of these containers are functionally the same.
Sidecar 容器提供了强大的功能，但也存在一些问题。 虽然 Pod 内的容器可以共享一些东西，但它们的“生命周期”是完全解耦的。 对于 Kubernetes 来说，这两个容器在功能上是相同的。

However, in Istio they are not the same - the Istio container is required for the primary application container to run, and has no value without the primary application container.
然而，在 Istio 中，它们并不相同——Istio 容器是主应用程序容器运行所必需的，如果没有主应用程序容器，Istio 容器就没有任何价值。

This mismatch in expectation leads to a variety of issues:
这种期望的不匹配会导致各种问题：

* If the application container starts faster than Istio's container, it cannot access the network. This wins the [most +1's](https://github.com/istio/istio/issues/11130) on Istio's GitHub by a landslide.
* 如果应用程序容器启动速度比 Istio 的容器快，则无法访问网络。 这在 Istio 的 GitHub 上以压倒性优势赢得了[最多 +1](https://github.com/istio/istio/issues/11130)。
* If Istio's container shuts down before the application container, the application container cannot access the network.
* 如果 Istio 的容器先于应用程序容器关闭，则应用程序容器无法访问网络。
* If an application container intentionally exits (typically from usage in a `Job`), Istio's container will still run and keep the pod running indefinitely. This is also a [top GitHub issue](https://github.com/istio/istio/issues/11659).
* 如果应用程序容器有意退出（通常是在“Job”中使用），Istio 的容器仍将运行并保持 pod 无限期运行。 这也是一个[GitHub 顶级问题](https://github.com/istio/istio/issues/11659)。
* `InitContainers`, which run before Istio's container starts, cannot access the network.
* 在 Istio 容器启动之前运行的 `InitContainers` 无法访问网络。

Countless hours have been spent in the Istio community and beyond to work around these issues - to limited success.
Istio 社区内外花费了无数时间来解决这些问题，但取得的成果有限。

## Fixing the root cause
## 解决根本原因

While increasingly-complex workarounds in Istio can help alleviate the pain for Istio users, ideally all of this would just work - and not just for Istio. Fortunately, the Kubernetes community has been hard at work to address these directly in Kubernetes.
虽然 Istio 中日益复杂的解决方法可以帮助减轻 Istio 用户的痛苦，但理想情况下，所有这些都可以正常工作 - 而不仅仅是 Istio。 幸运的是，Kubernetes 社区一直在努力直接在 Kubernetes 中解决这些问题。

In Kubernetes 1.28, a new feature to add native support for sidecars was merged, closing out over 5 years of ongoing work. With this merged, all of our issues can be addressed without workarounds!
在 Kubernetes 1.28 中，合并了一项为 sidecar 添加本机支持的新功能，结束了 5 年多的持续工作。 通过合并，我们所有的问题都可以得到解决，无需解决方法！

While we are on the "GitHub issue hall of fame", [these](https://github.com/kubernetes/kubernetes/issues/25908) two [issues](https://github.com/kubernetes/kubernetes/issues/65502) account for #1 and #6 all time issues in Kubernetes - and have finally been closed!
当我们进入“GitHub 问题名人堂”时，[这些](https://github.com/kubernetes/kubernetes/issues/25908) 两个[问题](https://github.com/kubernetes/kubernetes/ issues/65502）解决了 Kubernetes 中所有时间问题中的 #1 和 #6 - 并且终于被关闭了！

A special thanks goes to the huge group of individuals involved in getting this past the finish line.
特别感谢参与冲过终点线的众多个人。

## Trying it out
## 尝试一下

While Kubernetes 1.28 was just released, the new `SidecarContainers` feature is Alpha (and therefore, off by default), and the support for the feature in Istio is not yet shipped, we can still try it out today - just don't try this in production!
虽然 Kubernetes 1.28 刚刚发布，新的“SidecarContainers”功能还处于 Alpha 阶段（因此默认情况下处于关闭状态），而且 Istio 中对该功能的支持尚未发布，但我们今天仍然可以尝试一下 - 只是不要尝试 这在生产中！

First, we need to spin up a Kubernetes 1.28 cluster, with the `SidecarContainers` feature enabled:
首先，我们需要启动 Kubernetes 1.28 集群，并启用“SidecarContainers”功能：

{{< text shell >}}
$ cat <<EOF | kind create cluster --name sidecars --image gcr.io/istio-testing/kind-node:v1.28.0 --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
featureGates:
  SidecarContainers: true
EOF
{{< /text >}}

Then we can download the latest Istio 1.19 pre-release (as 1.19 is not yet out). I used Linux here. This is a pre-release of Istio, so again - do not try this in production! When we install Istio, we will enable the feature flag for native sidecar support and turn on access logs to help demo things later.
然后我们可以下载最新的 Istio 1.19 预发布版（因为 1.19 尚未发布）。 我这里用的是Linux。 这是 Istio 的预发行版，因此再次强调 - 不要在生产中尝试此操作！ 当我们安装 Istio 时，我们将启用本机 sidecar 支持的功能标志，并打开访问日志以帮助稍后演示。

{{< text shell >}}
$ TAG=1.19.0-beta.0
$ curl -L https://github.com/istio/istio/releases/download/$TAG/istio-$TAG-linux-amd64.tar.gz | tar xz
$ ./istioctl install --set values.pilot.env.ENABLE_NATIVE_SIDECARS=true -y --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

And finally we can deploy a workload:
最后我们可以部署工作负载：

{{< text shell >}}
$ kubectl label namespace default istio-injection=enabled
$ kubectl apply -f samples/sleep/sleep.yaml
{{< /text >}}

Let's look at the pod:
让我们看看 Pod：

{{< text shell >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-7656cf8794-8fhdk   2/2     Running   0          51s
{{< /text >}}

Everything looks normal at first glance... If we look under the hood, we can see the magic, though.
乍一看，一切看起来都很正常……但如果我们深入观察，我们就能看到其中的魔力。

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME                     INIT                     CONTAINERS
sleep-7656cf8794-8fhdk   istio-init,istio-proxy   sleep
{{< /text >}}

Here we can see all the `containers` and `initContainers` in the pod.
在这里我们可以看到 pod 中的所有 `containers` 和 `initContainers`。

Surprise! `istio-proxy` is now an `initContainer`.
惊喜！ `istio-proxy` 现在是一个 `initContainer`。

More specifically, it is an `initContainer` with `restartPolicy: Always` set (a new field, enabled by the `SidecarContainers` feature). This tells Kubernetes to treat it as a sidecar.
更具体地说，它是一个设置了“restartPolicy: Always”的“initContainer”（一个新字段，由“SidecarContainers”功能启用）。 这告诉 Kubernetes 将其视为 sidecar。

This means that later containers in the list of `initContainers`, and all normal `containers` will not start until the proxy container is ready. Additionally, the pod will terminate even if the proxy container is still running.
这意味着在代理容器准备好之前，“initContainers”列表中的后续容器以及所有正常的“容器”将不会启动。 此外，即使代理容器仍在运行，pod 也会终止。

### Init container traffic
### 初始化容器流量

To put this to the test, let's make our pod actually do something. Here we deploy a simple pod that sends a request in an `initContainer`. Normally, this would fail.
为了测试这一点，让我们让我们的 Pod 真正做一些事情。 这里我们部署了一个简单的 Pod，它在 `initContainer` 中发送请求。 通常情况下，这会失败。

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

Checking the proxy container, we can see the request both succeeded and went through the Istio sidecar:
检查代理容器，我们可以看到请求均成功并通过了 Istio sidecar：

{{< text shell >}}
$ kubectl logs sleep -c istio-proxy | tail -n1
[2023-07-25T22:00:45.703Z] "GET /get HTTP/1.1" 200 - via_upstream - "-" 0 1193 334 334 "-" "curl/7.81.0" "1854226d-41ec-445c-b542-9e43861b5331" "httpbin.org" ...
{{< /text >}}

If we inspect the pod, we can see our sidecar now runs *before* the `check-traffic` `initContainer`:
如果我们检查 pod，我们可以看到我们的 sidecar 现在在 `check-traffic` `initContainer` 之前运行：

{{< text shell >}}
$ kubectl get pod -o "custom-columns="\
"NAME:.metadata.name,"\
"INIT:.spec.initContainers[*].name,"\
"CONTAINERS:.spec.containers[*].name"

NAME    INIT                                  CONTAINERS
sleep   istio-init,istio-proxy,check-traffic   sleep
{{< /text >}}

### Exiting pods
### 退出 Pod

Earlier, we mentioned that when applications exit (common in `Jobs`), the pod would live forever. Fortunately, this is addressed as well!
之前，我们提到当应用程序退出时（常见于“Jobs”），pod 将永远存在。 幸运的是，这个问题也得到了解决！

First we deploy a pod that will exit after one second and doesn't restart:
首先我们部署一个 pod，它将在一秒后退出并且不会重新启动：

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

And we can watch its progress:
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

Here we can see the application container exited, and shortly after Istio's sidecar container exits as well. Previously, the pod would be stuck in `Running`, while now it can transition to `Completed`. No more zombie pods!
在这里我们可以看到应用程序容器退出了，不久之后 Istio 的 sidecar 容器也退出了。 以前，Pod 会停留在“Running”状态，而现在它可以转换为“Completed”。 不再有僵尸荚！

## What about ambient mode?
## 环境模式怎么样？

Last year, Istio announced [ambient mode](/blog/2022/introducing-ambient-mesh/) - a new data plane mode for Istio that doesn't rely on sidecar containers. So with ambient mode coming, does any of this even matter?
去年，Istio 宣布了 [ambient 模式](/blog/2022/introducing-ambient-mesh/) - Istio 的一种新数据平面模式，不依赖 sidecar 容器。 那么随着环境模式的到来，这一切还重要吗？

I would say a resounding "Yes"!
我会大声地说“是”！

While the impacts of sidecar are lessened when ambient mode is used for a workload, I expect that almost all large scale Kubernetes users have some sort of sidecar in their deployments. This could be Istio workloads they don't want to migrate to ambient, that they haven't *yet* migrated, or things unrelated to Istio. So while there may be fewer scenarios where this matters, it still is a huge improvement for the cases where sidecars are used.
虽然当环境模式用于工作负载时，Sidecar 的影响会减轻，但我预计几乎所有大规模 Kubernetes 用户在其部署中都会有某种 Sidecar。 这可能是他们不想迁移到环境中的 Istio 工作负载、他们尚未迁移的工作负载或与 Istio 无关的事物。 因此，虽然这种情况可能较少，但对于使用 sidecar 的情况来说，这仍然是一个巨大的改进。

You may wonder the opposite - if all our sidecar woes are addressed, why do we need ambient mode at all? There are still a variety of benefits ambient brings with these sidecar limitations addressed. For example, [this blog post](/blog/2023/waypoint-proxy-made-simple/) goes into details about why decoupling proxies from workloads is advantageous.
您可能想知道相反的情况 - 如果我们所有的边车问题都得到解决，为什么我们还需要环境模式？ 解决了这些边车限制后，环境仍然带来了多种好处。 例如，[这篇博文](/blog/2023/waypoint-proxy-made-simple/) 详细介绍了为什么将代理与工作负载分离是有利的。

## Try it out yourself
## 自己尝试一下

We encourage the adventurous readers to try this out themselves in testing environments! Feedback for these experimental and alpha features is critical to ensure they are stable and meeting expectations before promoting them. If you try it out, let us know what you think in the [Istio Slack](/get-involved/)!
我们鼓励有冒险精神的读者在测试环境中亲自尝试！ 对这些实验性和 alpha 功能的反馈对于确保它们稳定并在推广之前满足预期至关重要。 如果您尝试一下，请让我们知道您在 [Istio Slack](/get-involved/) 中的想法！

In particular, the Kubernetes team is interested in hearing more about:
Kubernetes 团队特别有兴趣了解更多有关以下内容的信息：

* Handling of shutdown sequence, especially when there are multiple sidecars involved.
* Backoff restart handling when sidecar containers are crashing.
* Edge cases they have not yet considered.
* 处理关闭序列，特别是当涉及多个 sidecar 时。
* Sidecar 容器崩溃时的退避重新启动处理。
* 他们尚未考虑的边缘情况。
