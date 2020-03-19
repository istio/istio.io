---
title: kind
description: 为 Istio 设置 kind 的说明。
weight: 17
skip_seealso: true
keywords: [platform-setup,kubernetes,kind]
---

[kind](https://kind.sigs.k8s.io/) 是一种使用 Docker 容器 `nodes` 运行本地 Kubernetes 集群的工具。
kind 主要是为了测试 Kubernetes 自身而设计的，但它也可用于本地开发或 CI。
请按照以下说明为 Istio 安装准备好 kind 集群。

## 准备{#prerequisites}

- 请使用最新的 Go 版本，最好是 Go 1.13 或更新版本。
- 为了使用 kind，还需要[安装 docker](https://docs.docker.com/install/)。
- 安装最新版本的 [kind](https://kind.sigs.k8s.io/docs/user/quick-start/)。

## 安装步骤{#installation-steps}

1. 使用下列命令创建一个集群：

    {{< text bash >}}
    $ kind create cluster --name istio-testing
    {{< /text >}}

    `--name` 用于为集群指定一个名字。默认情况下，该集群将会名为 `kind`。

1. 使用下列命令查看 kind 集群列表：

    {{< text bash >}}
    $ kind get clusters
    istio-testing
    {{< /text >}}

1. 使用下列命令查看本地 Kubernetes 环境：

    {{< text bash >}}
    $ kubectl config get-contexts
    CURRENT   NAME                 CLUSTER              AUTHINFO             NAMESPACE
    *         kind-istio-testing   kind-istio-testing   kind-istio-testing
              minikube             minikube             minikube
    {{< /text >}}

    {{< tip >}}
    `kind` 会作为前缀加到环境和集群名上，如：`kind-istio-testing`
    {{< /tip >}}

1. 如果运行了多套集群，还需要选择 `kubectl` 将要操作哪一套。
    可以在 [Kubernetes kubeconfig](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) 文件中设置当前环境来指定一个默认集群。
    另外，还可以运行下列命令来为 `kubectl` 设置当前环境：

    {{< text bash >}}
    $ kubectl config use-context kind-istio-testing
    Switched to context "kind-istio-testing".
    {{< /text >}}

    kind 集群设置完成后，就可以开始在它上面[安装 Istio](/zh/docs/setup/getting-started/#download) 了。

1. 当体验过后，想删除集群时，可以使用以下命令：

    {{< text bash >}}
    $ kind delete cluster --name istio-testing
    Deleting cluster "istio-testing" ...
    {{< /text >}}

## 为 kind 设置操作界面{#setup-Dashboard-for-kind}

kind 不像 minikube 一样内置了操作界面。但仍然可以设置一个基于网页的 Kubernetes 界面，以查看集群。
参考以下说明来为 kind 设置操作界面。

1. 运行以下命令以部署操作界面：

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
    {{< /text >}}

1. 验证操作界面已经部署并且正在运行。

    {{< text bash >}}
    $ kubectl get pod -n kubernetes-dashboard
    NAME                                         READY   STATUS    RESTARTS   AGE
    dashboard-metrics-scraper-76585494d8-zdb66   1/1     Running   0          39s
    kubernetes-dashboard-b7ffbc8cb-zl8zg         1/1     Running   0          39s
    {{< /text >}}

1. 创建 `ClusterRoleBinding` 以提供对新创建的集群的管理权限访问。

    {{< text bash >}}
    $ kubectl create clusterrolebinding default-admin --clusterrole cluster-admin --serviceaccount=default:default
    {{< /text >}}

1. 需要用 Bearer Token 来登录到操作界面。使用以下命令将 token 保存到变量。

    {{< text bash >}}
    $ token=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d)
    {{< /text >}}

    使用 `echo` 命令显示 token 并复制它，以用于登录到操作界面。

    {{< text bash >}}
    $ echo $token
    {{< /text >}}

1. 使用 kubectl 命令行工具运行以下命令以访问操作界面：

    {{< text bash >}}
    $ kubectl proxy
    Starting to serve on 127.0.0.1:8001
    {{< /text >}}

    点击 [Kubernetes Dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/) 来查看部署和服务。

    {{< warning >}}
    最好将 token 保存起来，不然每次登录到操作界面需要 token 时都得重新运行上述步骤 4.
    {{< /warning >}}
