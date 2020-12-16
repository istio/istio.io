---
title: 使用 Helm 安装
linktitle: 使用 Helm 安装
description: 安装、配置、并深入评估 Istio。
weight: 27
keywords: [kubernetes,helm]
owner: istio/wg-environments-maintainers
icon: helm
test: no
---

请跟随本指南一起，使用
 [Helm](https://helm.sh/docs/) 安装、配置、并深入评估 Istio 网格系统。
本指南用到的 Helm chart、以及使用 [Istioctl](/zh/docs/setup/install/istioctl/)、[Operator](/zh/docs/setup/install/operator/) 安装 Istio 时用到的 chart，它们都是相同的底层 chart。

此特性目前处于 [alpha](/zh/about/feature-stages/) 阶段。

## 先决条件 {#prerequisites}

1. [下载 Istio 发行版](/zh/docs/setup/getting-started/#download).

1. 执行必要的[平台安装](/zh/docs/setup/platform-setup/).

1. 检查 [Pod 和服务的要求](/zh/docs/ops/deployment/requirements/).

1. [安装 Helm 客户端](https://helm.sh/docs/intro/install/) ，需高于 3.1.1 版本。

    {{< warning >}}
    Istio 安装不再支持 Helm2。
    {{< /warning >}}

本文命令使用的 Helm charts 来自于 Istio 发行包，存放于目录 `manifests/charts`。

## 安装步骤 {#installation-steps}

将目录转到发行包的根目录，按照以下说明进行操作。

{{< warning >}}
default chart 配置将安全的第三方令牌映射到服务账户令牌，
此令牌将被 Istio 代理用于认证 Istio 控制平面。
继续安装下面 chart 之前，你需要用下面
[步骤](/zh/docs/ops/best-practices/security/#configure-third-party-service-account-tokens)
验证：在集群中，第三方令牌是否启用。
如果尚未启用第三方令牌，你应该将参数 `--set global.jwtPolicy=first-party-jwt` 添加到 Helm 安装命令中。
如果设置 `jwtPolicy` 时出了问题，各类pod，比如关联到 `istiod`、网关的 pod、
以及被注入 Envoy 代理的工作负载的 Pod等等，都会因为缺少 `istio-token` 卷的原因，而不能部署。

{{< /warning >}}

1. 为 Istio 组件，创建命名空间 `istio-system` :

    {{< text bash >}}
    $ kubectl create namespace istio-system
    {{< /text >}}

1. 安装 Istio base chart，它包含了 Istio 控制平面用到的集群范围的资源：

    {{< text bash >}}
    $ helm install istio-base manifests/charts/base -n istio-system
    {{< /text >}}

1. 安装 Istio discovery chart，它用于部署 `istiod` 服务：

    {{< text bash >}}
    $ helm install istiod manifests/charts/istio-control/istio-discovery \
        --set global.hub="docker.io/istio" \
        --set global.tag="{{< istio_full_version >}}" \
        -n istio-system
    {{< /text >}}

1. (可选项) 安装 Istio 的入站网关 chart，它包含入站网关组件：

    {{< text bash >}}
    $ helm install istio-ingress manifests/charts/gateways/istio-ingress \
        --set global.hub="docker.io/istio" \
        --set global.tag="{{< istio_full_version >}}" \
        -n istio-system
    {{< /text >}}

1. (可选项) 安装 Istio 的出站网关 chart，它包含了出站网关组件：

    {{< text bash >}}
    $ helm install istio-egress manifests/charts/gateways/istio-egress \
        --set global.hub="docker.io/istio" \
        --set global.tag="{{< istio_full_version >}}" \
        -n istio-system
    {{< /text >}}

## 验证安装 {#verifying-the-installation}

1. 确认命名空间 `istio-system` 中所有 Kubernetes pods 均已部署，且返回值中 `STATUS` 的值为 `Running`：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    {{< /text >}}

## 更新 Istio 配置 {#updating-your-configuration}

你可以用自己的安装参数，覆盖掉前面用到的 Istio Helm chart 的默认行为，
然后按照 Helm 升级流程来定制安装你的 Istio 网格系统。
至于可用的配置项，你可以在 `values.yaml` 文件内找到，
此文件位于你的 Istio 发行包的 `manifests/charts` 目录中。

{{< warning >}}
注意：上面说到的 Istio Helm chart values 特性正在紧张的开发中，尚属于试验阶段。
升级到新版本的 Istio，涉及到把你的定制参数迁移到新 API 定义中去。
{{< /warning >}}

定制安装支持两种方式：
[`ProxyConfig`](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig) 方式和
Helm 值文件方式。
其中， `ProxyConfig` 支持模式验证，但非结构化的 Helm 值文件不支持，所以更推荐使用前者。

## 使用 Helm 升级 {#upgrading-using-helm}

在你的集群中升级 Istio 之前，建议备份你的定制安装配置文件，以备不时之需。

{{< text bash >}}
$ kubectl get crds | grep 'istio.io' | cut -f1-1 -d "." | \
    xargs -n1 -I{} sh -c "kubectl get --all-namespaces -o yaml {}; echo ---" > $HOME/ISTIO_RESOURCE_BACKUP.yaml
{{< /text >}}

可以这样恢复你定制的配置文件：

{{< text bash >}}
$ kubectl apply -f $HOME/ISTIO_RESOURCE_BACKUP.yaml
{{< /text >}}

### 从非 Helm 安装迁移 {#migrating-from-non-helm-installations}

如果你需要将使用 `istioctl` 或 Operator 安装的 Istio 迁移到 Helm，
那要删除当前 Istio 控制平面资源，并根据上面的说明，使用 Helm 重新安装 Istio。
在删除当前 Istio 时，前外不能删掉 Istio 的客户资源定义（CRDs），以免丢掉你的定制 Istio 资源。

{{< warning >}}
建议：从集群中删除 Istio 前，使用上面的说明备份你的 Istio 资源。
{{< /warning >}}

依据你的安装方式，选择
[Istioctl 卸载指南](/zh/docs/setup/install/istioctl#uninstall-istio) 或
[Operator 卸载指南](/zh/docs/setup/install/operator/#uninstall)。

### 金丝雀升级 (推荐) {#canary-upgrade}

按照下面步骤，安装一个金丝雀版本的 Istio 控制平面，验证新版本是否兼容现有的配置和数据平面：

{{< warning >}}
注意：安装金丝雀版本的 `istiod` 服务后，主版本和金丝雀版本共享来自 base chart 的底层集群范围的资源。

当前，Istio 出站和入站网关的金丝雀升级支持尚且处于
[紧张的开发过程](/zh/docs/setup/upgrade/gateways/)，
属于 `experimental` （实验）阶段。
{{< /warning >}}

1. 设置版本，安装金丝雀版本的 Istio discovery chart:

    {{< text bash >}}
    $ helm install istiod-canary manifests/charts/istio-control/istio-discovery \
        --set revision=canary \
        --set global.hub="docker.io/istio" \
        --set global.tag=<version_to_upgrade> \
        -n istio-system
    {{< /text >}}

1. 验证在你的集群中运行了两个版本的 `istiod` ：

    {{< text bash >}}
    $ kubectl get pods -l app=istiod -L istio.io/rev -n istio-system
      NAME                            READY   STATUS    RESTARTS   AGE   REV
      istiod-5649c48ddc-dlkh8         1/1     Running   0          71m   default
      istiod-canary-9cc9fd96f-jpc7n   1/1     Running   0          34m   canary
    {{< /text >}}

1. 按照 [这里的](/zh/docs/setup/upgrade/#data-plane) 步骤在金丝雀版本的控制平面中测试或迁移存量工作负载。

1. 在你验证并迁移工作负载到金丝雀版本的控制平面之后，即可删除老版本的控制平面：

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

### 就地升级 {#in-place-upgrade}

使用 Helm 的升级流程，在你的集群中就地升级 Istio：

{{< warning >}}
此升级路径仅支持 Istio 1.8+ 的版本。

将用于覆盖默认配置的值文件（values file）或自定义选项添加到下面的命令中，
以在 Helm 升级过程中保留自定义配置。
{{< /warning >}}

1. 升级 Istio base chart:

    {{< text bash >}}
    $ helm upgrade istio-base manifests/charts/base -n istio-system
    {{< /text >}}

1. 升级 Istio discovery chart:

    {{< text bash >}}
    $ helm upgrade istiod manifests/charts/istio-control/istio-discovery \
        --set global.hub="docker.io/istio" \
        --set global.tag=<version_to_upgrade> \
        -n istio-system
    {{< /text >}}

1. (可选项) 如果集群中安装了 Istio 的入站或出站网关 charts，则升级它们：

    {{< text bash >}}
    $ helm upgrade istio-ingress manifests/charts/gateways/istio-ingress \
        --set global.hub="docker.io/istio" \
        --set global.tag=<version_to_upgrade>\
        -n istio-system
    $ helm upgrade istio-egress manifests/charts/gateways/istio-egress \
        --set global.hub="docker.io/istio" \
        --set global.tag=<version_to_upgrade> \
        -n istio-system
    {{< /text >}}

## 卸载 {#uninstall}

卸载前面安装的 chart，以便卸载 Istio 和它的各个组件。

1. 列出在命名空间 `istio-system` 中安装的所有 Istio chart：

    {{< text bash >}}
    $ helm ls -n istio-system
    {{< /text >}}

1. (可选项) 删除 Istio 的入/出站网关 chart:

    {{< text bash >}}
    $ helm delete istio-egress -n istio-system
    $ helm delete istio-ingress -n istio-system
    {{< /text >}}

1. 删除 Istio discovery chart:

    {{< text bash >}}
    $ helm delete istiod -n istio-system
    {{< /text >}}

1. 删除 Istio base chart:

    {{< warning >}}
    通过 Helm 删除 chart 并不会级联删除它安装的定制资源定义（CRD）。
    {{< /warning >}}

    {{< text bash >}}
    $ helm delete istio-base -n istio-system
    {{< /text >}}

1. 删除命名空间 `istio-system`：

    {{< text bash >}}
    $ kubectl delete namespace istio-system
    {{< /text >}}

### (可选项) 删除 Istio 安装的 CRD {#deleting-customer-resource-definition-installed}

永久删除 CRD， 会删除你在集群中创建的所有 Istio 资源。
用下面命令永久删除集群中安装的 Istio CRD：

    {{< text bash >}}
    $ kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
        | xargs -n1 kubectl delete crd
    {{< /text >}}
