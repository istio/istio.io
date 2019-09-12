---
title: 在 Kubernetes 中快速开始
description: 在 Kubernetes 集群中快速安装 Istio 服务网格的说明。
weight: 10
keywords: [kubernetes]
---

依照本文说明，在各种平台的 Kubernetes 集群上快速安装 Istio。这里无需安装 [Helm](https://github.com/helm/helm)，只使用基本的 Kubernetes 命令，就能设置一个预[配置](/zh/docs/setup/kubernetes/additional-setup/config-profiles/)的 Istio **demo**。

{{< tip >}}
要正式在生产环境上安装 Istio，我们推荐[使用 Helm 进行安装](/zh/docs/setup/kubernetes/install/helm/)，其中包含了大量选项，可以对 Istio 的具体配置进行选择和管理，来满足特定的使用要求。
{{< /tip >}}

## 前置条件

1. [下载 Istio 发布包](/zh/docs/setup/kubernetes/download/)。

1. [各平台下 Kubernetes 集群的配置](/zh/docs/setup/kubernetes/prepare/platform-setup/):

1. 复查 [Istio 对 Pod 和服务的要求](/zh/docs/setup/kubernetes/additional-setup/requirements/)。

## 安装步骤

1. 使用 `kubectl apply` 安装 Istio 的[自定义资源定义（CRD）](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions)，几秒钟之后，CRD 被提交给 Kubernetes 的 API-Server：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
    {{< /text >}}

1. 从下列的几个**演示配置**中选择一个进行安装。

{{< tabset cookie-name="profile" >}}

{{< tab name="宽容模式的 mutual TLS" cookie-value="permissive" >}}

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

{{< /tab >}}

{{< tab name="严格模式的 mutual TLS" cookie-value="strict" >}}
这种方案会在所有的客户端和服务器之间使用
[双向 TLS](/zh/docs/concepts/security/#双向-tls-认证)。

这种方式只适合所有工作负载都受 Istio 管理的 Kubernetes 集群。所有新部署的工作负载都会注入 Istio sidecar。

运行下面的命令可以安装这种方案。

{{< text bash >}}
$ kubectl apply -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 确认部署结果

1. 确认下列 Kubernetes 服务已经部署并都具有各自的 `CLUSTER-IP`：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                   AGE
    grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP                                                                                                                  2m
    istio-citadel            ClusterIP      172.21.177.222   <none>          8060/TCP,9093/TCP                                                                                                         2m
    istio-egressgateway      ClusterIP      172.21.113.24    <none>          80/TCP,443/TCP                                                                                                            2m
    istio-galley             ClusterIP      172.21.132.247   <none>          443/TCP,9093/TCP                                                                                                          2m
    istio-ingressgateway     LoadBalancer   172.21.144.254   52.116.22.242   80:31380/TCP,443:31390/TCP,31400:31400/TCP,15011:32081/TCP,8060:31695/TCP,853:31235/TCP,15030:32717/TCP,15031:32054/TCP   2m
    istio-pilot              ClusterIP      172.21.105.205   <none>          15010/TCP,15011/TCP,8080/TCP,9093/TCP                                                                                     2m
    istio-policy             ClusterIP      172.21.14.236    <none>          9091/TCP,15004/TCP,9093/TCP                                                                                               2m
    istio-sidecar-injector   ClusterIP      172.21.155.47    <none>          443/TCP                                                                                                                   2m
    istio-telemetry          ClusterIP      172.21.196.79    <none>          9091/TCP,15004/TCP,9093/TCP,42422/TCP                                                                                     2m
    jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                2m
    jaeger-collector         ClusterIP      172.21.135.51    <none>          14267/TCP,14268/TCP                                                                                                       2m
    jaeger-query             ClusterIP      172.21.26.187    <none>          16686/TCP                                                                                                                 2m
    kiali                    ClusterIP      172.21.155.201   <none>          20001/TCP                                                                                                                 2m
    prometheus               ClusterIP      172.21.63.159    <none>          9090/TCP                                                                                                                  2m
    tracing                  ClusterIP      172.21.2.245     <none>          80/TCP                                                                                                                    2m
    zipkin                   ClusterIP      172.21.182.245   <none>          9411/TCP                                                                                                                  2m
    {{< /text >}}

    {{< tip >}}
    如果你的集群在一个没有外部负载均衡器支持的环境中运行（例如 Minikube），`istio-ingressgateway` 的 `EXTERNAL-IP` 会是 `<pending>`。要访问这个网关，只能通过服务的 `NodePort` 或者使用端口转发来进行访问。
    {{< /tip >}}

1. 确认必要的 Kubernetes Pod 都已经创建并且其 `STATUS` 的值是 `Running`：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                                           READY   STATUS      RESTARTS   AGE
    grafana-f8467cc6-rbjlg                                         1/1     Running     0          1m
    istio-citadel-78df5b548f-g5cpw                                 1/1     Running     0          1m
    istio-cleanup-secrets-release-1.1-20190308-09-16-8s2mp         0/1     Completed   0          2m
    istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
    istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
    istio-grafana-post-install-release-1.1-20190308-09-16-2p7m5    0/1     Completed   0          2m
    istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
    istio-pilot-f479bbf5c-qwr28                                    2/2     Running     0          1m
    istio-policy-6fccc5c868-xhblv                                  2/2     Running     2          1m
    istio-security-post-install-release-1.1-20190308-09-16-bmfs4   0/1     Completed   0          2m
    istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
    istio-telemetry-78b96c6cb6-ldm9q                               2/2     Running     2          1m
    istio-tracing-69b5f778b7-s2zvw                                 1/1     Running     0          1m
    kiali-99f7467dc-6rvwp                                          1/1     Running     0          1m
    prometheus-67cdb66cbb-9w2hm                                    1/1     Running     0          1m
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

{{< tab name="宽容模式的 mutual TLS" cookie-value="permissive" >}}

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo.yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="严格模式的 mutual TLS" cookie-value="strict" >}}

{{< text bash >}}
$ kubectl delete -f install/kubernetes/istio-demo-auth.yaml
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* 也可以根据需要删除 CRD：

    {{< text bash >}}
    $ for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
    {{< /text >}}
