---
title: 在 Kubernetes 中快速开始
description: 在 Kubernetes 集群中快速安装 Istio 服务网格的说明。
weight: 5
keywords: [kubernetes]
---

{{< info_icon >}} Istio {{< istio_version >}} 已经在这些 Kubernetes 版本上进行过测试：{{< supported_kubernetes_versions >}}。

依照本文说明，在 Kubernetes 集群中安装和配置 Istio。

## 前置条件

1. [下载 Istio 发布包](/zh/docs/setup/kubernetes/download-release/)。

1. [各平台下 Kubernetes 集群的配置](/zh/docs/setup/kubernetes/platform-setup/):

    * [Minikube](/zh/docs/setup/kubernetes/platform-setup/minikube/)
    * [Google Container Engine (GKE)](/zh/docs/setup/kubernetes/platform-setup/gke/)
    * [IBM Cloud](/zh/docs/setup/kubernetes/platform-setup/ibm/)
    * [OpenShift Origin](/zh/docs/setup/kubernetes/platform-setup/openshift/)
    * [Amazon Web Services (AWS) with Kops](/zh/docs/setup/kubernetes/platform-setup/aws/)
    * [Azure](/zh/docs/setup/kubernetes/platform-setup/azure/)
    * [阿里云](/zh/docs/setup/kubernetes/platform-setup/alicloud/)
    * [Docker For Desktop](/zh/docs/setup/kubernetes/platform-setup/docker-for-desktop/)

1. 复查 [Istio 对 Pod 和服务的要求](/zh/docs/setup/kubernetes/spec-requirements/)。

## 安装步骤

1. 使用 `kubectl apply` 安装 Istio 的[自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，几秒钟之后，CRD 被提交给 kube-apiserver：

    {{< text bash >}}
    $ kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}

1. Istio 核心组件有几种**互斥**的安装方式供用户选择，下面会分别讲述。针对生产环境的需求，为了能够控制所有配置选项，我们建议使用 [Helm Chart](/zh/docs/setup/kubernetes/helm-install/) 方式进行安装。这种方式让运维人员能够根据特定需求对 Istio 进行定制。

### 选项 1：安装 Istio 而不启用 Sidecar 之间的双向 TLS 验证

请浏览
概念章节中的[双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)相关内容以获取更多信息。

这一选项的适用场景：

* 已经部署了应用的集群，
* 已经注入了 Istio sidecar 的服务，需要和 Kubernetes 中的非 Istio 服务进行通信，
* 使用[存活和就绪检查](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/)功能的应用程序，
* Headless 服务或 `StatefulSet`。

用如下命令安装不启用 Sidecar 间双向 TLS 认证的 Istio：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo.yaml
{{< /text >}}

### 选项 2：安装 Istio 并且缺省启用 Sidecar 之间的双向 TLS 认证

这一选项只适用于新安装的 Kubernetes 集群，并且部署其上的工作负载都会必须进行 Istio sidecar 注入。

要安装 Istio 并且缺省启用 Sidecar 之间的双向 TLS 认证：

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

### 选项 3：使用 Helm 渲染 Kubernetes 清单文件并使用 `kubectl` 进行部署

根据相关章节：[通过 Helm 的 `helm template` 安装 Istio](/zh/docs/setup/kubernetes/helm-install/#选项1-通过-helm-的-helm-template-安装-istio)，并跟随其中内容完成安装。

### 选项 4：使用 Helm 和 Tiller 来管理 Istio 部署

阅读相关章节：[通过 Helm 和 Tiller 的 `helm install` 安装 Istio](/zh/docs/setup/kubernetes/helm-install/#选项2-通过-helm-和-tiller-的-helm-install-安装-istio)，并跟随其中内容完成安装。

## 确认部署结果

1. 确认下列 Kubernetes 服务已经部署：`istio-pilot`、`istio-ingressgateway`、`istio-egressgateway`、`istio-policy`、`istio-telemetry`、`prometheus`、`istio-galley` 以及可选的 `istio-sidecar-injector`。

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                                                               AGE
    istio-citadel              ClusterIP      10.47.247.12    <none>            8060/TCP,9093/TCP                                                     7m
    istio-egressgateway        ClusterIP      10.47.243.117   <none>            80/TCP,443/TCP                                                        7m
    istio-galley               ClusterIP      10.47.254.90    <none>            443/TCP                                                               7m
    istio-ingress              LoadBalancer   10.47.244.111   35.194.55.10      80:32000/TCP,443:30814/TCP                                            7m
    istio-ingressgateway       LoadBalancer   10.47.241.20    130.211.167.230   80:31380/TCP,443:31390/TCP,31400:31400/TCP                            7m
    istio-pilot                ClusterIP      10.47.250.56    <none>            15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   7m
    istio-policy               ClusterIP      10.47.245.228   <none>            9091/TCP,15004/TCP,9093/TCP                                           7m
    istio-sidecar-injector     ClusterIP      10.47.245.22    <none>            443/TCP                                                               7m
    istio-statsd-prom-bridge   ClusterIP      10.47.252.184   <none>            9102/TCP,9125/UDP                                                     7m
    istio-telemetry            ClusterIP      10.47.250.107   <none>            9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 7m
    prometheus                 ClusterIP      10.47.253.148   <none>            9090/TCP                                                              7m
    {{< /text >}}

    > 如果该集群在不支持外部负载均衡器的环境中运行（例如 minikube），`istio-ingressgateway` 的 `EXTERNAL-IP` 将会显示为 `<pending>` 状态。这种情况下，只能通过服务的 NodePort，或者使用 port-forwarding 方式来访问服务。

1. 确保所有相应的 Kubernetes pod 都已被部署且所有的容器都已启动并正在运行：`istio-pilot-*`、`istio-ingressgateway-*`、`istio-egressgateway-*`、`istio-policy-*`、`istio-telemetry-*`、`istio-citadel-*`、`prometheus-*`、`istio-galley-*` 以及 `istio-sidecar-injector-*`（可选）。

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                       READY     STATUS        RESTARTS   AGE
    istio-citadel-75c88f897f-zfw8b             1/1       Running       0          1m
    istio-egressgateway-7d8479c7-khjvk         1/1       Running       0          1m
    istio-galley-6c749ff56d-k97n2              1/1       Running       0          1m
    istio-ingress-7f5898d74d-t8wrr             1/1       Running       0          1m
    istio-ingressgateway-7754ff47dc-qkrch      1/1       Running       0          1m
    istio-policy-74df458f5b-jrz9q              2/2       Running       0          1m
    istio-sidecar-injector-645c89bc64-v5n4l    1/1       Running       0          1m
    istio-statsd-prom-bridge-949999c4c-xjz25   1/1       Running       0          1m
    istio-telemetry-676f9b55b-k9nkl            2/2       Running       0          1m
    prometheus-86cb6dd77c-hwvqd                1/1       Running       0          1m
    {{< /text >}}

## 部署应用

上面步骤完成之后，就可以部署自己的应用或者 [Bookinfo](/zh/docs/examples/bookinfo/) 这样的示例应用了。

> 注意：已经不再支持 HTTP/1.0，所以应用程序必须使用 HTTP/1.1 或 HTTP/2.0 协议来传递 HTTP 流量。

如果您启动了 [Istio-sidecar-injector](/zh/docs/setup/kubernetes/sidecar-injection/#sidecar-的自动注入)，就可以使用 `kubectl apply` 直接部署应用。

如果运行 Pod 的 namespace 被标记为 `istio-injection=enabled` 的话，Istio-sidecar-injector 会向应用程序的 Pod 中自动注入 Envoy 容器：

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

如果没有安装 Istio-sidecar-injector 的话，就必须使用 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令在部署应用之前向应用程序的 Pod 中手动注入 Envoy 容器：

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## 卸载 Istio 核心组件

卸载过程要删除 RBAC 权限、`istio-system` 命名空间以及其下的所有资源。删除过程中出现的资源不存在的错误提示可以直接忽略，出现该错误信息的原因是这些资源已经被级联删除。

* 如果使用 `istio-demo.yaml` 进行的安装：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-demo.yaml
    {{< /text >}}

* 如果使用 `istio-demo-auth.yaml` 进行的安装：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/istio-demo-auth.yaml
    {{< /text >}}

* 如果是使用 Helm 安装的 Istio，可以依照[文档中的卸载](/zh/docs/setup/kubernetes/helm-install/#卸载)步骤完成删除。

* 另外如有有需要，也可以删除 CRD：

    {{< text bash >}}
    $ kubectl delete -f install/kubernetes/helm/istio/templates/crds.yaml
    {{< /text >}}
