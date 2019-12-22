---
title: MicroK8s
description: 配置 MicroK8s 以便使用 Istio。
weight: 20
skip_seealso: true
aliases:
    - /zh/docs/setup/kubernetes/prepare/platform-setup/MicroK8s/
    - /zh/docs/setup/kubernetes/platform-setup/MicroK8s/
keywords: [platform-setup,kubernetes,MicroK8s]
---

请按照如下说明准备 MicroK8s 以便使用 Istio。

{{< warning >}}
运行 MicroK8s 需要管理员权限。
{{< /warning >}}

1.  使用如下命令安装最新版本的 [MicroK8s](https://microk8s.io)

    {{< text bash >}}
    $ sudo snap install microk8s --classic
    {{< /text >}}

1.  使用如下命令启用 Istio。

    {{< text bash >}}
    $ microk8s.enable istio
    {{< /text >}}

1.  当提示出现时，您需要选择是否在 sidecars 之间强制进行双向 TLS 认证。
    如果您有不支持 Istio 和支持 Istio 服务的混合部署，或者您不确定，请选择 No。

请运行以下命令来检查部署进度：

    {{< text bash >}}
    $ watch microk8s.kubectl get all --all-namespaces
    {{< /text >}}