---
title: IBM Cloud 快速开始
description: 在 IBM 公有云或私有云上快速搭建 Istio 服务。
weight: 16
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/ibm/
    - /zh/docs/setup/kubernetes/platform-setup/ibm/
keywords: [platform-setup,ibm,iks]
---
依照以下说明
在 [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-getting-started) 公有云上搭建 Istio 服务集群。
在 [Istio on IBM Cloud Private](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.1/manage_cluster/istio.html) 私有云上搭建 Istio 服务集群。

{{< tip >}}
IBM 为 IBM Cloud Kubernetes Service 提供了 {{< gloss >}}managed control plane{{< /gloss >}} 插件，
您可以使用它代替手动安装 Istio。
请参阅 [Istio on IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers?topic=containers-istio)
有关详细信息和说明。
{{< /tip >}}

要在手动安装 Istio 之前准备群集，请按照下列步骤操作：

1. [安装 IBM Cloud CLI，IBM Cloud Kubernetes Service 插件和 Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

1. 使用以下命令创建标准的 Kubernetes 集群。
    将 `<cluster-name>` 替换为您用于集群的名称，将 `<zone-name>` 替换为可用区。

    {{< tip >}}
    您可以通过运行 `ibmcloud ks zones` 来显示可用区。
    IBM Cloud Kubernetes Service [位置参考指南](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones)
    介绍可用区域以及如何指定它们。
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-create --zone <zone-name> --machine-type b3c.4x16 \
      --workers 3 --name <cluster-name>
    {{< /text >}}

    {{< tip >}}
    如果已经有专用和公用 VLAN，您可以在上面的命令中指定使用 `--private-vlan` 和 `--public-vlan` 选项。
    否则, 将自动为您创建。您可以通过运行 `ibmcloud ks vlans --zone <zone-name>` 来查看可用的 VLAN。
    {{< /tip >}}

1. 运行以下命令下载您的 `kubectl` 集群配置，然后按照命令输出的说明来设置 `KUBECONFIG` 环境变量。

    {{< text bash >}}
    $ ibmcloud ks cluster-config <cluster-name>
    {{< /text >}}

    {{< warning >}}
    确保使用与集群的 Kubernetes 版本匹配的 `kubectl` CLI 版本。
    {{< /warning >}}
