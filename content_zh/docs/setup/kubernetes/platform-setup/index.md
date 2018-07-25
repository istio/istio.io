---
title: Kubernetes 集群设置
description: 为 Istio 进行 Kubernetes 集群设置。
weight: 10
keywords: [kubernetes]
---

依照如下步骤为 Istio 配置 Kubernetes 集群。

## 先决条件

下面的过程中需要：

* 可访问的 **1.9 或更高版本** 的 Kubernetes 集群，并且启用了 [RBAC（基于角色的访问控制）](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)功能，推荐采用 **1.10** 版本。

> 如果已经安装了 Istio 0.2.x，在进行后续工作之前要将其[完全删除](https://archive.istio.io/v0.2/docs/setup/kubernetes/quick-start#uninstalling)。另外还要把启用 Istio 的应用中的 Istio sidecar 全部删除。

## 平台设置

这一节会讲述如何对不同的 Kubernetes 进行设置。

### Minikube

1. 要在本地运行 Istio，可以安装最新版本的 [Minikube](https://kubernetes.io/docs/setup/minikube/)（**0.28.0 或更高**）

1. 选择一个 [虚拟机驱动](https://kubernetes.io/docs/setup/minikube/#quickstart)，安装之后，完成下面的步骤：

    Kubernetes **1.9**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.9.4 \
    --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

    Kubernetes **1.10**:

    {{< text bash >}}
    $ minikube start --memory=4096 --kubernetes-version=v1.10.0 \
    --vm-driver=`your_vm_driver_choice`
    {{< /text >}}

### Google Kubernetes Engine

1. 创建一个新集群：

    {{< text bash >}}
    $ gcloud container clusters create <cluster-name> \
      --cluster-version=1.10.5-gke.0 \
      --zone <zone> \
      --project <project-id>
    {{< /text >}}

1. 为 `kubectl` 获取认证凭据：

    {{< text bash >}}
    $ gcloud container clusters get-credentials <cluster-name> \
        --zone <zone> \
        --project <project-id>
    {{< /text >}}

1. 为了给 Istio 创建 RBAC 规则，需要给当前用户赋予集群管理员权限：

    {{< text bash >}}
    $ kubectl create clusterrolebinding cluster-admin-binding \
        --clusterrole=cluster-admin \
        --user=$(gcloud config get-value core/account)
    {{< /text >}}

### IBM Cloud Kubernetes Service (IKS)

1. 创建新的 `lite` 集群：

    {{< text bash >}}
    $ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

    或者创建一个新的付费集群：

    {{< text bash >}}
    $ bx cs cluster-create --location location --machine-type u2c.2x4 \
      --name <cluster-name> --kube-version 1.9.7
    {{< /text >}}

1. 为 `kubectl` 获取认证凭据。下面的命令需要根据实际情况对 `<cluster-name>` 进行替换：

    {{< text bash >}}
    $(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
    {{< /text >}}

### IBM Cloud Private

[设置 kubectl 客户端](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html)以便进行访问

### OpenShift Origin

缺省情况下，OpenShift 不允许容器使用 User ID（UID） 0 来运行。

下面的命令让 Istio 的 Service account 可以使用 UID 0 来运行容器：

{{< text bash >}}
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-egressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-ingressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-cleanup-old-ca-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account \
  -n istio-system
$ oc adm policy add-scc-to-user anyuid \
  -z istio-sidecar-injector-service-account -n istio-system
{{< /text >}}

上面的账号就是给 Istio 使用的 Service account。如果要启动其它的 Istio 服务，例如 _Grafana_ ，就需要使用类似命令来为其启用 Service account。

运行应用的 Service account 需要在安全上下文约束的条件下具备一定特权，这也是 Sidecar 注入过程的一部分：

{{< text bash >}}
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
{{< /text >}}

> 如果在 Envoy 启动过程中遇到问题，可以参考这一[讨论](https://github.com/istio/issues/issues/34)中关于 `SELINUX` 方面的问题。

### 在 AWS 使用 Kops 安装

如果使用 Kubernetes 1.9 版本，要确认启用 `admissionregistration.k8s.io/v1beta1`。

另外还需要执行下面的更新操作。

1. 打开配置文件：

    {{< text bash >}}
    $ kops edit cluster $YOURCLUSTER
    {{< /text >}}

1. 在其中加入下列内容：

    {{< text yaml >}}
    kubeAPIServer:
        admissionControl:
        - NamespaceLifecycle
        - LimitRanger
        - ServiceAccount
        - PersistentVolumeLabel
        - DefaultStorageClass
        - DefaultTolerationSeconds
        - MutatingAdmissionWebhook
        - ValidatingAdmissionWebhook
        - ResourceQuota
        - NodeRestriction
        - Priority
    {{< /text >}}

1. 执行更新：

    {{< text bash >}}
    $ kops update cluster
    $ kops update cluster --yes
    {{< /text >}}

1. 执行滚动更新：

    {{< text bash >}}
    $ kops rolling-update cluster
    $ kops rolling-update cluster --yes
    {{< /text >}}

1. 使用 `kubectl` 在 `kube-api` Pod 上检查 Admission Controller 的的启用情况：

    {{< text bash >}}
    $ for i in `kubectl \
      get pods -nkube-system | grep api | awk '{print $1}'` ; \
      do  kubectl describe pods -nkube-system \
      $i | grep "/usr/local/bin/kube-apiserver"  ; done
    {{< /text >}}

1. 查看输出内容：

    {{< text plain >}}
    [...]
    --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,
    PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,
    MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,
    NodeRestriction,Priority
    [...]
    {{< /text >}}

### Azure

必须用 `ACS-Engine` 进行部署：

1. 按照下面的[介绍](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install)，下载和安装 `acs-engine`。

1. 下载 Istio 的 API 模型定义文件：

    {{< text bash >}}
    $ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
    {{< /text >}}

1. 使用 `istio.json` 模板定义集群。其中的参数可以在[官方文档](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition)中找到。

    | 参数                             | 说明             |
    |---------------------------------------|----------------------------|
    | `subscription_id`                     | Azure 订阅 ID  |
    | `dns_prefix`                          | 集群 DNS 前缀         |
    | `location`                            | 集群位置           |

    {{< text bash >}}
    $ acs-engine deploy --subscription-id <subscription_id> \
      --dns-prefix <dns_prefix> --location <location> --auto-suffix \
      --api-model istio.json
    {{< /text >}}

    > 几分钟之后，就可以在 Azure 订阅中发现一个资源组，命名方式是 `<dns_prefix>-<id>`。假设 `dns-prefix` 取值为 `myclustername`，会在后面加入一个随机 ID 后缀，生成资源组名，例如 `mycluster-5adfba82`。`acs-engine` 会生成 `kubeconfig` 文件，放置到 `_output` 文件夹中。

1. 使用  `<dns_prefix>-<id>` 集群 ID，把 `kubeconfig` 从 `_output` 文件夹中复制出来：

    {{< text bash >}}
    $ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json \
        ~/.kube/config
    {{< /text >}}

    例如：

    {{< text bash >}}
    $ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json \
      ~/.kube/config
    {{< /text >}}

1. 检查 Istio 所需的参数是否已经正确设置：

    {{< text bash >}}
    $ kubectl describe pod --namespace kube-system
    $(kubectl get pods --namespace kube-system | grep api | cut -d ' ' -f 1) \
      | grep admission-control
    {{< /text >}}

1. 确认 `MutatingAdmissionWebhook` 和 `ValidatingAdmissionWebhook` 是否存在：

    {{< text plain >}}
    --admission-control=...,MutatingAdmissionWebhook,...,
    ValidatingAdmissionWebhook,...
    {{< /text >}}
