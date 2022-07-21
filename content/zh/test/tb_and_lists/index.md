---
title: 文本块和列表
description: 编写文本块和列表。
skip_sitemap: true
---

1. 一个项目编号

    {{< text plain >}}
    嵌套在一个项目编号中的文本块
    有第二行

    和第三行
    {{< /text >}}

1. 另一个项目编号

    {{< warning >}}
    一条嵌套的警告
    {{< /warning >}}

    {{< text plain >}}
    另一个嵌套的文本块
    有第二行

    和第三行
    {{< /text >}}

1. 又一个项目编号

    第二段

1. 还是一个项目编号

    {{< warning >}}
    这是带项目编号的一条警告。

    {{< text plain >}}
    这是带项目编号的警告中的一个文本块
    有第二行

    和第三行
    {{< /text >}}

    {{< /warning >}}

1.  使用 `kubectl` 命令部署您的应用程序：

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo.yaml@
    {{< /text >}}

    {{< warning >}}
    如果您在安装期间禁用了自动 Sidecar 注入且采用
    [手动 Sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#manual-sidecar-injection)，
    请先用 `istioctl kube-inject` 命令修改 `bookinfo.yaml` 文件，然后再部署您的应用程序。
    有关更多信息，请查阅 `istioctl` [参考文档](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject)。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo.yaml@)
    {{< /text >}}

    {{< /warning >}}

    这条命令将启动 `bookinfo` 应用程序架构图中显示的全部四个服务。
    审阅服务的 3 个版本（v1、v2 和 v3）都会被启动。

    {{< tip >}}
    在实际的部署过程中，会随着时间部署新版本的微服务，并不会同时部署所有版本。
    {{< /tip >}}
