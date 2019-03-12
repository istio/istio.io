---
title: 在 Kubernetes 中快速开始
description: 在 Kubernetes 集群中快速安装 Istio 服务网格的说明。
weight: 55
keywords: [kubernetes]
---

依照本文说明，在各种平台的 Kubernetes 集群上快速安装 Istio。这里无需安装 [Helm](https://github.com/helm/helm)，只使用基本的 Kubernetes 命令，就能设置一个预配置的 Istio **demo**。

{{< tip >}}
要正式在生产环境上安装 Istio，我们推荐[使用 Helm 进行安装](/zh/docs/setup/kubernetes/install/helm/)，其中包含了大量选项，可以对 Istio 的具体配置进行选择和管理，来满足特定的使用要求。
{{< /tip >}}

## 前置条件

1. [下载 Istio 发布包](/zh/docs/setup/kubernetes/download/)。

1. [各平台下 Kubernetes 集群的配置](/zh/docs/setup/kubernetes/prepare/platform-setup/):

    * [Minikube](/zh/docs/setup/kubernetes/prepare/platform-setup/minikube/)
    * [Google Container Engine (GKE)](/zh/docs/setup/kubernetes/prepare/platform-setup/gke/)
    * [IBM Cloud](/zh/docs/setup/kubernetes/prepare/platform-setup/ibm/)
    * [OpenShift Origin](/zh/docs/setup/kubernetes/prepare/platform-setup/openshift/)
    * [Amazon Web Services (AWS) with Kops](/zh/docs/setup/kubernetes/prepare/platform-setup/aws/)
    * [Azure](/zh/docs/setup/kubernetes/prepare/platform-setup/azure/)
    * [阿里云](/zh/docs/setup/kubernetes/prepare/platform-setup/alicloud/)
    * [Docker For Desktop](/zh/docs/setup/kubernetes/prepare/platform-setup/docker/)

    {{< tip >}}
    Istio {{< istio_version >}} 已经在下列 Kubernetes 版本上完成测试：{{< supported_kubernetes_versions >}}。
    {{< /tip >}}

1. 复查 [Istio 对 Pod 和服务的要求](/zh/docs/setup/kubernetes/additional-setup/requirements/)。

## 安装步骤

1. 使用 `kubectl apply` 安装 Istio 的[自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，几秒钟之后，CRD 被提交给 Kubernetes 的 API-Server：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 从下列的几个**演示配置**中选择一个进行安装。

{{< tabset cookie-name="profile" >}}

{{% tab name="宽容模式的 mutual TLS" cookie-value="permissive" %}}

如果使用 mutual TLS 的宽容模式，所有的服务会同时允许明文和双向 TLS 的流量。在没有明确[配置客户端进行双向 TLS 通信](/zh/docs/tasks/security/mtls-migration/#配置客户端进行双向-tls-通信)的情况下，客户端会发送明文流量。可以进一步阅读了解[双向 TLS 中的宽容模式](/docs/concepts/security/#permissive-mode)的相关内容。

这种方式的适用场景：

* 已有应用的集群；
* 注入了 Istio sidecar 的服务有和非 Istio Kubernetes 服务通信的需要；
* 需要进行[存活和就绪检测](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)的应用；
* Headless 服务；
* `StatefulSet`。

运行下面的命令即可完成这一模式的安装：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}

{{% /tab %}}

{{% tab name="严格模式的 mutual TLS" cookie-value="strict" %}}
这种方案会在所有的客户端和服务器之间使用
[双向 TLS](/zh/docs/concepts/security/#双向-tls-认证)。

这种方式只适合所有工作负载都受 Istio 管理的 Kubernetes 集群。所有新部署的工作负载都会注入 Istio sidecar。

运行下面的命令可以安装这种方案。

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

{{% /tab %}}

{{< /tabset >}}

## 确认部署结果

1. 确认下列 Kubernetes 服务已经部署并都具有各自的 `CLUSTER-IP`：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                      AGE
    istio-citadel            ClusterIP      172.21.113.238   <none>          8060/TCP,15014/TCP                                                                                                           8d
    istio-egressgateway      ClusterIP      172.21.32.42     <none>          80/TCP,443/TCP,15443/TCP                                                                                                     8d
    istio-galley             ClusterIP      172.21.137.255   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                   8d
    istio-ingressgateway     LoadBalancer   172.21.229.108   158.85.108.37   80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:31324/TCP,15030:31752/TCP,15031:30314/TCP,15032:30953/TCP,15443:30550/TCP   8d
    istio-pilot              ClusterIP      172.21.100.28    <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                       8d
    istio-policy             ClusterIP      172.21.83.199    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                 8d
    istio-sidecar-injector   ClusterIP      172.21.198.98    <none>          443/TCP                                                                                                                      8d
    istio-telemetry          ClusterIP      172.21.84.130    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                       8d
    prometheus               ClusterIP      172.21.140.237   <none>          9090/TCP                                                                                                                     8d
    {{< /text >}}

    {{< tip >}}
    如果你的集群在一个没有外部负载均衡器支持的环境中运行（例如 Minikube），`istio-ingressgateway` 的 `EXTERNAL-IP` 会是 `<pending>`。要访问这个网关，只能通过服务的 `NodePort` 或者使用端口转发来进行访问。
    {{< /tip >}}

1. 确认必要的 Kubernetes Pod 都已经创建并且其 `STATUS` 的值是 `Running`：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                      READY     STATUS      RESTARTS   AGE
    istio-citadel-5c4f467b9c-m8lhb            1/1       Running     0          8d
    istio-cleanup-secrets-1.1.0-rc.0-msbk7    0/1       Completed   0          8d
    istio-egressgateway-fbfb4865d-rv2f4       1/1       Running     0          8d
    istio-galley-7799878d-hnphl               1/1       Running     0          8d
    istio-ingressgateway-7cf9598b9c-s797z     1/1       Running     0          8d
    istio-pilot-698687d96d-76j5m              2/2       Running     0          8d
    istio-policy-55758d8898-sd7b8             2/2       Running     3          8d
    istio-sidecar-injector-5948ffdfc8-wz69v   1/1       Running     0          8d
    istio-telemetry-67d8545b68-wgkmg          2/2       Running     3          8d
    prometheus-c8d8657bf-gwsc7                1/1       Running     0          8d
    {{< /text >}}

## 部署应用

现在就可以部署你自己的应用，或者从 Istio 的发布包中找一个示例应用（例如 [Bookinfo](/zh/docs/examples/bookinfo/)）进行部署了。

{{< warning >}}
这里只支持 HTTP/1.1 或者 HTTP/2.0 协议，不支持 HTTP/1.0。
{{< /warning >}}

在使用 `kubectl apply` 进行应用部署的时候，如果目标命名空间已经打上了标签 `istio-injection=enabled`，[Istio sidecar injector](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入) 会自动把 Envoy 容器注入到你的应用 Pod 之中。

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

如果目标命名空间中没有打上 `istio-injection` 标签，
可以使用
 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令，在部署之前手工把 Envoy 容器注入到应用 Pod 之中：

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## 删除

删除 RBAC 权限、`istio-system` 命名空间及其所有资源。因为有些资源会被级联删除，因此会出现一些无法找到资源的提示，可以忽略。

* 根据启用的 mutual TLS 模式进行删除：

{{< tabset cookie-name="profile" >}}

{{% tab name="宽容模式的 mutual TLS" cookie-value="permissive" %}}

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}

{{% /tab %}}

{{% tab name="严格模式的 mutual TLS" cookie-value="strict" %}}

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

{{% /tab %}}

{{< /tabset >}}

* 也可以根据需要删除 CRD：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}