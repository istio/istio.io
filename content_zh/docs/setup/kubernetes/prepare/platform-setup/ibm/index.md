---
title: IBM Cloud Kubernetes Service
description: 对 IBM Cloud Kubernetes Service（IKS）集群进行配置以便安装运行 Istio。
weight: 18
skip_seealso: true
keywords: [platform-setup,ibm,iks]
---

按照以下说明为 Istio 准备 IBM Cloud 集群。

您可以在 IBM Cloud Public 中使用 [Managed Istio add-on for IBM Cloud Kubernetes Service](#managed-istio-add-on)、使用 Helm 在 [IBM Cloud Public](#ibm-cloud-public) 中安装 Istio，或在 [IBM-Cloud-Private](#ibm-cloud-private) 中安装 Istio。

## Managed Istio add-on

IBM Cloud Kubernetes Service 上提供 Istio 的无缝安装，Istio 控制平面组件的自动更新和生命周期管理，以及与平台日志记录和监视工具的集成。只需单击一下，您就可以获得所有 Istio 核心组件、其他跟踪、监控和可视化，以及 Bookinfo 示例应用程序的启动和运行。IBM Cloud Kubernetes 服务上的 Istio 作为托管附加组件提供，因此 IBM Cloud 会自动保持所有 Istio 组件的最新状态。

要在 IBM Cloud Public 中安装托管的 Istio 附加组件，请参阅 [IBM Cloud Kubernetes 服务文档](https://cloud.ibm.com/docs/containers/cs_istio.html)。

## IBM Cloud Public

将下面代码块中 `<cluster-name>` 替换为您要使用的群集名称。

1. 创建一个新的 `lite` 或付费 Kubernetes 集群：

    `lite` 集群:

    {{< text bash >}}
    $ ibmcloud cs cluster-create --name <cluster-name>
    {{< /text >}}

    付费集群:

    {{< text bash >}}
    $ ibmcloud cs cluster-create --location <location> --machine-type u2c.2x4 \
      --name <cluster-name>
    {{< /text >}}

1. 为 `kubectl` 获取认证凭据。下面的命令需要根据实际情况对 `<cluster-name>` 进行替换：

    {{< text bash >}}
    $(ibmcloud cs cluster-config <cluster-name> --export)
    {{< /text >}}

## IBM Cloud Private

[设置 `kubectl` 客户端](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html)以便对 IBM Cloud Private 进行访问
