---
title: 为从集群配置 istioctl
description: 使用代理服务器在具有外部控制平面的网格中支持 istioctl 命令。
publishdate: 2022-03-25
attribution: Frank Budinsky (IBM)
keywords: [istioctl, cli, external, remote, multicluster]
---

当在 {{< gloss >}}remote cluster{{< /gloss >}}，
[外部控制平面](/zh/docs/setup/install/external-controlplane/)或[多集群](/zh/docs/setup/install/multicluster/)
Istio 部署中使用 `istioctl` CLI 时，默认情况下某些命令将不起作用。
例如，`istioctl proxy-status` 需要访问 `istiod`
服务来对其管理的代理状态和配置执行检索操作。所以，如果您尝试在从集群上运行它，
您将收到如下错误消息：

    {{< text bash >}}
    $ istioctl proxy-status
    Error: unable to find any Istiod instances
    {{< /text >}}

请注意，错误消息不仅表示无法访问 `istiod` 服务，而且还特别提到无法找到
`istiod` 实例。这是因为 `istioctl proxy-status`
命令的实现不仅需要检索单个 `istiod` 实例的同步状态，
而且也需要检索其他所有实例的同步状态。当存在多个 `istiod`
实例（副本）在运行时，每个实例仅为连接到网格中运行服务代理的一个子集。
而 `istioctl` 命令需要返回整个网格的状态，
而不仅仅是返回其中一个实例所管理的子集信息。

当 `istiod` 服务运行在集群（即，{{< gloss >}}primary cluster{{< /gloss >}}）本地的普通
Istio 环境中，通过简单查找所有正在运行中 `istiod` Pod 的命令，
依次调用每个 Pod，然后再聚合这些结果并返回给用户。

{{< image width="75%"
    link="istioctl-primary-cluster.svg"
    caption="具有对 istiod Pod 本地访问权限的 CLI"
    >}}

另一方面，当使用从集群时，这个方式就变得不可行，因为 `istiod`
实例在网格集群之外运行，并且对于网格用户来说是无法访问的。
这些实例甚至可能不会使用 Kubernetes 集群上的 Pod 进行部署。

幸运的是，`istioctl` 提供了一个配置选项来解决这个问题。
您可以使用能访问 `istiod` 实例的外部代理服务地址配置 `istioctl`。
与只会将请求委托给一个具体的实例的普通负载均衡器服务不同，
此代理服务会代替委托到所有 `istiod` 实例，聚合响应，然后返回组合结果。

如果外部代理服务实际上在另一个 Kubernetes 集群上运行，
则代理实现代码可能与 `istioctl` 在主集群情况下运行的实现代码非常相似，
就是找到所有正在运行的 `istiod` Pod，依次调用每一个，然后聚合结果。

{{< image width="75%"
    link="istioctl-remote-cluster.svg"
    caption="不具有对 istiod Pod 本地访问权限的 CLI"
    >}}

可以在[此处](https://github.com/istio-ecosystem/istioctl-proxy-sample)找到包含此类
`istioctl` 代理服务器实现的 Istio 生态系统项目。要试用它，
您需要两个集群，其中一个集群使用安装在另一个集群中的控制平面将其配置为从集群。

## 使用从集群拓扑安装 Istio {#install-istio-with-a-remote-cluster-topology}

为了演示 `istioctl` 在从集群上的工作情况，
我们将首先使用[外部控制平面安装说明](/zh/docs/setup/install/external-controlplane/)来安装一个具有在另一个外部集群中运行外部控制平面的独立外部网格。

完成安装后，我们应该有两个环境变量，`CTX_REMOTE_CLUSTER` 和 `CTX_EXTERNAL_CLUSTER`，
分别包含远程（网格）和外部（控制平面）集群的上下文名称。

我们还应该在网格中运行 `helloworld` 和 `sleep`
示例程序，比如在从集群上运行它们：

    {{< text bash >}}
    $ kubectl get pod -n sample --context="${CTX_REMOTE_CLUSTER}"
    NAME                             READY   STATUS    RESTARTS   AGE
    helloworld-v1-776f57d5f6-tmpkd   2/2     Running   0          10s
    sleep-557747455f-v627d           2/2     Running   0          9s
    {{< /text >}}

请注意，如果您尝试在从集群中运行 `istioctl proxy-status` 命令，
您将看到前面描述的错误消息：

    {{< text bash >}}
    $ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
    Error: unable to find any Istiod instances
    {{< /text >}}

## 为 istioctl 配置和使用简单的代理服务{#configure-istioctl-to-use-the-sample-proxy-service}

要对 `istioctl` 进行配置，我们首先需要在运行中的 `istiod` Pod 处部署代理服务。
在我们的安装中，已经在 `external-istiod` 命名空间中部署了控制平面，
因此可以使用以下命令在外部集群上启动代理服务：

    {{< text bash >}}
    $ kubectl apply -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}" \
        -f https://raw.githubusercontent.com/istio-ecosystem/istioctl-proxy-sample/main/istioctl-proxy.yaml
    service/istioctl-proxy created
    serviceaccount/istioctl-proxy created
    secret/jwt-cert-key-secret created
    deployment.apps/istioctl-proxy created
    role.rbac.authorization.k8s.io/istioctl-proxy-role created
    rolebinding.rbac.authorization.k8s.io/istioctl-proxy-role created
    {{< /text >}}

您可以运行以下命令来确认 `istioctl-proxy` 服务与 `istiod` 是否在一起运行：

    {{< text bash >}}
    $ kubectl get po -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME                              READY   STATUS    RESTARTS   AGE
    istioctl-proxy-664bcc596f-9q8px   1/1     Running   0          15s
    istiod-666fb6694d-jklkt           1/1     Running   0          5m31s
    {{< /text >}}

代理服务是一个端口为 9090 的 gRPC 服务器：

    {{< text bash >}}
    $ kubectl get svc istioctl-proxy -n external-istiod --context="${CTX_EXTERNAL_CLUSTER}"
    NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    istioctl-proxy   ClusterIP   172.21.127.192   <none>        9090/TCP   11m
    {{< /text >}}

然而，在我们使用它之前，我们需要将它暴露在外部集群之外。
由于部署环境的不同，有很多方法可以做到这一点。在当前设置中，
我们拥有一个在外部集群上运行的入口网关，因此我们可以更新它来暴露 9090 端口，
然后更新关联的虚拟服务用来将 9090 端口的请求定向到代理服务中，
然后配置 `istioctl`，使用网关地址作为代理服务地址。这是其中一种“合适”的方法。

然而，这只是一个简单地将代理服务 `port-forward` 到 `localhost` 的方式，
让我们可以访问两个集群的简单演示：

    {{< text bash >}}
    $ kubectl port-forward -n external-istiod service/istioctl-proxy 9090:9090 --context="${CTX_EXTERNAL_CLUSTER}"
    {{< /text >}}

我们现在通过设置 `ISTIOCTL_XDS_ADDRESS` 环境变量将 `istioctl`
的访问代理配置为使用 `localhost:9090` 地址：

    {{< text bash >}}
    $ export ISTIOCTL_XDS_ADDRESS=localhost:9090
    $ export ISTIOCTL_ISTIONAMESPACE=external-istiod
    $ export ISTIOCTL_PREFER_EXPERIMENTAL=true
    {{< /text >}}

因为我们的控制平面运行在 `external-istiod` 命名空间，
而不是默认的 `istio-system` 命名空间中，我们需要额外设置
`ISTIOCTL_ISTIONAMESPACE` 环境变量。

设置 `ISTIOCTL_PREFER_EXPERIMENTAL` 环境变量是可选的。
它将 `istioctl` 的 `istioctl command` 调用重定向到实验性等效项
`istioctl x command` 中，对于任何 `command` 都具备稳定版和实验性版本实现。

## 运行 istioctl proxy-status 命令 {#run-the-istioctl-proxy-status-command}

现在我们已经完成了 `istioctl` 的配置，我们可以再次尝试运行
`proxy-status` 命令：

    {{< text bash >}}
    $ istioctl proxy-status --context="${CTX_REMOTE_CLUSTER}"
    NAME                                                      CDS        LDS        EDS        RDS        ISTIOD         VERSION
    helloworld-v1-776f57d5f6-tmpkd.sample                     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
    istio-ingressgateway-75bfd5668f-lggn4.external-istiod     SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
    sleep-557747455f-v627d.sample                             SYNCED     SYNCED     SYNCED     SYNCED     <external>     1.12.1
    {{< /text >}}

如您所见，这次网格中运行的所有服务的同步状态都正确显示了。请注意，
`ISTIOD` 列的返回值为 `<external>`，而不是在 Pod
在本地运行时显示的实例名称（例如，`istiod-666fb6694d-jklkt`）。
在这种情况下，网格用户是无法获得或不需要此详细信息的。
它仅在外部集群上可用，供网格操作员查看。

## 总结 {#summary}

在本文中，我们使用了一个[示例代理服务器](https://github.com/istio-ecosystem/istioctl-proxy-sample)来配置
`istioctl` 并与[安装在外部的控制平面](/zh/docs/setup/install/external-controlplane/)一同工作。
我们已经看到一些 `istioctl` CLI 不能在由外部控制平面管理的从集群上开箱即用的原因。
`istioctl proxy-status` 等命令需要访问 istiod 服务实例来管理网格，
当控制平面在网格集群外部运行时，这些实例是不可用的。为了解决这个问题，
`istioctl` 被配置了与外部控制平面一起运行的代理服务器，用于访问 `istiod` 实例。
