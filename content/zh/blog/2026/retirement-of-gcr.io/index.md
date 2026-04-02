---
title: "Istio 正在迁移容器仓库"
description: 您今天可以采取哪些措施，以确保您的集群不受 `gcr.io/istio-release` 退役的影响？.
publishdate: 2026-03-23
attribution: Steven Jin (Microsoft), John Howard (Solo.io); Translated by Wilson Wu (DaoCloud)
keywords: [Istio,Helm,Container Registry]
---

由于 Istio 资助模式的变更，自 2027 年 1 月 1 日起，
Istio 镜像将不再提供于 `gcr.io/istio-release`。
这意味着，引用托管在 `gcr.io/istio-release` 上的镜像的集群，
在 2027 年可能会无法创建新的 Pod。

事实上，我们正将所有 Istio 相关的制品（artifacts）——包括
Helm Chart 在内——全面迁出 Google Cloud。
后续的通告将涵盖 Helm Chart 及其他制品的迁移事宜。
本文将重点介绍：针对 2027 年容器注册表迁移这一事件，您目前可以采取哪些应对措施。

## 我受影响了吗？ {#am-i-affected}

默认情况下，Istio 安装使用 Docker Hub (`docker.io/istio`) 作为其容器镜像仓库，
但许多用户选择使用 `gcr.io/istio-release` 镜像。
您可以使用以下命令来检查当前是否正在使用该镜像。

{{< text bash >}}
$ kubectl get pods --all-namespaces -o json \
    | jq -r '.items[] | select(.spec.containers[].image | startswith("gcr.io/istio-release")) | "\(.metadata.namespace)/\(.metadata.name)"'
{{< /text >}}

上述命令将列出所有使用了托管在 `gcr.io/istio-release`
上的镜像的 Pod。如果存在此类 Pod，您很可能需要进行迁移。

{{< tip >}}
即使您目前使用的是 Docker Hub 作为镜像仓库，
我们仍建议您迁移至 `registry.istio.io`，
以防未来 Istio 镜像在 Docker Hub 上不再可用。详情请参阅下文。
{{< /tip >}}

## 今天要做什么 {#what-to-do-today}

尽管我们计划将镜像在 `gcr.io/istio-release` 上保留至 2026 年底，
但我们已将 `registry.istio.io` 设立为 Istio 镜像的新归宿。
请尽快迁移至使用 `registry.istio.io`。

### 使用 `istioctl` {#using-istioctl}

如果您使用 `istioctl` 安装 Istio，
可以按如下方式更新您的 `IstioOperator` 配置：

{{< text yaml >}}
# istiooperator.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  # ...
  hub: registry.istio.io/release
  # 其余部分均可保持不变，除非你在其他地方引用了 `gcr.io/istio-release` 镜像。
{{< /text >}}

并使用此配置安装 Istio：

{{< text bash >}}
$ istioctl install -f istiooperator.yaml
{{< /text >}}

或者，您也可以将注册表作为命令行参数传入。

{{< text bash >}}
$ istioctl install --set hub=registry.istio.io/release # the rest of your arguments
{{< /text >}}

### 使用 Helm {#using-helm}

如果您使用 Helm 安装 Istio，
请更新您的 Values 文件，使其包含以下内容：

{{< text yaml >}}
# ...
hub: registry.istio.io/release
global:
  hub: registry.istio.io/release
# 其余部分均可保持不变，除非你在其他地方引用了 `gcr.io/istio-release` 镜像。
{{< /text >}}

然后，使用新的 Values 文件更新您的 Helm 安装。

### 私有镜像 {#private-mirrors}

您的组织可能会从 `gcr.io/istio-release` 拉取镜像，
将其推送到私有镜像仓库，并在 Istio 安装过程中引用该私有仓库。
这一流程依然有效，但您需要从 `registry.istio.io/release` 拉取镜像，
而非 `gcr.io/istio-release`。
