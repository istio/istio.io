---
title: 加固 Docker 容器镜像
description: 使用加固的容器镜像来减小 Istio 的攻击面。
weight: 80
aliases:
  - /zh/help/ops/security/harden-docker-images
  - /zh/docs/ops/security/harden-docker-images
owner: istio/wg-security-maintainers
test: n/a
status: Alpha
---

{{< boilerplate alpha >}}

Istio 的[默认镜像](https://hub.docker.com/r/istio/base)基于 `ubuntu` 添加了一些额外的工具。
也可以使用基于 [Distroless 镜像](https://github.com/GoogleContainerTools/distroless)的替代镜像。

使用 Distroless 时，Distroless 镜像已经不再包含非必需的可执行文件和库。

- 减少了攻击面。尽可能少的漏洞。
- 镜像更小了，且启动更快。

请参考官方 Distroless README 的[为何选择 Distroless 镜像？](https://github.com/GoogleContainerTools/distroless#why-should-i-use-distroless-images) 章节。

## 安装 Distroless 镜像 {#install-distroless-images}

按照[安装步骤](/zh/docs/setup/install/istioctl/)配置 Istio。
添加 `variant` 选项以使用 **Distroless 镜像** 。

{{< text bash >}}
$ istioctl install --set values.global.variant=distroless
{{< /text >}}

如果您只对将 Distroless 镜像用于注入的代理镜像感兴趣，
您还可以使用 [Proxy Config](/zh/docs/reference/config/networking/proxy-config/#ProxyImage)
中的 `proxyImage` 字段。请注意，上面的 `variant` 标志会自动为您设置该字段。

## 调试 {#debugging}

Distroless 镜像缺少所有调试工具（包括 Shell！）。
虽然对安全性有好处，但这限制了使用 `kubectl exec` 对代理容器进行临时调试的能力。

幸运的是，[临时容器](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/ephemeral-containers/) 可以在此处提供帮助。
`kubectl debug` 可以将临时容器附加到 Pod。
通过使用带有额外工具的镜像，我们可以像以前一样进行调试：

{{< text shell >}}
$ kubectl debug --image istio/base --target istio-proxy -it app-65c6749c9d-t549t
Defaulting debug container name to debugger-cdftc.
If you don't see a command prompt, try pressing enter.
root@app-65c6749c9d-t549t:/# curl example.com
{{< /text >}}

这会使用 `istio/base` 部署一个新的临时容器。
这与 Distroless Istio 镜像中使用的基础镜像相同，并且包含各种可用于调试 Istio 的工具。
但是，任何镜像都可以起作用。
该容器还被附加到 Sidecar 代理 (`--target istio-proxy`) 的进程命名空间和 Pod 的网络命名空间。
