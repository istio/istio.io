---
title: 快速开始
description: 在kubernetes集群中快速安装Istio service mesh的说明。
weight: 10
keywords: [kubernetes]
---

本页面在kubernetes集群中快速安装Istio service mesh的说明。

## 前置条件

下面的操作说明需要您可以访问kubernetes **1.9 或更高版本** 的集群，并且启用了 [RBAC (基于角色的访问控制)](https://kubernetes.io/docs/admin/authorization/rbac/)。您需要安装了**1.9 或更高版本** 的 `kubectl` 命令。

如果您希望启用[自动注入sidecar](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)，您必须使用kubernetes 1.9或更高版本。

  > 如果您安装的是Istio 0.2.x，在安装新版本之前请将其完全[卸载](https://archive.istio.io/v0.2/docs/setup/kubernetes/quick-start#uninstalling)（包括所有启用了Istio的Pod中的sidecar）。

* 安装或更新kubernetes命令行工具[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)以匹配集群的版本 （1.9或者更高，支持CRD功能）

### Minikube

要在本地安装Istio，请安装最新版本的[Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)（0.25.0或更高版本）。

Kubernetes 1.9

```command
$ minikube start \
    --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.Admission.PluginNames=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
    --kubernetes-version=v1.9.0
```

Kubernetes 1.10

```command
$ minikube start \
    --extra-config=controller-manager.cluster-signing-cert-file="/var/lib/localkube/certs/ca.crt" \
    --extra-config=controller-manager.cluster-signing-key-file="/var/lib/localkube/certs/ca.key" \
    --extra-config=apiserver.admission-control="NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota" \
    --kubernetes-version=v1.10.0
```

### Google Kubernetes Engine

创建集群。

```command
$ gcloud container clusters create <cluster-name> \
    --cluster-version=1.9.7-gke.1 \
    --zone <zone> \
    --project <project-name>
```

获取`kubectl`使用的证书。

```command
$ gcloud container clusters get-credentials <cluster-name> \
    --zone <zone> \
    --project <project-name>
```

为当前用户授权管理员权限（为Istio创建必需的RBAC规则需要使用管理员权限）。

```command
$ kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)
```

### IBM Cloud Kubernetes Service (IKS)

创建一个新的精简版集群。

```command
$ bx cs cluster-create --name <cluster-name> --kube-version 1.9.7
```

或者创建一个新的付费群集：

```command
$ bx cs cluster-create --location location --machine-type u2c.2x4 --name <cluster-name> --kube-version 1.9.7
```

获取`kubectl`使用的证书（使用您自己集群的名字替换下面的`<cluster-name>`）：

```bash
$(bx cs cluster-config <cluster-name>|grep "export KUBECONFIG")
```

### IBM Cloud Private

要访问IBM Cloud Private Cluster，请按照[这里](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0/manage_cluster/cfc_cli.html)的步骤配置`kubectl` CLI。

### OpenShift Origin

默认情况下OpenShift不允许容器使用UID 0来运行。为Istio的service account启动容器以UID 0运行：

```command
$ oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z default -n istio-system
$ oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
$ oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
```

以上列出了Istio中包含的所有默认的service account。如果您想启用Istio的其他服务（例如*Grafana*）需要使用类似的命令来涵盖那些服务。

运行应用程序pod的service account需要特权的安全上下文约束以作为sidecar注入的一部分。

```command
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
```

> 检查该[讨论](https://github.com/istio/issues/issues/34)中关于Istio的`SELINUX`问题，以防出现Envoy的问题。

### AWS (w/Kops)

在安装Kubernetes 1.9版的新集群时，将涵盖启用`admissionregistration.k8s.io/v1beta1`的先决条件。

然而，准入控制器的列表需要更新。

```command
$ kops edit cluster $YOURCLUSTER
```

在配置文件中增加以下内容：

```yaml
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
```

执行更新

```command
$ kops update cluster
$ kops update cluster --yes
```

启动滚动更新

```command
$ kops rolling-update cluster
$ kops rolling-update cluster --yes
```

使用kube-api pod上`的kubectl`客户端进行验证，您应该看到新的准入控制器：

```command
$ for i in `kubectl get pods -nkube-system | grep api | awk '{print $1}'` ; do  kubectl describe pods -nkube-system $i | grep "/usr/local/bin/kube-apiserver"  ; done
```

输出应该是：

```plain
[...] --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,NodeRestriction,Priority [...]
```

### Azure

你应该使用`ACS-Engine`来部署集群。按照[这些说明](https://github.com/Azure/acs-engine/blob/master/docs/acsengine.md#install)来获取和安装`acs-engine`二进制包，使用下面的命令下载Istio `api model definition`：

```command
$ wget https://raw.githubusercontent.com/Azure/acs-engine/master/examples/service-mesh/istio.json
```

使用`istio.json`模板和以下命令部署集群。您可以在[官方文档](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/deploy.md#step-3-edit-your-cluster-definition)中找到参数的参考。

| 参数                       | 期望值             |
|-------------------------------------|----------------------------|
| `subscription_id`                     | Azure订阅ID |
| `dns_prefix`                          | 集群DNS前缀       |
| `location`                            | 集群位置         |

```command
$ acs-engine deploy --subscription-id <subscription_id> --dns-prefix <dns_prefix> --location <location> --auto-suffix --api-model istio.json
```

几分钟后，您应该在名为`<dns_prefix>-<id>`的资源组中找到您的Azure订阅集群。假设我的`dns_prifex` 是 `myclustername`，有效的资源组和唯一的集群ID是`mycluster-5adfba82`。使用这个`<dns_prefix>-<id>`集群ID，您可以将`acs-engine`生成的`kubeconfig`文件从`_output`文件夹复制到您的机器中：

```command
$ cp _output/<dns_prefix>-<id>/kubeconfig/kubeconfig.<location>.json ~/.kube/config
```

例如：

```command
$ cp _output/mycluster-5adfba82/kubeconfig/kubeconfig.westus2.json ~/.kube/config
```

要检查是否部署了正确的Istio标志，请使用：

```command
$ kubectl describe pod --namespace kube-system $(kubectl get pods --namespace kube-system | grep api | cut -d ' ' -f 1) | grep admission-control
```

您应该可以看到`MutatingAdmissionWebhook`和`ValidatingAdmissionWebhook`标志：

```plain
      --admission-control=...,MutatingAdmissionWebhook,...,ValidatingAdmissionWebhook,...
```

## 下载和准备安装

从 0.2 版本开始，Istio 安装到 `istio-system` namespace 下，即可以管理所有其它 namespace 下的微服务。

1. 到 [Istio release](https://github.com/istio/istio/releases) 页面上，根据您的操作系统下载对应的发行版。如果您使用的是 MacOS 或者 Linux 系统，可以使用下面的额命令自动下载和解压最新的发行版：

    ```command
    $ curl -L https://git.io/getLatestIstio | sh -
    ```

1. 解压安装文件，切换到文件所在目录。安装文件目录下包含：

    * `install/` 目录下是 kubernetes 使用的 `.yaml` 安装文件
    * `samples/` 目录下是示例程序
    * `istioctl` 客户端二进制文件在`bin`目录下。`istioctl`文件用户手动注入Envoy sidecar代理、创建路由和策略等
    * `istio.VERSION` 配置文件

1. 切换到Istio包的解压目录。例如istio-{{< istio_version >}}.0：

    ```command
    $ cd istio-{{< istio_version >}}.0
    ```

1. 将`istioctl`客户端二进制文件加到PATH中。
  例如，在 MacOS 或 Linux 系统上执行下面的命令：

    ```command
    $ export PATH=$PWD/bin:$PATH
    ```

## 安装步骤

安装Istio的核心部分。从以下四种_**非手动**_部署方式中选择一种方式安装。然而，我们推荐您在生产环境时使用[Helm Chart](/docs/setup/kubernetes/helm-install/)来安装Istio，这样可以按需定制配置选项。

*  安装Istio而不启用sidecar之间的[双向TLS验证](/docs/concepts/security/mutual-tls/)。对于现有应用程序的集群，使用Istio sidecar的服务需要能够与其他非Istio Kubernetes服务以及使用[存活和就绪探针](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)、headless服务或StatefulSets的应用程序通信的应用程序选择此选项。

```command
$ kubectl apply -f install/kubernetes/istio-demo.yaml
```

或者

*  默认情况下安装Istio，并强制在sidecar之间进行双向TLS身份验证。仅在保证新部署的工作负载安装了Istio sidecar的新建的kubernetes集群上使用此选项。

```command
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
```

或者

*  [使用Helm渲染出Kubernetes配置清单然后使用kubectl部署](/docs/setup/kubernetes/helm-install/#option-1-install-with-helm-via-helm-template)

或者

*  [使用Helm和Tiller管理Istio部署](/docs/setup/kubernetes/helm-install/#option-2-install-with-helm-and-tiller-via-helm-install)

## 确认安装

1. 确认下列Kubernetes服务已经部署：`istio-pilot`、 `istio-ingressgateway`、`istio-policy`、`istio-telemetry`、`prometheus` 、`istio-sidecar-injector`（可选）。

    ```command
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP   EXTERNAL-IP     PORT(S)                                                               AGE
    istio-citadel              ClusterIP      30.0.0.119   <none>          8060/TCP,9093/TCP                                                     7h
    istio-egressgateway        ClusterIP      30.0.0.11    <none>          80/TCP,443/TCP                                                        7h
    istio-ingressgateway       LoadBalancer   30.0.0.39    9.111.255.245   80:31380/TCP,443:31390/TCP,31400:31400/TCP                            7h
    istio-pilot                ClusterIP      30.0.0.136   <none>          15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   7h
    istio-policy               ClusterIP      30.0.0.242   <none>          9091/TCP,15004/TCP,9093/TCP                                           7h
    istio-statsd-prom-bridge   ClusterIP      30.0.0.111   <none>          9102/TCP,9125/UDP                                                     7h
    istio-telemetry            ClusterIP      30.0.0.246   <none>          9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 7h
    prometheus                 ClusterIP      30.0.0.253   <none>          9090/TCP                                                              7h
    ```

    > 如果您的集群在不支持外部负载均衡器的环境中运行（例如minikube），`istio-ingressgateway`的`EXTERNAL-IP`将会显示为`<pending>`状态。您将需要使用服务的NodePort来访问，或者使用port-forwarding。

1. 确保所有相应的Kubernetes pod都已被部署且所有的容器都已启动并正在运行：`istio-pilot-*`、`istio-ingressgateway-*`、`istio-egressgateway-*`、`istio-policy-*`、`istio-telemetry-*`、`istio-citadel-*`、`prometheus-*`、`istio-sidecar-injector-*`（可选）。

    ```command
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS      RESTARTS   AGE
    istio-citadel-dcb7955f6-vdcjk              1/1       Running     0          11h
    istio-egressgateway-56b7758b44-l5fm5       1/1       Running     0          11h
    istio-ingressgateway-56cfddbd5b-xbdcx      1/1       Running     0          11h
    istio-pilot-cbd6bfd97-wgw9b                2/2       Running     0          11h
    istio-policy-699fbb45cf-bc44r              2/2       Running     0          11h
    istio-statsd-prom-bridge-949999c4c-nws5j   1/1       Running     0          11h
    istio-telemetry-55b675d8c-kfvvj            2/2       Running     0          11h
    prometheus-86cb6dd77c-5j48h                1/1       Running     0          11h
    ```

## 部署应用

您可以部署自己的应用或者示例应用程序如[BookInfo](/docs/guides/bookinfo/)。
注意：应用程序必须使用HTTP/1.1或HTTP/2.0协议来传递HTTP流量，因为HTTP/1.0已经不再支持。

如果您启动了[Istio-Initializer](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)，如上所示，您可以使用`kubectl create`直接部署应用。Istio-Initializer会向应用程序的Pod中自动注入Envoy容器，如果运行Pod的namespace被标记为`istio-injection=enabled`的话：

```command
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
```

如果您没有安装Istio-initializer-injector的话，您必须使用[istioctl kube-inject](/docs/reference/commands/istioctl/#istioctl-kube-inject)命令在部署应用之前向应用程序的Pod中手动注入Envoy容器：

```command
$ kubectl create -f <(istioctl kube-inject -f <your-app-spec>.yaml)
```

## 卸载

* 卸载Istio核心组件。对于该版本，卸载时将删除RBAC权限、`istio-system` 命名空间和该命名空间的下的各层级资源。

  不必理会在层级删除过程中的各种报错，因为这些资源可能已经被删除的。

如果您使用`istio-demo.yaml`安装的Istio：

```command
$ kubectl delete -f install/kubernetes/istio-demo.yaml
```

否则使用[Helm卸载Istio](/docs/setup/kubernetes/helm-install/#uninstall)。

## 下一步

* 查看[Bookinfo](/docs/guides/bookinfo/)应用程序示例

* 查看如何[验证Istio双向TLS认证](/docs/tasks/security/mutual-tls/)
