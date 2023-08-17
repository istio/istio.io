---
title: Kubernetes Egress 流量服务
description: 展示如何配置 Istio Kubernetes 外部服务。
keywords: [traffic-management,egress]
weight: 60
owner: istio/wg-networking-maintainers
test: yes
---

Kubernetes [ExternalName](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#externalname)
服务和带 [Endpoints](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#services-without-selectors)
的 Kubernetes 服务使您可以创建一个外部服务的本地 DNS 别名。这个 DNS 别名与本地服务的 DNS 条目具有相同的形式，
即 `<service name>.<namespace name>.svc.cluster.local`。DNS 别名为您的工作负载提供“位置透明性”：
工作负载可以以相同的方式调用本地和外部服务。如果您决定在某个时间在集群内部部署外部服务，
您只需更新其 Kubernetes 服务以引用本地版本即可。工作负载将继续运行，而不会有任何变化。

本页内容表明这些访问外部服务的 Kubernetes 机制在 Istio 中依然有效。
您只需配置使用 TLS 模式即可，并不需要 Istio 的[双向 TLS](/zh/docs/concepts/security/#mutual-TLS-authentication)。
因为外部服务不是 Istio 服务网格的一部分，所以它们无法执行 Istio 的双向 TLS。
您在配置 TLS 模式时，一要按照外部服务的 TLS 模式的要求，二要遵从您的工作负载访问外部服务的方式。
当您的工作负载发起的是 HTTP 请求但是外部服务需要 TLS 时，您可以通过 Istio 发起 TLS。
当您的工作负载已经使用 TLS 来加密流量时，您可以禁用 Istio 的双向 TLS。

{{< warning >}}
本页介绍 Istio 如何与现有 Kubernetes 配置集成。对于新部署，
我们建议遵循[访问 Egress 服务](/zh/docs/tasks/traffic-management/egress/egress-control/)。
{{< /warning >}}

虽然本页的示例使用 HTTP 协议，但是用于引导 Egress 流量的 Kubernetes 服务也可以与其他协议一起使用。

{{< boilerplate before-you-begin-egress >}}

*  为没有 Istio 控制的源 Pod 创建一个命名空间：

    {{< text bash >}}
    $ kubectl create namespace without-istio
    {{< /text >}}

*  在命名空间 `without-istio` 中启动 [sleep]({{< github_tree >}}/samples/sleep) 示例。

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

*  要发送请求，可以创建环境变量 `SOURCE_POD_WITHOUT_ISTIO` 来保存源 Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD_WITHOUT_ISTIO="$(kubectl get pod -n without-istio -l app=sleep -o jsonpath={.items..metadata.name})"
    {{< /text >}}

*   验证是否未注入 Istio Sidecar，即 Pod 中有一个容器：

    {{< text bash >}}
    $ kubectl get pod "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio
    NAME                     READY   STATUS    RESTARTS   AGE
    sleep-66c8d79ff5-8tqrl   1/1     Running   0          32s
    {{< /text >}}

## Kubernetes ExternalName 服务访问外部服务{#ks-external-name-service-to-access-an-external-service}

1. 在默认命名空间中，为 `httpbin.org` 创建一个 Kubernetes
   [ExternalName](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#externalname) 服务：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-httpbin
    spec:
      type: ExternalName
      externalName: httpbin.org
      ports:
      - name: http
        protocol: TCP
        port: 80
    EOF
    {{< /text >}}

1. 观察您的服务。注意它没有集群 IP。

    {{< text bash >}}
    $ kubectl get svc my-httpbin
    NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    my-httpbin   ExternalName   <none>       httpbin.org   80/TCP    4s
    {{< /text >}}

1. 从没有 Istio Sidecar 的源 Pod 通过 Kubernetes 服务的主机名访问 `httpbin.org`。注意下面的 **curl** 命令使用
   [Kubernetes DNS 格式用于服务](https://v1-13.docs.kubernetes.io/docs/concepts/services-networking/dns-pod-service/#a-records)：`<service name>.<namespace>.svc.cluster.local`。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.55.0"
      }
    }
    {{< /text >}}

1. 在这个例子中，未加密的 HTTP 请求被发送到 `httpbin.org`。
   仅出于示例目的，您禁用 TLS 模式，并允许外部服务的未加密流量。在现实生活中，我们建议
   由 Istio 执行 [Egress TLS Origination](/zh/docs/tasks/traffic-management/egress/egress-tls-origination)。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: my-httpbin
    spec:
      host: my-httpbin.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1. 通过带有 Istio Sidecar 的源 Pod 通过 Kubernetes 服务的主机名访问 `httpbin.org`。
   注意 Istio Sidecar 添加的 header，例如，`X-Istio-Attributes` 和 `X-Envoy-Decorator-Operation`。
   另请注意 `Host` header 等于您的服务的主机名。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.64.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "5795fab599dca0b8",
        "X-B3-Traceid": "5079ad3a4af418915795fab599dca0b8",
        "X-Envoy-Decorator-Operation": "my-httpbin.default.svc.cluster.local:80/*",
        "X-Envoy-Peer-Metadata": "...",
        "X-Envoy-Peer-Metadata-Id": "sidecar~10.28.1.74~sleep-6bdb595bcb-drr45.default~default.svc.cluster.local"
      }
    }
    {{< /text >}}

### 清理 Kubernetes ExternalName 服务{#cleanup-of-ks-external-name-service}

{{< text bash >}}
$ kubectl delete destinationrule my-httpbin
$ kubectl delete service my-httpbin
{{< /text >}}

## 使用带 endpoints 的 Kubernetes 服务来访问外部服务{#use-a-ks-service-with-endpoints-to-access-an-external-service}

1. 为 Wikipedia 创建没有 selector 的 Kubernetes 服务：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-wikipedia
    spec:
      ports:
      - protocol: TCP
        port: 443
        name: tls
    EOF
    {{< /text >}}

1. 为您的服务创建 endpoints。
   从 [Wikipedia 范围列表](https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses)中选择几个 IP。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Endpoints
    apiVersion: v1
    metadata:
      name: my-wikipedia
    subsets:
      - addresses:
          - ip: 91.198.174.192
          - ip: 198.35.26.96
        ports:
          - port: 443
            name: tls
    EOF
    {{< /text >}}

1. 观察您的服务。请注意，它具有一个集群 IP，您可以使用它访问 `wikipedia.org`。

    {{< text bash >}}
    $ kubectl get svc my-wikipedia
    NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    my-wikipedia   ClusterIP   172.21.156.230   <none>        443/TCP   21h
    {{< /text >}}

1. 从没有 Istio Sidecar 的源 Pod 通过您的 Kubernetes 服务集群 IP 来发送 HTTPS 请求到 `wikipedia.org`。
   使用 `curl` 的 `--resolve` 选项通过集群 IP 访问 `wikipedia.org`：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1. 在这种情况下，工作负载将 HTTPS 请求（开放 TLS 连接）发送到 `wikipedia.org`。
   流量已经通过工作负载加密，因此您可以安全地禁用 Istio 的双向 TLS：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: my-wikipedia
    spec:
      host: my-wikipedia.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1. 使用 Istio Sidecar 从源 Pod 中通过 Kubernetes 服务的集群 IP 访问 `wikipedia.org`：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1. 检查访问是否确实由集群 IP 完成。在 `curl -v` 的输出中注意这句话
   `Connected to en.wikipedia.org (172.21.156.230)`，其中提到了在您的服务输出中作为集群 IP 打印的 IP。

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page -o /dev/null
    * Added en.wikipedia.org:443:172.21.156.230 to DNS cache
    * Hostname en.wikipedia.org was found in DNS cache
    *   Trying 172.21.156.230...
    * TCP_NODELAY set
    * Connected to en.wikipedia.org (172.21.156.230) port 443 (#0)
    ...
    {{< /text >}}

### 清理没有 endpoints 的 Kubernetes 服务{#cleanup-of-ks-service-with-endpoints}

{{< text bash >}}
$ kubectl delete destinationrule my-wikipedia
$ kubectl delete endpoints my-wikipedia
$ kubectl delete service my-wikipedia
{{< /text >}}

## 清理{#cleanup}

1. 停止服务 [sleep]({{< github_tree >}}/samples/sleep)：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1. 停止命名空间 `without-istio` 中的服务 [sleep]({{< github_tree >}}/samples/sleep)：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

1. 删除命名空间 `without-istio`：

    {{< text bash >}}
    $ kubectl delete namespace without-istio
    {{< /text >}}

1. 注销环境变量：

    {{< text bash >}}
    $ unset SOURCE_POD SOURCE_POD_WITHOUT_ISTIO
    {{< /text >}}
