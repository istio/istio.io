---
title: 快速开始评估环境安装
description: 在 Kubernetes 集群中安装评估使用的 Istio 的安装指南。
weight: 5
keywords: [kubernetes]
aliases:
    - /docs/setup/kubernetes/quick-start/
    - /docs/setup/kubernetes/install/kubernetes/
---

本指南安装使用 Istio 内置的 `demo` [配置文件](/docs/setup/additional-setup/config-profiles/)。
通过本安装可以让你快速在任意平台的 Kubernetes 集群中使用 Istio 进行评估。

{{< warning >}}
`demo` 的配置方案通过配置高级别的跟踪和访问日志，用于展示 Istio 的功能，不适用于高性能评估使用。
{{< /warning >}}

要正式在生产环境上安装 Istio，我们推荐 [使用 {{< istioctl >}} 安装](/docs/setup/install/istioctl/)，
它提供了更多选项，可以对 Istio 的配置进行选择和管理，满足特定的使用需求。

## 前提条件

1. [下载 Istio 的发布包](/docs/setup/#downloading-the-release)。

1. 执行必须的[平台特定设置](/docs/setup/platform-setup/)。

## 安装 demo 配置

{{< text bash >}}
$ istioctl manifest apply --set profile=demo
{{< /text >}}

## 验证安装结果

1.  确认下面 Kubernetes 服务已经部署且除了 `jaeger-agent` 外都具有合适的 `CLUSTER-IP`：

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    NAME                     TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                                                                                                                                      AGE
    grafana                  ClusterIP      172.21.211.123   <none>          3000/TCP                                                                                                                                     2m
    istio-citadel            ClusterIP      172.21.177.222   <none>          8060/TCP,15014/TCP                                                                                                                           2m
    istio-egressgateway      ClusterIP      172.21.113.24    <none>          80/TCP,443/TCP,15443/TCP                                                                                                                     2m
    istio-galley             ClusterIP      172.21.132.247   <none>          443/TCP,15014/TCP,9901/TCP                                                                                                                   2m
    istio-ingressgateway     LoadBalancer   172.21.144.254   52.116.22.242   15020:31831/TCP,80:31380/TCP,443:31390/TCP,31400:31400/TCP,15029:30318/TCP,15030:32645/TCP,15031:31933/TCP,15032:31188/TCP,15443:30838/TCP   2m
    istio-pilot              ClusterIP      172.21.105.205   <none>          15010/TCP,15011/TCP,8080/TCP,15014/TCP                                                                                                       2m
    istio-policy             ClusterIP      172.21.14.236    <none>          9091/TCP,15004/TCP,15014/TCP                                                                                                                 2m
    istio-sidecar-injector   ClusterIP      172.21.155.47    <none>          443/TCP,15014/TCP                                                                                                                            2m
    istio-telemetry          ClusterIP      172.21.196.79    <none>          9091/TCP,15004/TCP,15014/TCP,42422/TCP                                                                                                       2m
    jaeger-agent             ClusterIP      None             <none>          5775/UDP,6831/UDP,6832/UDP                                                                                                                   2m
    jaeger-collector         ClusterIP      172.21.135.51    <none>          14267/TCP,14268/TCP                                                                                                                          2m
    jaeger-query             ClusterIP      172.21.26.187    <none>          16686/TCP                                                                                                                                    2m
    kiali                    ClusterIP      172.21.155.201   <none>          20001/TCP                                                                                                                                    2m
    prometheus               ClusterIP      172.21.63.159    <none>          9090/TCP                                                                                                                                     2m
    tracing                  ClusterIP      172.21.2.245     <none>          80/TCP                                                                                                                                       2m
    zipkin                   ClusterIP      172.21.182.245   <none>          9411/TCP                                                                                                                                     2m
    {{< /text >}}

    {{< tip >}}
    如果你的集群运行在不支持外部负载均衡器的环境中（例如 minikube），`istio-ingressgateway` 的 `EXTERNAL-IP` 会是 `<pending>`。
    只能使用服务的 `NodePort` 或端口转发访问这个网关。
    {{< /tip >}}

1.  确认 Kubernetes 的 Pod 已经部署并且 `STATUS` 是 `Running`：

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

## 部署你的应用

现在你可以部署你的应用或使用 Istio 的发布包中的示例应用（如 [Bookinfo](/docs/examples/bookinfo/)）进行部署。

{{< warning >}}
部署的应用必须使用 HTTP/1.1 或 HTTP/2.0 协议，Istio 不支持 HTTP/1.0 协议。
{{< /warning >}}

当你使用 `kubectl apply` 部署应用时，如果目标命名空间已经打上了 `istio-injection=enabled` 标签，[Istio sidecar injector](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)
会自动把 Envoy 容器注入到应用 Pod 中：

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

如果目标命名空间没有 `istio-injection` 标签，你可以在部署之前使用 [`istioctl kube-inject`](/docs/reference/commands/istioctl/#istioctl-kube-inject)
命令手动把 Envoy 容器注入到应用 Pod 中：

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

## 卸载

卸载操作会删除 RBAC 权限、`istio-system` 命名空间和其下的所有资源。由于资源可能被级联删除了，所以操作时出现一些资源不存在的提示可以忽略。

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}
