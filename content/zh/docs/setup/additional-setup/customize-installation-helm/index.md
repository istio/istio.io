---
title: 高级 Helm chart 自定义
description: 描述使用 Helm 安装时如何自定义安装配置选项。
weight: 55
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

## 先决条件  {#prerequisites}

在开始之前，请检查以下先决条件：

1. [下载 Istio 版本](/zh/docs/setup/getting-started/#download)。
1. 执行任何必要的[特定于平台的设置](/zh/docs/setup/platform-setup/)。
1. 检查 [Pod 和服务的请求](/zh/docs/ops/deployment/requirements/)。
1. [使用 helm 进行 Istio 安装](/zh/docs/setup/install/helm)。
1. Helm 版本支持后期渲染。（>= 3.1）
1. kubectl 或 kustomize。

## 高级 Helm chart 自定义  {#advanced-helm-chart-customization}

Istio 的 Helm chart 尝试结合用户满足其特定需求所需的大部分属性。
然而，它并不包含了所有您可能想要调整 Kubernetes 值。
虽然建立这样的机制并不实际，但在本文档中，我们将演示一种方法，
该方法允许您进行一些高级 Helm chart 自定义，
而无需直接修改 Istio 的 Helm chart。

### 使用 Helm 和 kustomize 对 Istio Chart 文件进行后期渲染  {#using-helm-with-kustomize-to-post-render-istio-charts}

使用 Helm `post-renderer` 和 `post-renderer` 功能，您可以轻松地调整安装清单以满足您的要求。
`Post-rendering` 可在 Helm 安装前灵活地操作、配置、和/或验证已渲染的清单。
这使得具有高级配置需求的用户可以使用像 Kustomize 这样的工具来应用配置更改，
而不需要原始 Chart 维护人员提供的任何额外支持。

### 向现有图表添加值  {#adding-a-value-to-an-already-existing-chart}

在本例中，我们将为 Istio 的 `ingress-gateway` 部署添加一个 `sysctl` 值。我们需要：

1. 创建 `sysctl` Deployment 自定义补丁模板。
1. 使用 Helm 应用补丁 `post-rendering`。
1. 验证 `sysctl` 补丁是否已正确应用到 Pod 中。

## 创建 Kustomization  {#create-the-kustomization}

首先，我们创建一个 `sysctl` 补丁文件，向 `ingress-gateway` Pod 添加一个
`securityContext` 并附加属性：

{{< text bash >}}
$ cat > sysctl-ingress-gw-customization.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    spec:
      securityContext:
          sysctls:
          - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
            value: "10"
EOF
{{< /text >}}

下面的 shell 脚本有助于弥补 Helm `post-renderer` 和 Kustomize 之间的差距，
因为前者适用 `stdin/stdout`，而后者适用于文件。

{{< text bash >}}
$ cat > kustomize.sh <<EOF
#!/bin/sh
cat > base.yaml
exec kubectl kustomize # 如果您安装了它，您也可以使用 "kustomize build ."。
EOF
$ chmod +x ./kustomize.sh
{{< /text >}}

最后，让我们创建 `kustomization` yaml 文件，这是 `kustomize`
的一组资源和相关定制细节的输入。

{{< text bash >}}
$ cat > kustomization.yaml <<EOF
resources:
- base.yaml
patchesStrategicMerge:
- sysctl-ingress-gw-customization.yaml
EOF
{{< /text >}}

## 应用自定义  {#apply-the-kustomization}

现在 Kustomization 文件已经准备好了，让我们使用 Helm 来确保它被正确应用。

### 为 Istio 添加 Helm 存储库  {#add-the-helm-repository-for-istio}

{{< text bash >}}
$ helm repo add istio https://istio-release.storage.googleapis.com/charts
$ helm repo update
{{< /text >}}

### 使用 Helm 模板进行渲染和验证  {#render-and-verify-using-helm-template}

我们可以在 Helm 安装之前使用 Helm `post-renderer` 来验证渲染的清单。

{{< text bash >}}
$ helm template istio-ingress istio/gateway --namespace istio-ingress --post-renderer ./kustomize.sh | grep -B 2 -A 1 netfilter.nf_conntrack_tcp_timeout_close_wait
{{< /text >}}

在输出中，检查 `ingress-gateway` Pod 中新增的 `sysctl` 属性：

{{< text yaml >}}
    securityContext:
      sysctls:
      - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
        value: "10"
{{< /text >}}

### 使用 Helm 应用补丁 `Post-Renderer`  {#apply-the-patch-using-helm-post-renderer}

使用以下命令来安装 Istio 入口网关，使用 Helm 来应用我们的自定义 `post-renderer`：

{{< text bash >}}
$ kubectl create ns istio-ingress
$ helm upgrade -i istio-ingress istio/gateway --namespace istio-ingress --wait --post-renderer ./kustomize.sh
{{< /text >}}

## 验证自定义  {#verify-the-kustomization}

检查 ingress-gateway Deployment，您将看到新增的 `sysctl` 值：

{{< text bash >}}
$ kubectl -n istio-ingress get deployment istio-ingress -o yaml
{{< /text >}}

{{< text yaml >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  …
  name: istio-ingress
  namespace: istio-ingress
spec:
  template:
    metadata:
      …
    spec:
      securityContext:
        sysctls:
        - name: net.netfilter.nf_conntrack_tcp_timeout_close_wait
          value: "10"
{{< /text >}}

## 附加信息  {#additional-information}

有关本文档中描述的概念和技术的更多详细信息，请参阅：

1. [IstioOperator - 自定义安装](/zh/docs/setup/additional-setup/customize-installation)
1. [高级 Helm 技术](https://helm.sh/docs/topics/advanced/)
1. [自定义](https://kubernetes.io/zh-cn/docs/tasks/manage-kubernetes-objects/kustomization/)
