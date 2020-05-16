---
title: 设置本地计算机
overview: 为该教程设置本地计算机。
weight: 3
---

{{< boilerplate work-in-progress >}}

在本模块中，您将为教程准备本地计算机

1. 安装 [`curl`](https://curl.haxx.se/download.html)。

1. 安装 [Node.js](https://nodejs.org/en/download/)。

1. 安装 [Docker](https://docs.docker.com/install/)。

1. 安装 [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)。

1. 为您从教程中收到的配置文件或者在上一个模块自己创建的配置文件设置环境变量 `KUBECONFIG`。

    {{< text bash >}}
    $ export KUBECONFIG=<the file you recieved or created in the previous module>
    {{< /text >}}

1. 通过打印当前命名空间来验证配置是否生效：

    {{< text bash >}}
    $ kubectl config view -o jsonpath="{.contexts[?(@.name==\"$(kubectl config current-context)\")].context.namespace}"
    tutorial
    {{< /text >}}

    您应该在输出中看到命名空间的名称，该命名空间由讲师分配或者在上一个模块中由您自己分配。

1. 下载一个 [Istio 发行版](https://github.com/istio/istio/releases) ，从 `bin` 目录下提出命令行工具 `istioctl`，使用下边的命令验证 `istioctl` 是否可以正常使用：

    {{< text bash >}}
    $ istioctl version
    version.BuildInfo{Version:"release-1.1-20190214-09-16", GitRevision:"6113e155ac85e2485e30dfea2b80fd97afd3130a", User:"root", Host:"4496ae63-3039-11e9-86e9-0a580a2c0304", GolangVersion:"go1.10.4", DockerHub:"gcr.io/istio-release", BuildStatus:"Clean", GitTag:"1.1.0-snapshot.6-6-g6113e15"}
    {{< /text >}}

恭喜，您已配置完毕本地计算机！

接下来[在本地运行微服务](/zh/docs/examples/microservices-istio/single/)。

