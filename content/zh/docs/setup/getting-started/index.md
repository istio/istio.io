---
title: 开始
description: 下载、安装并学习如何快速使用 Istio 的基本特性。
weight: 5
aliases:
    - /zh/docs/setup/kubernetes/getting-started/
    - /zh/docs/setup/kubernetes/
    - /zh/docs/setup/kubernetes/install/kubernetes/
keywords: [getting-started, install, bookinfo, quick-start, kubernetes]
---

要开始使用 Istio，只需遵循以下三个步骤：

1. [搭建平台](#platform)
1. [下载 Istio](#download)
1. [安装 Istio](#install)

## 搭建平台 {#platform}

在安装 Istio 之前，需要一个运行着 Kubernetes 的兼容版本的 {{< gloss >}}cluster{{< /gloss >}}。

Istio {{< istio_version >}} 已经在 Kubernetes 版本 {{< supported_kubernetes_versions >}} 中测试过。

- 通过选择合适的 [platform-specific setup instructions](/zh/docs/setup/platform-setup/) 来创建一个集群。

有些平台提供了 {{< gloss >}}managed control plane{{< /gloss >}}，您可以使用它来代替手动安装Istio。 如果您选择的平台支持这种方式，并且您选择使用它，那么，在创建完集群后，您将完成 Istio 的安装。因此，可以跳过以下说明。

## 下载 Istio {#download}

下载 Istio，下载内容将包含：安装文件、示例和 [{{< istioctl >}}](/zh/docs/reference/commands/istioctl/) 命令行工具。

1.  访问 [Istio release]({{< istio_release_url >}}) 页面下载与您操作系统对应的安装文件。在 macOS 或 Linux 系统中，也可以通过以下命令下载最新版本的 Istio：

    {{< text bash >}}
    $ curl -L https://istio.io/downloadIstio | sh -
    {{< /text >}}

1.  切换到 Istio 包所在目录下。例如：Istio 包名为 `istio-{{< istio_full_version >}}`，则：

    {{< text bash >}}
    $ cd istio-{{< istio_full_version >}}
    {{< /text >}}

    安装目录包含如下内容：

    - `install/kubernetes` 目录下，有 Kubernetes 相关的 YAML 安装文件
    - `samples/` 目录下，有示例应用程序
    - `bin/` 目录下，包含 [`istioctl`](/zh/docs/reference/commands/istioctl) 的客户端文件。`istioctl` 工具用于手动注入 Envoy sidecar 代理。

1.  将 `istioctl` 客户端路径增加到 path 环境变量中，macOS 或 Linux 系统的增加方式如下：

    {{< text bash >}}
    $ export PATH=$PWD/bin:$PATH
    {{< /text >}}

1. 在使用 bash 或 ZSH 控制台时，可以选择启动 [auto-completion option](/zh/docs/ops/diagnostic-tools/istioctl#enabling-auto-completion)。

## 安装 Istio {#install}

本指南可以让您快速尝鲜 Istio ，这对初学者来说是一个理想的起点。首先，下载并安装 Istio 的内建 `demo` [配置](/zh/docs/setup/additional-setup/config-profiles/)。

本指南让您快速开始认识 Istio。如果您已经熟悉 Istio 或对其他配置内容或更高级的[部署模型](/zh/docs/ops/deployment/deployment-models/)感兴趣，请参考 [使用 {{< istioctl >}} 命令安装](/zh/docs/setup/install/istioctl)。

{{< warning >}}
演示用的配置不适合用于性能评估。它仅用来展示 Istio 的链路追踪和访问记录功能。
{{< /warning >}}

1. 安装 `demo` 配置

    {{< text bash >}}
    $ istioctl manifest apply --set profile=demo
    {{< /text >}}

1. 为了验证是否安装成功，需要先确保以下 Kubernetes 服务正确部署，然后验证除 `jaeger-agent` 服务外的其他服务，是否均有正确的 `CLUSTER-IP`：

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
    如果集群运行在一个不支持外部负载均衡器的环境中（例如：minikube），`istio-ingressgateway` 的 `EXTERNAL-IP` 将显示为 `<pending>` 状态。请使用服务的 `NodePort` 或 端口转发来访问网关。
    {{< /tip >}}

    请确保关联的 Kubernetes pod 已经部署，并且 `STATUS` 为 `Running`：

    {{< text bash >}}
    $ kubectl get pods -n istio-system
    NAME                                                           READY   STATUS      RESTARTS   AGE
    grafana-f8467cc6-rbjlg                                         1/1     Running     0          1m
    istio-citadel-78df5b548f-g5cpw                                 1/1     Running     0          1m
    istio-egressgateway-78569df5c4-zwtb5                           1/1     Running     0          1m
    istio-galley-74d5f764fc-q7nrk                                  1/1     Running     0          1m
    istio-ingressgateway-7ddcfd665c-dmtqz                          1/1     Running     0          1m
    istio-pilot-f479bbf5c-qwr28                                    1/1     Running     0          1m
    istio-policy-6fccc5c868-xhblv                                  1/1     Running     2          1m
    istio-sidecar-injector-78499d85b8-x44m6                        1/1     Running     0          1m
    istio-telemetry-78b96c6cb6-ldm9q                               1/1     Running     2          1m
    istio-tracing-69b5f778b7-s2zvw                                 1/1     Running     0          1m
    kiali-99f7467dc-6rvwp                                          1/1     Running     0          1m
    prometheus-67cdb66cbb-9w2hm                                    1/1     Running     0          1m
    {{< /text >}}

## 后续步骤 {#next-steps}

安装 Istio 后，就可以部署您自己的服务，或部署安装程序中系统的任意一个示例应用。

{{< warning >}}
应用程序必须使用 HTTP/1.1 或 HTTP/2.0 协议用于 HTTP 通信；HTTP/1.0 不支持。
{{< /warning >}}

当使用 `kubectl apply` 来部署应用时，如果 pod 启动在标有 `istio-injection=enabled` 的命名空间中，那么，[Istio sidecar 注入器](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection) 将自动注入 Envoy 容器到应用的 pod 中：

{{< text bash >}}
$ kubectl label namespace <namespace> istio-injection=enabled
$ kubectl create -n <namespace> -f <your-app-spec>.yaml
{{< /text >}}

在没有 `istio-injection` 标记的命名空间中，在部署前可以使用 [`istioctl kube-inject`](/zh/docs/reference/commands/istioctl/#istioctl-kube-inject) 命令将 Envoy 容器手动注入到应用的 pod 中：

{{< text bash >}}
$ istioctl kube-inject -f <your-app-spec>.yaml | kubectl apply -f -
{{< /text >}}

如果您不确定要从哪开始，可以先[部署 Bookinfo 示例](/zh/docs/examples/bookinfo/)，它会让您体验到 Istio 的流量路由、故障注入、速率限制等功能。
然后您可以根据您的兴趣浏览各种各样的[Istio 任务](/zh/docs/tasks/)。

下列任务都是初学者开始学习的好入口：

- [请求路由](/zh/docs/tasks/traffic-management/request-routing/)
- [故障注入](/zh/docs/tasks/traffic-management/fault-injection/)
- [流量转移](/zh/docs/tasks/traffic-management/traffic-shifting/)
- [查询指标](/zh/docs/tasks/observability/metrics/querying-metrics/)
- [可视化指标](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)
- [日志收集](/zh/docs/tasks/observability/logs/collecting-logs/)
- [速率限制](/zh/docs/tasks/policy-enforcement/rate-limiting/)
- [Ingress 网关](/zh/docs/tasks/traffic-management/ingress/ingress-control/)
- [访问外部服务](/zh/docs/tasks/traffic-management/egress/egress-control/)
- [可视化您的网格](/zh/docs/tasks/observability/kiali/)

下一步，可以定制 Istio 并部署您自己的应用。在您开始自定义 Istio 来适配您的平台或者其他用途之前，请查看以下资源：

- [部署模型](/zh/docs/ops/deployment/deployment-models/)
- [部署最佳实践](/zh/docs/ops/best-practices/deployment/)
- [Pod 需求](/zh/docs/ops/deployment/requirements/)
- [常规安装说明](/zh/docs/setup/)

使用 Istio 过程中有任何问题，请来信告知我们，并欢迎您加入我们的 [社区](/zh/about/community/join/)。

## 卸载 {#uninstall}

卸载程序将删除 RBAC 权限、`istio-system` 命名空间和所有相关资源。可以忽略那些不存在的资源的报错，因为它们可能已经被删除掉了。

{{< text bash >}}
$ istioctl manifest generate --set profile=demo | kubectl delete -f -
{{< /text >}}
