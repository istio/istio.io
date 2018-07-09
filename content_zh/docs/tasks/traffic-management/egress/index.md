---
title: 控制 Egress 流量
description: 在 Istio 中配置从网格内访问外部服务的流量路由。
weight: 40
keywords: [traffic-management,egress]
---

> 这一任务使用的是新的 [v1alpha3 流量管理 API](/blog/2018/v1alpha3-routing/)。旧版本的 API 已经过时，会在 Istio 的下一个版本中弃用。如果需要使用旧版本，请阅读[旧版文档](https://archive.istio.io/v0.7/docs/tasks/traffic-management/)。

缺省情况下，Istio 服务网格内的 Pod，由于其 iptables 将所有外发流量都透明的转发给了 Sidecar，所以这些集群内的服务无法访问集群之外的 URL，而只能处理集群内部的目标。

本文的任务描述了如何将外部服务暴露给 Istio 集群中的客户端。你将会学到如何通过定义 [ServiceEntry](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) 来调用外部服务；或者简单的对 Istio 进行配置，要求其直接放行对特定 IP 范围的访问。

## 开始之前

* 根据[安装指南](/docs/setup)的内容，部署 Istio。

* 启动  [sleep]({{< github_tree >}}/samples/sleep) 示例应用，我们将会使用这一应用来完成对外部服务的调用过程。
    如果启用了 [Sidecar 的自动注入功能](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)，运行：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则在部署 `sleep` 应用之前，就需要手工注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    实际上任何可以 `exec` 和 `curl` 的 Pod 都可以用来完成这一任务。

## Istio 中配置外部服务

通过配置 Istio `ServiceEntry`，可以从 Istio 集群中访问外部任意的可用服务。这里我们会使用 [httpbin.org](http://httpbin.org) 以及 [www.google.com](https://www.google.com) 进行试验。

### 配置外部服务

1. 创建一个 `ServiceEntry` 对象，放行对一个外部 HTTP 服务的访问：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
    EOF
    {{< /text >}}

1. 另外创建一个 `ServiceEntry` 对象，允许访问对一个外部 HTTPS 服务的访问：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: google-ext
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
    EOF
    {{< /text >}}

### 发起对外部服务的访问

1. 使用 `kubectl exec` 命令进入测试 Pod。假设使用的是 sleep 服务，运行如下命令：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    {{< /text >}}

1. 发起一个对外部 HTTP 服务的请求：

    {{< text bash >}}
    $ curl http://httpbin.org/headers
    {{< /text >}}

1. 发起一个对外部 HTTPS 服务的请求：

    {{< text bash >}}
    $ curl https://www.google.com
    {{< /text >}}

### 为外部服务设置路由规则

通过 `ServiceEntry` 访问外部服务的流量，和网格内流量类似，都可以进行 Istio [路由规则](/docs/concepts/traffic-management/#rule-configuration) 的配置。下面我们使用 [istioctl](/docs/reference/commands/istioctl/) 为 httpbin.org 服务设置一个超时规则。

1. 在测试 Pod 内部，调用 httpbin.org 这一外部服务的 `/delay` 端点：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    200

    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    这个请求会在大概五秒钟左右返回一个内容为 `200 (OK)` 的响应。

1. 退出测试 Pod，使用 `istioctl` 为 httpbin.org 外部服务的访问设置一个 3 秒钟的超时：

    {{< text bash >}}
    $ cat <<EOF | istioctl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin-ext
    spec:
      hosts:
        - httpbin.org
      http:
      - timeout: 3s
        route:
          - destination:
              host: httpbin.org
            weight: 100
    EOF
    {{< /text >}}

1. 等待几秒钟之后，再次发起 `curl` 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep bash
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    504

    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    这一次会在 3 秒钟之后收到一个内容为 `504 (Gateway Timeout)` 的响应。虽然 httpbin.org 还在等待他的 5 秒钟，Istio 却在 3 秒钟的时候切断了请求。

## 直接调用外部服务

如果想要跳过 Istio，直接访问某个 IP 范围内的外部服务，就需要对 Envoy sidecar 进行配置，阻止 Envoy 对外部请求的[劫持](/docs/concepts/traffic-management/#communication-between-services)。可以在 [Helm](/docs/setup/kubernetes/helm-install/#customization-with-helm) 中设置 `global.proxy.includeIPRanges` 变量，然后使用 `kubectl apply` 命令来更新名为 `istio-sidecar-injector` 的 `Configmap`。在 `istio-sidecar-injector` 更新之后，`global.proxy.includeIPRanges` 会在所有未来部署的 Pod 中生效。

使用 `global.proxy.includeIPRanges` 变量的最简单方式就是把内部服务的 IP 地址范围传递给它，这样就在 Sidecar proxy 的重定向列表中排除掉了外部服务的地址了。

内部服务的 IP 范围取决于集群的部署情况。例如 Minikube 中这一范围是 `10.0.0.1/24`，这个配置中，就应该这样更新 `istio-sidecar-injector`：

{{< text bash >}}
$ helm template @install/kubernetes/helm/istio@ <安装 Istio 时所使用的参数> --set global.proxy.includeIPRanges="10.0.0.1/24" -x @templates/sidecar-injector-configmap.yaml@ | kubectl apply -f -
{{< /text >}}

注意这里应该使用和之前部署 Istio 的时候同样的 [Helm 命令](/docs/setup/kubernetes/helm-install)，尤其是 `--namespace` 参数。在安装 Istio 原有命令的基础之上，加入 `--set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml` 即可。

[和前面一样](/docs/tasks/traffic-management/egress/#before-you-begin)，重新部署 `sleep` 应用。

### 确定 `global.proxy.includeIPRanges` 的值

根据集群部署情况为 `global.proxy.includeIPRanges` 赋值。

#### IBM Cloud Private

1. 从 IBM Cloud Private 配置文件（`cluster/config.yaml`）中获取 `service_cluster_ip_range`。

    {{< text bash >}}
    $ cat cluster/config.yaml | grep service_cluster_ip_range
    {{< /text >}}

    会输出类似内容：

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1. 使用 `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

使用 `--set global.proxy.includeIPRanges="172.30.0.0/16\,172.20.0.0/16\,10.10.10.0/24"`

#### Google Container Engine (GKE)

这个范围是不确定的，所以需要运行 `gcloud container clusters describe` 命令来获取范围的具体定义，例如：

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

使用 `--set global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Container Service(ACS)

使用 `--set global.proxy.includeIPRanges="10.244.0.0/16\,10.240.0.0/16`

#### Minikube

使用 `--set global.proxy.includeIPRanges="10.0.0.1/24"`

### 访问外部服务

更新了 `ConfigMap` `istio-sidecar-injector` 并且重新部署了 `sleep` 应用之后，Istio sidecar 就应该只劫持和管理集群内部的请求了。任意的外部请求都会简单的绕过 Sidecar，直接访问目的地址。

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
{{< /text >}}

## 总结

这个任务中，我们使用两种方式从 Istio 服务网格内部来完成对外部服务的调用：

1. 使用 `ServiceEntry` (推荐方式)

1. 配置 Istio sidecar，从它的重定向 IP 表中排除外部服务的 IP 范围

第一种方式（`ServiceEntry`）中，网格内部的服务不论是访问内部还是外部的服务，都可以使用同样的 Istio 服务网格的特性。我们通过为外部服务访问设置超时规则的例子，来证实了这一优势。

第二种方式越过了 Istio sidecar proxy，让服务直接访问到对应的外部地址。然而要进行这种配置，需要了解云供应商特定的知识和配置。

## 清理

1. 删除规则：

    {{< text bash >}}
    $ istioctl delete serviceentry httpbin-ext google-ext
    $ istioctl delete virtualservice httpbin-ext
    {{< /text >}}

1. 停止 [sleep]({{< github_tree >}}/samples/sleep) 服务：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 更新 `ConfigMap` `istio-sidecar-injector`，要求 Sidecar 转发所有外发流量：

    {{< text bash >}}
    $ helm template @install/kubernetes/helm/istio@ <安装 Istio 时所使用的参数> -x @templates/sidecar-injector-configmap.yaml@ | kubectl apply -f -
    {{< /text >}}