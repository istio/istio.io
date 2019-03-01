---
title: IBM Cloud 快速入门
description: 如何使用 IBM 公有云或 IBM 私有云快速安装 Istio。
weight: 21
keywords: [kubernetes,ibm,icp]
---

参照以下说明，在 IBM Cloud 上安装和运行 Istio。你可以选择安装在 [IBM 公有云](#ibm-公有云)或 [IBM 私有云](#ibm-私有云)上.

## IBM 公有云

在 [IBM 公有云](https://www.ibm.com/cloud/)中，使用 Helm 和 IBM Cloud Kubernetes Service 安装和运行 Istio。

本指南将安装 Istio 的当前发布版本。

### 前置条件 - IBM 公有云

-  [安装 IBM Cloud CLI，IBM Cloud Kubernetes Service 插件，以及 Kubernetes CLI](https://console.bluemix.net/docs/containers/cs_cli_install.html)。Istio 需要 Kubernetes 1.9 版本及更新的版本。确保安装的 `kubectl` CLI 版本与集群中 Kubernetes 版本一致。
-  确保 Kubernetes 集群的版本是 1.9 或之后的版本。如果你还没有一个可用的集群，[创建一个 1.9 版本或更新版本的集群](https://console.bluemix.net/docs/containers/cs_clusters.html)。
-  通过执行 `ibmcloud ks cluster-config <cluster_name_or_ID>` 将 CLI 指向你的集群，然后对输出的命令进行拷贝粘贴。

### 初始化 Helm 和 Tiller

1. 安装 [Helm CLI](https://docs.helm.sh/using_helm/#installing-helm)。

1. 在 `kube-system` namespace 为 Tiller 创建一个 Service account，以及一个与 pod `tiller-deploy` 绑定的 Kubernetes RBAC 集群角色:

    {{< text yaml >}}
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: tiller
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: tiller
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
      - kind: ServiceAccount
        name: tiller
        namespace: kube-system
    {{< /text >}}

1. 执行创建 Service account 并绑定集群角色：

    {{< text bash >}}
    $ kubectl create -f rbac-config.yaml
    {{< /text >}}

1. 初始化 Helm 并安装 Tiller：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 将 IBM Cloud 的 Helm 仓库地址添加到你的 Helm 实例：

    {{< text bash >}}
    $ helm repo add ibm-charts https://registry.bluemix.net/helm/ibm-charts
    {{< /text >}}

### 部署 Istio Helm chart

1. 如果使用 2.10.0 之前的 Helm 版本，请通过 `kubectl apply` 命令安装 Istio 的 CRD，并等待几秒钟：

    {{< text bash >}}
    $ kubectl apply -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml
    {{< /text >}}

1. 在你的集群中安装 Helm chart：

    {{< text bash >}}
    $ helm install ibm-charts/ibm-istio --name=istio --namespace istio-system
    {{< /text >}}

1. 确保 Istio 的 9 个 Pod 和 Prometheus 的 pod 已经完全部署好：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS      RESTARTS   AGE
    istio-citadel-748d656b-pj9bw               1/1       Running     0          2m
    istio-egressgateway-6c65d7c98d-l54kg       1/1       Running     0          2m
    istio-galley-65cfbc6fd7-bpnqx              1/1       Running     0          2m
    istio-ingressgateway-f8dd85989-6w6nj       1/1       Running     0          2m
    istio-pilot-5fd885964b-l4df6               2/2       Running     0          2m
    istio-policy-56f4f4cbbd-2z2bk              2/2       Running     0          2m
    istio-sidecar-injector-646655c8cd-rwvsx    1/1       Running     0          2m
    istio-statsd-prom-bridge-7fdbbf769-8k42l   1/1       Running     0          2m
    istio-telemetry-8687d9d745-mwjbf           2/2       Running     0          2m
    prometheus-55c7c698d6-f4drj                1/1       Running     0          2m
    {{< /text >}}

### 升级

1. 将你的 Istio Helm chart 升级到最新版本：

    {{< text bash >}}
    $ helm upgrade -f config.yaml istio ibm/ibm-istio
    {{< /text >}}

### 卸载 Istio

1. 卸载 Istio 的 Helm 部署：

    {{< text bash >}}
    $ helm del istio --purge
    {{< /text >}}

    如果你的 Helm 版本低于 2.9.0，那么在重新部署新版本的 Istio Chart 之前，您需要手动清理额外的 Job 资源：

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}

1. 如果需要，删除 Istio CRD：

    {{< text bash >}}
    $ kubectl delete -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml
    {{< /text >}}

## IBM 私有云

使用 `Catalog` 模块在 [IBM 私有云](https://www.ibm.com/cloud/private)安装和运行 Istio。

本指南将安装 Istio 的当前发布版本。

### 前置条件 - IBM 私有云

- 你需要有一个可用的 IBM 私有云集群。否则，你可以参照[安装 IBM 私有云](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/installing/install_containers_CE.html)的指引创建一个 IBM 私有云集群。

### 使用 `Catalog` 模块部署 Istio

- 登录到 **IBM 私有云** 控制台。
- 点击导航栏右侧的 `Catalog`。
- 点击搜索框右侧的 `Filter` 并选中 `ibm-charts` 复选框。
- 点击左侧导航窗格的 `Operations`。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-catalog-1.png" caption="IBM 私有云 - Istio 目录" >}}

- 点击右侧面板中的 `ibm-istio`。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-catalog-2.png" caption="IBM 私有云 - Istio 目录" >}}

- （可选的）使用 `CHART VERSION` 的下拉功能修改 Istio 版本。
- 点击 `Configure` 按钮。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-installation-1.png" caption="IBM 私有云 - 安装 Istio" >}}

- 输入 Helm 部署实例的名称（例如：`istio-1.0.3`），并选择 `istio-system` 作为目标 namespace。
- 同意许可条款。
- （可选的）点击 `All parameters` 自定义安装参数。
- 点击 `Install` 按钮。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-installation-2.png" caption="IBM 私有云 - 安装 Istio" >}}

安装完成后，你可以在 **Helm Releases** 页通过搜索实例名找到它。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-release.png" caption="IBM 私有云 - 安装 Istio" >}}

### 升级或回滚

- 登录到 **IBM 私有云**控制台。
- 点击导航栏左侧的菜单按钮。
- 点击 `Workloads` 并选中 `Helm Releases`。
- 通过实例名找到已安装的 Istio。
- 点击 `Action` 然后选择 `upgrade` 或 `rollback`。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-upgrade-1.png" caption="IBM 私有云 - Istio 升级或回滚" >}}

{{< image link="/docs/setup/kubernetes/install/ibm/istio-upgrade-2.png" caption="IBM 私有云 - Istio 升级或回滚" >}}

### 卸载

- 登录到 **IBM 私有云**控制台。
- 点击导航栏左侧的菜单按钮。
- 点击 `Workloads` 并选中 `Helm Releases`。
- 通过实例名找到已安装的 Istio。
- 点击 `Action` 并选择 `delete`。

{{< image link="/docs/setup/kubernetes/install/ibm/istio-deletion.png" caption="IBM 私有云 - 卸载 Istio" >}}
