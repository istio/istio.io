---
title: 控制 Egress 流量
description: 在 Istio 中配置从网格内访问外部服务的流量路由。
weight: 40
keywords: [traffic-management,egress]
---

缺省情况下，Istio 服务网格内的 Pod，由于其 iptables 将所有外发流量都透明的转发给了 Sidecar，所以这些集群内的服务无法访问集群之外的 URL，而只能处理集群内部的目标。

本文的任务描述了如何将外部服务暴露给 Istio 集群中的客户端。你将会学到如何通过定义 [`ServiceEntry`](/zh/docs/reference/config/istio.networking.v1alpha3/#serviceentry) 来调用外部服务；或者简单的对 Istio 进行配置，要求其直接放行对特定 IP 范围的访问。

## 开始之前

*   根据[安装指南](/zh/docs/setup)的内容，部署 Istio。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 示例应用，我们将会使用这一应用来完成对外部服务的调用过程。

    如果启用了 [Sidecar 的自动注入功能](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入)，运行：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则在部署 `sleep` 应用之前，就需要手工注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    实际上任何可以 `curl` 的 Pod 都可以用来完成这一任务。
    {{< /tip >}}

*   将 `SOURCE_POD` 环境变量设置为已部署的 `sleep` pod：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Envoy 配置外部服务

Istio 有一个[安装选项](/zh/docs/reference/config/installation-options/) `global.outboundTrafficPolicy.mode`，用于配置外部服务的边车处理，即那些未在Istio内部服务注册中定义的服务。
如果此选项设置为 `ALLOW_ANY`，则 Istio 代理允许调用未知服务。
如果该选项设置为 `REGISTRY_ONLY`，则 Istio 代理会阻止任何没有 HTTP 服务的主机或网格中定义的服务条目。
`ALLOW_ANY` 是默认值，允许您快速开始评估 Istio，而无需控制对外部服务的访问。
然后后面你可以决定[配置对外部服务的访问](#控制外部服务) .

{{< warning >}}
在 Istio 1.1.4 之前的版本中，`ALLOW_ANY` 仅适用于没有在网格中定义的 HTTP 服务或服务条目的端口。
使用与任何内部 HTTP 服务相同的端口的外部主机回退到默认阻止行为。
由于某些端口（例如端口 80 ）默认情况下在 Istio 内部具有 HTTP 服务，因此在 Istio 1.1.3 之前，您无法在任何端口上调用外部服务。
{{< /warning >}}

1. 要查看此方法，您需要确保将 `global.outboundTrafficPolicy.mode` 选项设置为 `ALLOW_ANY` 来配置 Istio 安装。除非您在安装 Istio 时将其明确设置为 `REGISTRY_ONLY` 模式，否则默认情况下可能会启用它。

    运行以下命令以确认配置正确：

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | grep -o "mode: ALLOW_ANY"
    mode: ALLOW_ANY
    {{< /text >}}

    如果启用了 `mode: ALLOW_ANY`，它应出现在输出中。

    {{< tip >}}
    如果已显式配置 `REGISTRY_ONLY` 模式，则可以运行以下命令进行更改：

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: REGISTRY_ONLY/mode: ALLOW_ANY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

    {{< /tip >}}

1.  从 `SOURCE_POD` 向外部 HTTPS 服务发出几个请求以确认成功的 `200` 响应：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

恭喜！您已成功从网格中发送出口流量。

这种访问外部服务的简单方法的缺点是您失去了对外部服务流量的监控和控制;例如，调用外部服务不会出现在 Mixer 日志中。
下一节将向您展示如何监视和控制网格对外部服务的访问。

### 控制外部服务

使用 Istio `ServiceEntry` 配置，您可以从 Istio 集群中访问任何可公开访问的服务。本节介绍如何配置对外部HTTP服务的访问，
[httpbin.org](http://httpbin.org), 以及外部 HTTPS 服务，
[www.google.com](https://www.google.com) 不失去 Istio 的流量监控和控制功能。

### 修改为默认阻止策略

要演示启用对外部服务的访问的受控方式，您需要将 `global.outboundTrafficPolicy.mode` 选项从 `ALLOW_ANY` 模式更改为 `REGISTRY_ONLY` 模式。

{{< tip >}}
您可以添加对已在 `ALLOW_ANY` 模式下可访问的服务的受控访问。
这样，您就可以开始在某些外部服务上使用 Istio 功能而不会阻止任何其他服务。
一旦配置了所有服务，就可以将模式切换为 `REGISTRY_ONLY` 以阻止任何其他无意访问。
{{< /tip >}}

1.  运行以下命令将 `global.outboundTrafficPolicy.mode` 选项改为 `REGISTRY_ONLY`：

    {{< text bash >}}
    $ kubectl get configmap istio -n istio-system -o yaml | sed 's/mode: ALLOW_ANY/mode: REGISTRY_ONLY/g' | kubectl replace -n istio-system -f -
    configmap "istio" replaced
    {{< /text >}}

1.  从 `SOURCE_POD` 向外部 HTTPS 服务发出一些请求，以验证它们现在是否被阻止：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"; kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    (因为缓存)配置更改可能需要一段时间才能应用成功，因此您仍可能获得成功的连接。
    等待几秒钟，然后重试最后一个命令。
    {{< /warning >}}

### 访问外部 HTTP 服务

1. 创建一个 `ServiceEntry` 对象，放行对一个外部 HTTP 服务的访问：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  从 `SOURCE_POD` 向外部 HTTP 服务发出请求：

    {{< text bash >}}
    $  kubectl exec -it $SOURCE_POD -c sleep -- curl http://httpbin.org/headers
    {
      "headers": {
      "Accept": "*/*",
      "Connection": "close",
      "Host": "httpbin.org",
      "User-Agent": "curl/7.60.0",
      ...
      "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
      }
    }
    {{< /text >}}

    注意由 Istio sidecar 代理添加的标题：`X-Envoy-Decorator-Operation`。

1.  检查 `SOURCE_POD` 的 sidecar 代理的日志：

    {{< text bash >}}
    $  kubectl logs $SOURCE_POD -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    请注意与您对 `httpbin.org/headers` 的 HTTP 请求相关的条目。

1.  检查 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'httpbin.org'
    {"level":"info","time":"2019-01-24T12:17:11.855496Z","instance":"accesslog.logentry.istio-system","apiClaims":"","apiKey":"","clientTraceId":"","connection_security_policy":"unknown","destinationApp":"","destinationIp":"I60GXg==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"httpbin.org","destinationWorkload":"unknown","grpcMessage":"","grpcStatus":"","httpAuthority":"httpbin.org","latency":"214.661667ms","method":"GET","permissiveResponseCode":"none","permissiveResponsePolicyID":"none","protocol":"http","receivedBytes":270,"referer":"","reporter":"source","requestId":"17fde8f7-fa62-9b39-8999-302324e6def2","requestSize":0,"requestedServerName":"","responseCode":200,"responseSize":599,"responseTimestamp":"2019-01-24T12:17:11.855521Z","sentBytes":806,"sourceApp":"sleep","sourceIp":"AAAAAAAAAAAAAP//rB5tUg==","sourceName":"sleep-88ddbcfdd-rgk77","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/sleep","sourcePrincipal":"","sourceWorkload":"sleep","url":"/headers","userAgent":"curl/7.60.0","xForwardedFor":"0.0.0.0"}
    {{< /text >}}

    请注意，`destinationServiceHost` 属性等于 `httpbin.org`。 还要注意 HTTP 相关的属性：`method`，`url`，`responseCode` 等。使用 Istio 出口流量控制，您可以监控对外部 HTTP 服务的访问，包括每次访问的 HTTP 相关信息。

### 配置外部 HTTPS 服务

1.  创建一个 `ServiceEntry` 以允许访问外部 HTTPS 服务。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: google
    spec:
      hosts:
      - www.google.com
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  从 `SOURCE_POD` 向外部 HTTPS 服务发出请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -I https://www.google.com | grep  "HTTP/"
    HTTP/2 200
    {{< /text >}}

1.  检查 `SOURCE_POD` 的 sidecar 代理的日志：

    {{< text bash >}}
    $ kubectl logs $SOURCE_POD -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    请注意与您对 `www.google.com` 的 HTTPS 请求相关的条目。

1.  检查 Mixer 日志。如果 Istio 部署在 `istio-system` 命名空间中，则打印日志的命令是：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'www.google.com'
    {"level":"info","time":"2019-01-24T12:48:56.266553Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"1.289085134s","connectionEvent":"close","connection_security_policy":"unknown","destinationApp":"","destinationIp":"rNmhJA==","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"","destinationServiceHost":"www.google.com","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":601,"reporter":"source","requestedServerName":"www.google.com","sentBytes":17766,"sourceApp":"sleep","sourceIp":"rB5tUg==","sourceName":"sleep-88ddbcfdd-rgk77","sourceNamespace":"default","sourceOwner":"kubernetes://apis/apps/v1/namespaces/default/deployments/sleep","sourcePrincipal":"","sourceWorkload":"sleep","totalReceivedBytes":601,"totalSentBytes":17766}
    {{< /text >}}

    请注意，`requestedServerName` 属性等于 `www.google.com`。 使用 Istio 出口流量控制，您可以监控对外部 HTTPS 服务的访问，特别是 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 以及发送和接收的字节数。 请注意，在 HTTPS 中，所有与 HTTP 相关的信息（如方法，URL 路径，响应代码）都已加密，因此 Istio 无法查看，也无法监控 HTTPS 的信息。 如果您需要在访问外部时监视与 HTTP 相关的信息
    HTTPS 服务，您可能希望让您的应用程序发出 HTTP 请求
    [配置 Istio 以执行 TLS](/docs/examples/advanced-gateways/egress-tls-origination/)。

### 管理外部服务的流量

通过 `ServiceEntry` 访问外部服务的流量，和网格内流量类似，都可以进行 Istio [路由规则](/zh/docs/concepts/traffic-management/#规则配置) 的配置。下面我们使用 [`istioctl`](/zh/docs/reference/commands/istioctl/) 为 httpbin.org 服务设置一个超时规则。

1. 在测试 Pod 内部，使用 `curl` 调用 httpbin.org 这一外部服务的 `/delay` 端点：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep sh
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    200

    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    这个请求会在大概五秒钟左右返回一个内容为 `200 (OK)` 的响应。

1.  退出测试 Pod，使用 `kubectl` 为 httpbin.org 外部服务的访问设置一个 3 秒钟的超时：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
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

1.  等待几秒钟之后，再次发起 _curl_ 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep sh
    $ time curl -o /dev/null -s -w "%{http_code}\n" http://httpbin.org/delay/5
    504

    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    这一次会在 3 秒钟之后收到一个内容为 `504 (Gateway Timeout)` 的响应。虽然 httpbin.org 还在等待他的 5 秒钟，Istio 却在 3 秒钟的时候切断了请求。

### 清除对外部服务的受控访问

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

## 直接调用外部服务

如果想要跳过 Istio，直接访问某个 IP 范围内的外部服务，就需要对 Envoy sidecar 进行配置，阻止 Envoy 对外部请求的[劫持](/zh/docs/concepts/traffic-management/#服务之间的通讯)。可以在 [Helm](/zh/docs/reference/config/installation-options/) 中设置 `global.proxy.includeIPRanges` 变量，然后使用 `kubectl apply` 命令来更新名为 `istio-sidecar-injector` 的 `Configmap`。在 `istio-sidecar-injector` 更新之后，`global.proxy.includeIPRanges` 会在所有未来部署的 Pod 中生效。

{{< warning >}}
与[Envoy 配置外部服务](＃Envoy-配置外部服务)不同，它使用 `ALLOW_ANY` 流量策略指示 Istio sidecar 代理通过对未知服务的调用，这种方法完全绕过了 sidecar，基本上禁用指定 IP 的所有 Istio 功能。
您无法使用 `ALLOW_ANY` 方法逐步添加特定目标的服务条目。
因此，此配置方法仅建议作为最后的手段当出于性能或其他原因，无法使用 sidecar 配置外部访问。
{{< /warning >}}

排除所有外部 IP 重定向到 sidecar 代理的一种简单方法是将 `global.proxy.includeIPRanges` 配置选项设置为用于内部集群服务的 IP 范围。这些 IP 范围值取决于群集运行的平台。

### 确定平台的内部 IP 范围

根据集群部署情况为 `global.proxy.includeIPRanges` 赋值。

#### IBM Cloud Private

1.  从 IBM Cloud Private 配置文件（`cluster/config.yaml`）中获取 `service_cluster_ip_range`。

    {{< text bash >}}
    $ cat cluster/config.yaml | grep service_cluster_ip_range
    {{< /text >}}

    会输出类似内容：

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1.  使用 `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

使用 `--set global.proxy.includeIPRanges="172.30.0.0/16\,172.21.0.0/16\,10.10.10.0/24"`

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

#### Minikube, Docker For Desktop, Bare Metal

它没有固定值，但默认值为 10.96.0.0/12 。要确定您的实际值：

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

使用 `--set global.proxy.includeIPRanges="10.96.0.0/12"`

### 配置代理绕过

{{< warning >}}
删除以前在本指南中部署的服务条目和虚拟服务。
{{< /warning >}}

使用特定于您平台的 IP 范围更新 `istio-sidecar-injector` configmap。
例如，如果范围是10.0.0.1/24，请使用以下命令：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> --set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

使用您以前使用的相同 Helm 命令 [install Istio](/docs/setup/kubernetes/install/helm),
特别, 确保为 `--namespace` 标志使用相同的值
添加这些标志： `--set global.proxy.includeIPRanges="10.0.0.1/24" -x templates/sidecar-injector-configmap.yaml`.

### 访问外部服务

由于旁路配置仅影响新部署，因此需要按照[开始之前](#开始之前)部分中的说明重新部署 `sleep` 应用程序。

更新了 `ConfigMap` `istio-sidecar-injector` 并且重新部署了 `sleep` 应用之后，Istio sidecar 就应该只劫持和管理集群内部的请求了。任意的外部请求都会简单的绕过 Sidecar，直接访问目的地址。

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl exec -it $SOURCE_POD -c sleep curl http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Connection": "close",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.60.0"
  }
}
{{< /text >}}

与通过 HTTP 或 HTTPS 访问外部服务不同，您看不到与 Istio sidecar 相关的任何 header ，并且发送到外部服务的请求既不出现在边车的日志中，也不出现在 Mixer 日志中。
绕过 Istio sidecars 意味着您无法再监控对外部服务的访问。

### 清除对外部服务的直接访问

更新 `istio-sidecar-injector.configmap.yaml` configmap 以将所有出站流量重定向到 sidecar 代理：

{{< text bash >}}
$ helm template install/kubernetes/helm/istio <the flags you used to install Istio> -x templates/sidecar-injector-configmap.yaml | kubectl apply -f -
{{< /text >}}

## 理解原理

这个任务中，我们使用两种方式从 Istio 服务网格内部来完成对外部服务的调用：

1. 使用 `ServiceEntry` (推荐方式)

1. 配置 Istio sidecar，从它的重定向 IP 表中排除外部服务的 IP 范围

第一种方式（`ServiceEntry`）中，网格内部的服务不论是访问内部还是外部的服务，都可以使用同样的 Istio 服务网格的特性。我们通过为外部服务访问设置超时规则的例子，来证实了这一优势。

第二种方式越过了 Istio sidecar proxy，让服务直接访问到对应的外部地址。然而要进行这种配置，需要了解云供应商特定的知识和配置。

## Security note

{{< warning >}}
Note that configuration examples in this task **do not enable secure egress traffic control** in Istio.
A malicious application can bypass the Istio sidecar proxy and access any external service without Istio control.
{{< /warning >}}

To implement egress traffic control in a more secure way, you must
[direct egress traffic through an egress gateway](/docs/examples/advanced-gateways/egress-gateway)
and review the security concerns described in the
[additional security considerations](/docs/examples/advanced-gateways/egress-gateway#additional-security-considerations)
section.

## 清理

停止 [sleep]({{< github_tree >}}/samples/sleep) 服务：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
