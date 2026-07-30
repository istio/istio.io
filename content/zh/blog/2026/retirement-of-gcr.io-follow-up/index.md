---
title: "关于我们容器仓库迁移的最新进展"
description: 为了确保您的集群不会受到 `gcr.io/istio-release` 和 `registry.istio.io` 停用的影响，您可以立即采取以下措施。
publishdate: 2026-07-23
attribution: Steven Jin (Microsoft); Translated by Wilson Wu (DaoCloud)
keywords: [Istio,Container Registry]
---

在[之前的博文](../retirement-of-gcr.io/)中，我们宣布 Istio 将于 2026 年底停用 `gcr.io/istio-release` 容器镜像仓库，
并将镜像迁移到 `registry.istio.io/release` 作为新的镜像仓库。
最初的设计是将 `registry.istio.io/release` 作为 Cloudflare 工作进程，
代理请求到任何符合 OCI 标准的镜像仓库，从而实现镜像仓库的切换，
而不会对 Istio 用户造成任何影响。目前，我们仍然代理到 `gcr.io/istio-release`。

如前所述，我们将在 2026 年底停用 `gcr.io/istio-release`。由于 2027 年的基础设施预算有限，
我们计划使用免费的容器托管平台来托管 Istio 镜像。然而，通过 Cloudflare
进行代理意味着所有流量都会集中到少数几个出口 IP 地址，这会触发免费容器托管平台的速率限制策略。

在与托管平台就此限制进行讨论后，我们做出了艰难的决定，停用 `registry.istio.io/release`。
我们将继续托管 `registry.istio.io/release` 直至 2026 年底。
我们将一如既往地把 Istio 镜像发布到 `docker.io/istio`，并计划未来发布到镜像站点。

## 我是否受到影响？ {#am-i-affected}

默认情况下，Istio 1.30 安装使用 `registry.istio.io/release` 作为容器镜像仓库。
所有其他 Istio 版本默认使用 `docker.io/istio`。您可以通过运行以下命令来检查是否受到影响：

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("registry.istio.io/release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

上述命令将列出所有使用托管在 `registry.istio.io/release` 上的镜像的 Pod。
如果存在任何此类 Pod，您可能需要进行迁移。

请注意，正如上一篇文章中所述，我们仍将在 2026 年底停用 `gcr.io/istio-release`，
因此您也应该检查 `gcr.io/istio-release` 的使用情况。

## 今天要做什么 {#what-to-do-today}

尽管我们计划将镜像保留在 `registry.istio.io/release` 和 `gcr.io/istio-release` 上直至 2026 年底，
但我们建议您尽快迁移到 `docker.io/istio`。更理想的做法是配置一个拉取式缓存，以确保最大程度的可用性。

### 使用 `istioctl` {#using-istioctl}

如果您使用 `istioctl` 安装 Istio，则可以按如下方式更新 `IstioOperator` 配置：

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: docker.io/istio  # 或者你的拉取缓存
  # 除非你在其他地方引用了 `gcr.io/istio-release` 镜像，否则其他所有内容都可以保持不变。
{{< /text >}}

然后使用以下配置安装 Istio：

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

或者，您可以将仓库作为命令行参数传递。

{{< text bash >}}
$ istioctl install --set hub=docker.io/istio # or your pull-through cache
{{< /text >}}

### 使用 Helm {#using-helm}

如果您使用 Helm 安装 Istio，请按如下方式更新您的 values 文件：

{{< text yaml >}}
# ...
hub: docker.io/istio  # 或者你的拉取缓存
global:
  hub: docker.io/istio  # 或者你的拉取缓存
# 除非你在其他地方引用了 `gcr.io/istio-release` 镜像，否则其他所有内容都可以保持不变。
{{< /text >}}

然后，使用新的 values 文件更新 Helm 安装。
