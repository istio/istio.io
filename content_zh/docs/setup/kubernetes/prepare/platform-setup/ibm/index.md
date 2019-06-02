---
title: IBM Cloud
description: 为 IBM Cloud 集群设置 Istio 的说明。
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

1. [安装 IBM Cloud CLI，IBM Cloud Kubernetes Service 插件和 Kubernetes CLI](https://cloud.ibm.com/docs/containers?topic=containers-cs_cli_install).

1. 创建标准 Kubernetes 集群。将 `<cluster-name>` 替换为您要在以下说明中使用的集群的名称。

    {{< tip >}}
    要查看可用区域 (zone)，请运行 `ibmcloud ks zones`。区域 (zone)彼此隔离，确保没有共享的单点故障。 IBM Cloud Kubernetes 服务[地区 (Region)和区域 (zone)](https://cloud.ibm.com/docs/containers?topic=containers-regions-and-zones)描述了地区 (Region)，区域 (zone)以及如何为新地区 (Region)和区域 (zone)指定地区 (Region)和区域 (zone)集群。
    {{< /tip >}}

    {{< tip >}}
    下面的命令不包含 `--private-vlan value` 和 `--public-vlan value` 选项。要查看可用的 VLAN，请运行 `ibmcloud ks vlan-ls --zone <zone-name>`。如果您还没有私有 VLAN 和公共 VLAN，则会自动为您创建它们。如果您已经拥有 VLAN，则需要使用 `--private-vlan value` 和 `--public-vlan value` 选项指定它们。
    {{< /tip >}}

    {{< text bash >}}
    $ ibmcloud ks cluster-create --zone <zone-name> --machine-type b2c.4x16 \
      --name <cluster-name>
    {{< /text >}}

1.  获取 `kubectl` 的认证凭据。

    {{< text bash >}}
    $(ibmcloud ks cluster-config <cluster-name> --export)
    {{< /text >}}

{{< warning >}}
确保使用与您的集群的 Kubernetes 版本匹配的 `kubectl` 版本。
{{< /warning >}}

## IBM Cloud Private

[设置 `kubectl` 客户端](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/manage_cluster/cfc_cli.html)以便对 IBM Cloud Private 进行访问
