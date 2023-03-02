---
title: k3d
description: Instructions to set up k3d for Istio.
weight: 28
skip_seealso: true
keywords: [platform-setup,kubernetes,k3d,k3s]
owner: istio/wg-environments-maintainers
test: no
---

k3d 是在 docker 中运行 [k3s](https://github.com/rancher/k3s) (Rancher Lab 的最小 Kubernetes 分布)的轻量级包装器。
k3d 使得在 docker 中创建单节点和多节点 k3s 集群变得非常容易，例如用于 Kubernetes 的本地开发。

## 先决条件

- 要使用 k3d，您还需要 [安装 docker](https://docs.docker.com/install/)。
- 安装 [k3d] 的最新版本 (https://k3d.io/v5.4.7/#installation)。
- 与Kubernetes 集群 [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)进行交互。
- (可选) [Helm](https://helm.sh/docs/intro/install/)是Kubernetes 的软件包管理器。

## 安装

1. 创建集群并使用以下命令禁用 `Traefik`:

    {{< text bash >}}
    $ k3d cluster create --api-port 6550 -p "9080:80@loadbalancer"  -p "9443:443@loadbalancer" --agents 2 --k3s-arg '--disable=traefik@server:*'
    {{< /text >}}

2. 查看 k3d 集群列表，请使用以下命令:

    {{< text bash >}}
    $ k3d cluster list
    k3s-default
    {{< /text >}}

3. 列出本地 Kubernetes 上下文，请使用以下命令。

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         k3d-k3s-default      k3d-k3s-default      k3d-k3s-default
    {{< /text >}}

    {{< tip >}}
    `k3d-` is prefixed to the context and cluster names, for example: `k3d-k3s-default`
    {{< /tip >}}

4. 如果运行多个集群，则需要选择 `kubectl` 与哪个集群进行对话。您可以设置默认集群通过在 [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) 文件中设置当前上下文来实现 `kubectl`。此外，您可以运行以下命令为 `kubectl` 设置当前上下文。

    {{< text bash >}}
    $ kubectl config use-context k3d-k3s-default
    Switched to context "k3d-k3s-default".
    {{< /text >}}

## 为 k3d 设置 Istio

1. 完成 k3d 集群的设置后，可以继续在其上 [使用 Helm 3安装 Istio](/docs/setup/install/helm/)。

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ helm install istio-base istio/base -n istio-system --wait
    $ helm install istiod istio/istiod -n istio-system --wait
    {{< /text >}}

2. (可选) 安装入口网关:

    {{< text bash >}}
    $ kubectl label namespace istio-system istio-injection=enabled
    $ helm install istio-ingressgateway istio/gateway -n istio-system --wait
    {{< /text >}}

## 为 k3d 设置仪表板用户界面

k3d 没有像 minikube 这样的内置仪表板 UI。但是您仍然可以设置 Dashboard (基于 web 的 Kubernetes UI) 来查看您的集群。
按照以下说明为 k3d 设置仪表板。

1. 要部署仪表板，请运行以下命令:

    {{< text bash >}}
    $ GITHUB_URL=https://github.com/kubernetes/dashboard/releases
    $ VERSION_KUBE_DASHBOARD=$(curl -w '%{url_effective}' -I -L -s -S ${GITHUB_URL}/latest -o /dev/null | sed -e 's|.*/||')
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${VERSION_KUBE_DASHBOARD}/aio/deploy/recommended.yaml
    {{< /text >}}

2. 验证仪表板已部署并正在运行。

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-8c47d4b5d-dd2ks    1/1     Running   0          25s
    kubernetes-dashboard-67bd8fc546-4xfmm        1/1     Running   0          25s
    {{< /text >}}

3. 创建 `serviceaccount` 和 `clusterrolebinding` 为新创建的集群提供管理员访问权限。

    {{< text bash >}}
    $ kubectl create serviceaccount -n kubernetes-dashboard admin-user
    $ kubectl create clusterrolebinding -n kubernetes-dashboard admin-user --clusterrole cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
    {{< /text >}}

4. 要登录到您的仪表板，您需要一个承载令牌。使用以下命令将令牌存储在变量中。

    {{< text bash >}}
    $ token=$(kubectl -n kubernetes-dashboard create token admin-user)
    {{< /text >}}

    Display the token using the `echo` command and copy it to use for logging in to your Dashboard.

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

5. 您可以通过运行以下命令使用 kubectl 命令行工具访问仪表板:

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    单击 [Kubernetes 仪表板](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) 来查看您的部署和服务。

    {{< warning >}}
    You have to save your token somewhere, otherwise you have to run step number 4 everytime you need a token to log in to your Dashboard.
    {{< /warning >}}

## 卸载

1. 当您完成实验并想要删除现有集群时，请使用以下命令:

    {{< text bash >}}
    $ k3d cluster delete k3s-default
    Deleting cluster "k3s-default" ...
    {{< /text >}}
