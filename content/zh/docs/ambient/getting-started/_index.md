---
title: 入门
description: 如何在 Ambient 模式下部署和安装 Istio。
weight: 2
aliases:
  - /zh/docs/ops/ambient/getting-started
  - /zh/latest/docs/ops/ambient/getting-started
owner: istio/wg-networking-maintainers
skip_list: true
test: yes
---

本指南可让您快速评估 Istio 的 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}。
您需要一个 Kubernetes 集群才能继续。如果您没有集群，
则可以使用 [kind](/zh/docs/setup/platform-setup/kind)
或任何其他[受支持的 Kubernetes 平台](/zh/docs/setup/platform-setup)。

这些步骤要求您拥有一个{{< gloss "cluster" >}}集群{{< /gloss >}}，
其中运行 Kubernetes [受支持的版本](/zh/docs/releases/supported-releases#support-status-of-istio-releases)
（{{< supported_kubernetes_versions >}}）。

## 下载 Istio CLI {#download-the-istio-cli}

Istio 使用名为 `istioctl` 的命令行工具进行配置。下载该工具以及 Istio 示例应用程序：

{{< text syntax=bash snip_id=none >}}
$ curl -L https://istio.io/downloadIstio | sh -
$ cd istio-{{< istio_full_version >}}
$ export PATH=$PWD/bin:$PATH
{{< /text >}}

通过打印版本的命令来检查您是否能够运行 `istioctl`。
此时，Istio 尚未安装在您的集群中，因此您将看到没有 Pod 就绪。

{{< text syntax=bash snip_id=none >}}
$ istioctl version
no ready Istio pods in "istio-system"
{{< istio_full_version >}}
{{< /text >}}

## 将 Istio 安装到你的集群上 {#install-istio-on-to-your-cluster}

`istioctl` 支持多种[配置文件](/zh/docs/setup/additional-setup/config-profiles/)，
其中包含不同的默认选项，并可根据您的生产需求进行自定义。
`ambient` 配置文件中包含对 Ambient 模式的支持。使用以下命令安装 Istio：

{{< text syntax=bash snip_id=install_ambient >}}
$ istioctl install --set profile=ambient --skip-confirmation
{{< /text >}}

安装 Istio 组件可能需要一分钟。安装完成后，您将看到以下输出，表明所有组件已成功安装。

{{< text syntax=plain snip_id=none >}}
✔ Istio core installed
✔ Istiod installed
✔ CNI installed
✔ Ztunnel installed
✔ Installation complete
{{< /text >}}

{{< tip >}}
您可以使用命令 `istioctl verify-install` 验证已安装的组件。
{{< /tip >}}

## 安装 Kubernetes Gateway API CRD {#install-the-kubernetes-gateway-api-crds}

您需要安装 Kubernetes Gateway API CRD，大多数 Kubernetes 集群上默认不会安装这些 CRD：

{{< text syntax=bash snip_id=install_k8s_gateway_api >}}
$ kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v1.1.0" | kubectl apply -f -; }
{{< /text >}}

您将使用 Kubernetes Gateway API 来配置流量路由。

## 下一步 {#next-steps}

恭喜！您已成功安装支持 Ambient 模式的 Istio。
继续下一步以[安装演示应用程序并将其添加到 Ambient 网格](/zh/docs/ambient/getting-started/deploy-sample-app/)。
