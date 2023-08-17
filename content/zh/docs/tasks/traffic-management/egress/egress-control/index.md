---
title: 访问外部服务
description: 描述如何配置 Istio 以将流量从网格中的服务路由到外部服务。
weight: 10
aliases:
    - /zh/docs/tasks/egress.html
    - /zh/docs/tasks/egress
keywords: [traffic-management,egress]
owner: istio/wg-networking-maintainers
test: yes
---

由于默认情况下，来自 Istio-enable Pod 的所有出站流量都会重定向到其 Sidecar
代理，集群外部 URL 的可访问性取决于代理的配置。默认情况下，Istio 将 Envoy
代理配置为允许传递未知服务的请求。尽管这为入门 Istio 带来了方便，但是，通常情况下，
配置更严格的控制是更可取的。

这个任务向您展示了三种访问外部服务的方法：

1. 允许 Envoy 代理将请求传递到未在网格内配置过的服务。
1. 配置 [Service Entry](/zh/docs/reference/config/networking/service-entry/) 以提供对外部服务的受控访问。
1. 对于特定范围的 IP，完全绕过 Envoy 代理。

## 开始之前 {#before-you-begin}

*   根据[安装指南](/zh/docs/setup/)中的命令设置 Istio。
    使用 `demo` [安装配置文件](/zh/docs/setup/additional-setup/config-profiles/)或者
    [启用 Envoy 的访问记录](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)。

*   部署 [sleep]({{< github_tree >}}/samples/sleep) 这个示例应用，用作发送请求的测试源。
    如果您启用了[自动注入 Sidecar](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，使用以下的命令来部署示例应用：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，在部署 `sleep` 应用前，使用以下命令手动注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    您可以使用任何安装了 `curl` 的 Pod 作为测试源。
    {{< /tip >}}

*   设置环境变量 `SOURCE_POD`，值为您的源 Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath='{.items..metadata.name}')
    {{< /text >}}

## Envoy 转发流量到外部服务{#envoy-passthrough-to-external-services}

Istio 有一个[安装选项](/zh/docs/reference/config/installation-options/)，
`global.outboundTrafficPolicy.mode`，它配置 Sidecar 对外部服务（那些没有在
Istio 的内部服务注册中定义的服务）的处理方式。如果这个选项设置为 `ALLOW_ANY`，
Istio 代理允许调用未知的服务。如果这个选项设置为 `REGISTRY_ONLY`，那么 Istio
代理会阻止任何没有在网格中定义的 HTTP 服务或 Service Entry 的主机。`ALLOW_ANY`
是默认值，不控制对外部服务的访问，方便您快速地评估 Istio。
您可以稍后再[配置对外部服务的访问](#controlled-access-to-external-services)。

1. 要查看这种方法的实际效果，您需要确保 Istio 的安装配置了 `meshConfig.outboundTrafficPolicy.mode`
   选项为 `ALLOW_ANY`。它在默认情况下是开启的，除非您在安装 Istio 时显式地将它设置为 `REGISTRY_ONLY`。

    运行以下命令以确认 `meshConfig.outboundTrafficPolicy.mode` 设置为 `ALLOW_ANY` 或被省略：

    {{< text bash >}}
    $ kubectl get istiooperator installed-state -n istio-system -o jsonpath='{.spec.meshConfig.outboundTrafficPolicy.mode}'
    ALLOW_ANY
    {{< /text >}}

    您应该看到 `ALLOW_ANY` 或没有任何输出（默认为 `ALLOW_ANY`）。

    {{< tip >}}
    如果您显式地设置了 `REGISTRY_ONLY` 模式，例如，通过使用更改后的设置重新运行原始的
    `istioctl install` 命令：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.outboundTrafficPolicy.mode=ALLOW_ANY
    {{< /text >}}

    {{< /tip >}}

1. 从 `SOURCE_POD` 向外部 HTTPS 服务发出两个请求，确保能够得到状态码为 `200` 的响应：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://edition.cnn.com | grep "HTTP/"
    HTTP/2 200
    HTTP/2 200
    {{< /text >}}

恭喜！您已经成功地从网格中发送了 Egress 流量。

这种访问外部服务的简单方法有一个缺点，即丢失了对外部服务流量的 Istio 监控和控制；
比如，外部服务的调用没有记录到 Mixer 的日志中。下一节将介绍如何监控和控制网格对外部服务的访问。

## 控制对外部服务的访问 {#controlled-access-to-external-services}

使用 Istio `ServiceEntry` 配置，您可以从 Istio 集群中访问任何公开的服务。
本节将向您展示如何在不丢失 Istio 的流量监控和控制特性的情况下，配置对外部 HTTP
服务（[httpbin.org](http://httpbin.org)）和外部 HTTPS 服务（[www.google.com](https://www.google.com)）
的访问。

### 更改为默认的封锁策略 {#change-to-the-blocking-by-default-policy}

为了演示如何控制对外部服务的访问，您需要将 `global.outboundTrafficPolicy.mode`
选项，从 `ALLOW_ANY` 模式改为 `REGISTRY_ONLY` 模式。

{{< tip >}}
您可以向已经在 `ALLOW_ANY` 模式下的可访问服务添加访问控制。
通过这种方式，您可以在一些外部服务上使用 Istio 的特性，而不会阻止其他服务。
一旦您配置了所有服务，就可以将模式切换到 `REGISTRY_ONLY` 来阻止任何其他无意的访问。
{{< /tip >}}

1. 执行以下命令来将 `global.outboundTrafficPolicy.mode` 选项改为 `REGISTRY_ONLY`：

    如果您使用 `IstioOperator` CR 安装 Istio，请在配置中添加以下字段：

    {{< text yaml >}}
    spec:
      meshConfig:
        outboundTrafficPolicy:
          mode: REGISTRY_ONLY
    {{< /text >}}

    否则，将等效设置添加到原始 `istioctl install` 命令中，例如：

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
    {{< /text >}}

1. 从 `SOURCE_POD` 向外部 HTTPS 服务发出几个请求，验证它们现在是否被阻止：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://www.google.com | grep  "HTTP/"; kubectl exec "$SOURCE_POD" -c sleep -- curl -sI https://edition.cnn.com | grep "HTTP/"
    command terminated with exit code 35
    command terminated with exit code 35
    {{< /text >}}

    {{< warning >}}
    配置更改后肯定需要一小段时间才能生效，所以您可能仍然可以得到成功的响应。等待若干秒后再重新执行上面的命令。
    {{< /warning >}}

### 访问一个外部的 HTTP 服务 {#access-an-external-http-service}

1. 创建一个 `ServiceEntry`，以允许访问一个外部的 HTTP 服务：

    {{< warning >}}
    `DNS` 解析在下面的服务条目中用作安全措施。将解析设置为 `NONE` 会出现受到攻击的可能。
    恶意客户端在真正连接到其他 IP 时，可能会伪装设置 `HOST` 头信息为 `httpbin.org`
   （与 `httpbin.org` 不相关）。Istio Sidecar 代理将信任 HOST 头信息，并错误地允许通信，
    甚至将其传递到其他主机的 IP 地址。

    该主机可能是恶意的站点，或者网格安全策略禁止的站点。

    使用 `DNS` 解析，Sidecar 代理将忽略原始目标 IP 地址并引导流量到 `httpbin.org`，
    并执行 DNS 查询以获取 `httpbin.org` 的 IP 地址。
    {{< /warning >}}

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

1. 从 `SOURCE_POD` 向外部的 HTTP 服务发出一个请求：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS http://httpbin.org/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin.org",
        ...
        "X-Envoy-Decorator-Operation": "httpbin.org:80/*",
        ...
      }
    }
    {{< /text >}}

    注意由 Istio Sidecar 代理添加的头信息：`X-Envoy-Decorator-Operation`。

1. 检查 `SOURCE_POD` 的 Sidecar 代理的日志：

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:17:11.640Z] "GET /headers HTTP/1.1" 200 - 0 599 214 214 "-" "curl/7.60.0" "17fde8f7-fa62-9b39-8999-302324e6def2" "httpbin.org" "35.173.6.94:80" outbound|80||httpbin.org - 35.173.6.94:80 172.30.109.82:55314 -
    {{< /text >}}

    注意与 HTTP 请求相关的 `httpbin.org/headers`。

### 访问外部 HTTPS 服务 {#access-an-external-https-service}

1. 创建一个 `ServiceEntry`，允许对外部服务的访问。

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

1. 从 `SOURCE_POD` 往外部 HTTPS 服务发送请求：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sSI https://www.google.com | grep  "HTTP/"
    HTTP/2 200
    {{< /text >}}

1. 检查 `SOURCE_POD` 的 Sidecar 代理的日志：

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy | tail
    [2019-01-24T12:48:54.977Z] "- - -" 0 - 601 17766 1289 - "-" "-" "-" "-" "172.217.161.36:443" outbound|443||www.google.com 172.30.109.82:59480 172.217.161.36:443 172.30.109.82:59478 www.google.com
    {{< /text >}}

    请注意与您对 `www.google.com` 的 HTTPS 请求相关的条目。

### 管理到外部服务的流量 {#manage-traffic-to-external-services}

与集群内的请求相似，也可以为使用 `ServiceEntry` 配置访问的外部服务设置
[Istio 路由规则](/zh/docs/concepts/traffic-management/#routing-rules)。
在本示例中，您将设置对 `httpbin.org` 服务访问的超时规则。

1. 从用作测试源的 Pod 内部，向外部服务 `httpbin.org` 的 `/delay`
   endpoint 发出 **curl** 请求：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    200
    real    0m5.024s
    user    0m0.003s
    sys     0m0.003s
    {{< /text >}}

    这个请求大约在 5 秒内返回 200 (OK)。

1. 退出测试源 Pod，使用 `kubectl` 设置调用外部服务 `httpbin.org` 的超时时间为 3 秒。

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

1. 几秒后，重新发出 **curl** 请求：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- time curl -o /dev/null -sS -w "%{http_code}\n" http://httpbin.org/delay/5
    504
    real    0m3.149s
    user    0m0.004s
    sys     0m0.004s
    {{< /text >}}

    这一次，在 3 秒后出现了 504 (Gateway Timeout)。Istio 在 3 秒后切断了响应时间为
    5 秒的 `httpbin.org` 服务。

### 清理对外部服务的受控访问 {#cleanup-the-controlled-access-to-external-services}

{{< text bash >}}
$ kubectl delete serviceentry httpbin-ext google
$ kubectl delete virtualservice httpbin-ext --ignore-not-found=true
{{< /text >}}

## 直接访问外部服务 {#direct-access-to-external-services}

如果要让特定范围的 ​​IP 完全绕过 Istio，则可以配置 Envoy Sidecar
以防止它们[拦截](/zh/docs/concepts/traffic-management/)外部请求。要设置绕过
Istio，请更改 `global.proxy.includeIPRanges` 或 `global.proxy.excludeIPRanges`
[配置参数](https://archive.istio.io/v1.4/docs/reference/config/installation-options/)，
并使用 `kubectl apply` 命令更新 `istio-sidecar-injector` 配置。
也可以通过设置相应的[注解](/zh/docs/reference/config/annotations/)）在 Pod 上进行配置，
例如 `traffic.sidecar.istio.io / includeOutboundIPRanges`。`istio-sidecar-injector`
配置的更新，影响的是新部署应用的 Pod。

{{< warning >}}
与 [Envoy 转发流量到外部服务](#envoy-passthrough-to-external-services)不同，
后者使用 `ALLOW_ANY` 流量策略来让 Istio Sidecar 代理将调用传递给未知服务，
该方法完全绕过了 Sidecar，从而实质上禁用了指定 IP 的所有 Istio 功能。您不能像
`ALLOW_ANY` 方法那样为特定的目标增量添加 Service Entry。
因此，仅当出于性能或其他原因无法使用边车配置外部访问时，才建议使用此配置方法。
{{< /warning >}}

排除所有外部 IP 重定向到 Sidecar 代理的一种简单方法是将 `global.proxy.includeIPRanges`
配置选项设置为内部集群服务使用的 IP 范围。这些 IP 范围值取决于集群所在的平台。

### 确定平台内部的 IP 范围 {#determine-the-internal-IP-ranges-for-your-platform}

根据您的集群的提供者，设置参数 `global.proxy.includeIPRanges`。

#### IBM Cloud Private

1. 从 `IBM Cloud Private` 的配置文件 `cluster/config.yaml` 中获取您的
   `service_cluster_ip_range`：

    {{< text bash >}}
    $ grep service_cluster_ip_range cluster/config.yaml
    {{< /text >}}

    以下是输出示例：

    {{< text plain >}}
    service_cluster_ip_range: 10.0.0.1/24
    {{< /text >}}

1. 使用 `--set global.proxy.includeIPRanges="10.0.0.1/24"`

#### IBM Cloud Kubernetes Service

若要查看集群中使用了哪个 CIDR，可以使用 `ibmcloud ks cluster get -c <CLUSTER-NAME>` 并查看 `Service Subnet`：

{{< text bash >}}
$ ibmcloud ks cluster get -c my-cluster | grep "Service Subnet"
Service Subnet:                 172.21.0.0/16
{{< /text >}}

然后使用 `--set values.global.proxy.includeIPRanges="172.21.0.0/16"`

{{< warning >}}
在非常旧的集群上，这可能无法正常工作，因此您可以使用
`--set values.global.proxy.includeIPRanges="172.30.0.0/16,172.21.0.0/16,10.10.10.0/24"`
或使用 `kubectl get svc -o wide -A` 进一步缩小设置的 CIDR 值。
{{< /warning >}}

#### Google Kubernetes Engine (GKE)

范围是不固定的，您需要运行 `gcloud container clusters describe` 命令来确定要使用的范围。
举个例子：

{{< text bash >}}
$ gcloud container clusters describe XXXXXXX --zone=XXXXXX | grep -e clusterIpv4Cidr -e servicesIpv4Cidr
clusterIpv4Cidr: 10.4.0.0/14
servicesIpv4Cidr: 10.7.240.0/20
{{< /text >}}

使用 `--set global.proxy.includeIPRanges="10.4.0.0/14\,10.7.240.0/20"`

#### Azure Container Service(ACS)

使用 `--set global.proxy.includeIPRanges="10.244.0.0/16\,10.240.0.0/16`

#### Minikube, Docker For Desktop, Bare Metal

默认值为 `10.96.0.0/12`，但不是固定的。使用以下命令确定您的实际值：

{{< text bash >}}
$ kubectl describe pod kube-apiserver -n kube-system | grep 'service-cluster-ip-range'
      --service-cluster-ip-range=10.96.0.0/12
{{< /text >}}

使用 `--set global.proxy.includeIPRanges="10.96.0.0/12"`

### 配置代理绕行 {#configuring-the-proxy-bypass}

{{< warning >}}
删除本指南中先前部署的 Service Entry 和 Virtual Service。
{{< /warning >}}

使用平台的 IP 范围更新 `istio-sidecar-injector` 的配置。比如，如果 IP 范围是
10.0.0.1&#47;24，则使用一下命令：

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set values.global.proxy.includeIPRanges="10.0.0.1/24"
{{< /text >}}

在[安装 Istio](/zh/docs/setup/install/istioctl) 命令的基础上增加
`--set values.global.proxy.includeIPRanges="10.0.0.1/24"`。

### 访问外部服务 {#access-the-external-services}

由于绕行配置仅影响新的部署，因此您需要按照[开始之前](#before-you-begin)部分中的说明重新部署 `sleep` 程序。

在更新 `istio-sidecar-injector` configmap 和重新部署 `sleep` 程序后，
Istio Sidecar 将仅拦截和管理集群中的内部请求。任何外部请求都会绕过 Sidecar，
并直接到达其预期的目的地。举个例子：

{{< text bash >}}
$ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS http://httpbin.org/headers
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    ...
  }
}
{{< /text >}}

与通过 HTTP 和 HTTPS 访问外部服务不同，您不会看到任何与 Istio Sidecar 有关的请求头，
并且发送到外部服务的请求既不会出现在 Sidecar 的日志中，也不会出现在 Mixer 日志中。
绕过 Istio Sidecar 意味着您不能再监视对外部服务的访问。

### 清除对外部服务的直接访问 {#cleanup-the-direct-access-to-external-services}

更新配置，以针对各种 IP 停止绕过 Sidecar 代理：

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio>
{{< /text >}}

## 理解原理 {#understanding-what-happened}

在此任务中，您研究了从 Istio 网格调用外部服务的三种方法：

1. 配置 Envoy 以允许访问任何外部服务。

1. 使用 Service Entry 将一个可访问的外部服务注册到网格中。这是推荐的方法。

1. 配置 Istio Sidecar 以从其重新映射的 IP 表中排除外部 IP。

第一种方法通过 Istio Sidecar 代理来引导流量，包括对网格内部未知服务的调用。使用这种方法时，
您将无法监控对外部服务的访问或无法利用 Istio 的流量控制功能。
要轻松为特定的服务切换到第二种方法，只需为那些外部服务创建 Service Entry 即可。
此过程使您可以先访问任何外部服务，然后再根据需要决定是否启用控制访问、流量监控、流量控制等功能。

第二种方法可以让您使用 Istio 服务网格所有的功能区调用集群内或集群外的服务。
在此任务中，您学习了如何监控对外部服务的访问并设置对外部服务的调用的超时规则。

第三种方法绕过了 Istio Sidecar 代理，使您的服务可以直接访问任意的外部服务。
但是，以这种方式配置代理需要了解集群提供商相关知识和配置。
与第一种方法类似，您也将失去对外部服务访问的监控，并且无法将 Istio 功能应用于外部服务的流量。

## 安全说明 {#security-note}

{{< warning >}}
请注意，此任务中的配置示例**没有启用安全的出口流量控制**。
恶意程序可以绕过 Istio Sidecar 代理并在没有 Istio 控制的情况下访问任何外部服务。
{{< /warning >}}

为了以更安全的方式实施出口流量控制，您必须[通过 Egress Gateway 引导出口流量](/zh/docs/tasks/traffic-management/egress/egress-gateway/)，
并查看[其他安全注意事项](/zh/docs/tasks/traffic-management/egress/egress-gateway/#additional-security-considerations)部分中描述的安全问题。

## 清理 {#cleanup}

关闭服务 [sleep]({{< github_tree >}}/samples/sleep)：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
