---
title: k3d
description: 为 Istio 设置 k3d 的说明。
weight: 28
skip_seealso: true
keywords: [platform-setup,kubernetes,k3d,k3s]
owner: istio/wg-environments-maintainers
test: no
---

k3d 是在 Docker 中运行 [k3s](https://github.com/rancher/k3s)（Rancher Lab 推出的 Kubernetes 最小发行版）的轻量级包装器。
k3d 使得在 Docker 中创建单节点和多节点 k3s 集群变得非常容易，例如特别适用于 Kubernetes 本地开发。

## 先决条件 {#prerequisites}

- 要使用 k3d，您还需要[安装 Docker](https://docs.docker.com/install/)。
- 安装最新版本 [k3d](https://k3d.io/v5.4.7/#installation)。
- 与 Kubernetes 集群 [kubectl](https://kubernetes.io/zh-cn/docs/docs/tasks/tools/#kubectl) 进行交互。
- (可选) [Helm](https://helm.sh/docs/intro/install/) 是针对 Kubernetes 的包管理器。

## 安装 {#installation}

1. 使用以下命令创建集群并禁用 `Traefik`：

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p '9080:80@loadbalancer' -p '9443:443@loadbalancer' --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

1. 使用以下命令查看 k3d 集群列表：

    {{< text bash >}}
    $ k3d cluster list
    k3s-default
    {{< /text >}}

1. 使用以下命令列举本地 Kubernetes 上下文：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         k3d-k3s-default      k3d-k3s-default      k3d-k3s-default
    {{< /text >}}

    {{< tip >}}
    `k3d-` 是上下文和集群名称的前缀，例如 `k3d-k3s-default`
    {{< /tip >}}

1. 如果运行多个集群，则需要选择 `kubectl` 与哪个集群进行对话。您可以设置默认集群通过在
    [Kubernetes kubeconfig](https://kubernetes.io/zh-cn/docs/concepts/configuration/organize-cluster-access-kubeconfig/)
    文件中设置当前上下文来实现 `kubectl`。此外，您可以运行以下命令为 `kubectl` 设置当前上下文。

    {{< text bash >}}
    $ kubectl config use-context k3d-k3s-default
    Switched to context "k3d-k3s-default".
    {{< /text >}}

## 为 k3d 设置 Istio {#set-up-istio-for-k3d}

1. 完成 k3d 集群的设置后，可以继续在其上[使用 Helm 3 安装 Istio](/zh/docs/setup/install/helm/)。

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ helm install istio-base istio/base -n istio-system --wait
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

1. （可选）安装 Ingress Gateway：

    {{< text bash >}}
    $ helm install istio-ingressgateway istio/gateway -n istio-system --wait
    {{< /text >}}

## 为 k3d 设置 Dashboard 用户界面 {#set-up-dashboard-UI-for-k3d}

k3d 没有像 minikube 这样的内置 Dashboard UI。但是您仍然可以设置 Dashboard
（基于 Web 的 Kubernetes UI）来查看您的集群。
按照以下说明为 k3d 设置 Dashboard。

1. 要部署 Dashboard，请运行以下命令：

    {{< text bash >}}
    $ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    $ helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
    {{< /text >}}

1. 验证 Dashboard 已部署并正在运行。

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-8c47d4b5d-dd2ks    1/1     Running   0          25s
    kubernetes-dashboard-67bd8fc546-4xfmm        1/1     Running   0          25s
    {{< /text >}}

1. 创建 `ServiceAccount` 和 `ClusterRoleBinding` 为新创建的集群提供管理员访问权限。

    {{< text bash >}}
    $ kubectl create serviceaccount -n kubernetes-dashboard admin-user
    $ kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
    {{< /text >}}

1. 要登录到您的 Dashboard，您需要一个承载令牌。使用以下命令将令牌存储在变量中。

    {{< text bash >}}
    $ token=$(kubectl -n kubernetes-dashboard create token admin-user)
    {{< /text >}}

    使用 `echo` 命令显示令牌，并将其复制以用于登录到 Dashboard。

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

1. 您可以通过运行以下命令使用 kubectl 命令行工具访问 Dashboard：

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    单击 [Kubernetes Dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)
    来查看您的部署和服务。

    {{< warning >}}
    您必须保存好令牌，否则每次都需要运行第 4 步获取令牌后才能登录到 Dashboard。
    {{< /warning >}}

## 卸载 {#uninstall}

1. 当您完成实验并想要删除现有集群时，请使用以下命令：

    {{< text bash >}}
    $ k3d cluster delete k3s-default
    Deleting cluster "k3s-default" ...
    {{< /text >}}
