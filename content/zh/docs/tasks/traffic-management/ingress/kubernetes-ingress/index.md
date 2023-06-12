---
title: Kubernetes Ingress
description: 展示如何配置 Kubernetes Ingress 对象，使得从服务网格外部可以访问网格内服务。
weight: 40
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

此任务描述如何使用 [Kubernetes Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/)
为 Istio 配置入口网关以暴露服务网格集群内的服务。

{{< tip >}}
建议使用 [Gateway](/zh/docs/tasks/traffic-management/ingress/ingress-control/)
而不是 Ingress 来利用 Istio 提供的完整功能集，例如丰富的流量管理和安全功能。
{{< /tip >}}

## 准备工作{#before-you-begin}

请按照[入口网关任务](/zh/docs/tasks/traffic-management/ingress/ingress-control/)中的
[准备工作](/zh/docs/tasks/traffic-management/ingress/ingress-control/#before-you-begin)、
[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)的说明进行操作。

## 使用 Ingress 资源配置入口网关 {#configuring-ingress-using-an-ingress-resource}

[Kubernetes Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/)
公开了从集群外到集群内服务的 HTTP 和 HTTPS 路由。

让我们看看如何在端口 80 上配置 `Ingress` 以实现 HTTP 流量。

1.  创建一个 `Ingress` 资源：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      annotations:
        kubernetes.io/ingress.class: istio
      name: ingress
    spec:
      rules:
      - host: httpbin.example.com
        http:
          paths:
          - path: /status
            pathType: Prefix
            backend:
              service:
                name: httpbin
                port:
                  number: 8000
    EOF
    {{< /text >}}

    需要使用 `kubernetes.io/ingress.class` 注解来告知 Istio 网关控制器它应该处理此 `Ingress`，否则它将被忽略。

1.  使用 **curl** 访问 **httpbin** 服务：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    注意，您需要使用 `-H` 标志将 **Host** 的 HTTP 头设置为 "httpbin.example.com"，
    因为 `Ingress` 中已经配置为处理访问 "httpbin.example.com" 的请求，但是在测试环境中，该 host 并没有相应的 DNS 绑定。

1.  访问未显式公开的其他 URL 时，将返回 HTTP 404 错误：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## 下一步{#next-steps}

### TLS {#TLS}

`Ingress` 支持[指定 TLS 设置](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/#tls)。
Istio 支持此功能，但是引用的 `Secret` 必须存在于 `istio-ingressgateway` 部署的命名空间（通常是 `istio-system`）中。
[cert-manager](/zh/docs/ops/integrations/certmanager/) 可用于生成这些证书。

### 指定路径类型{#specifying-path-type}

Istio 默认路径类型为精确匹配，除非路径以 `/*` 或 `.*` 结尾，在这种情况下，路径类型为前缀匹配。不支持其他正则表达式。

在 Kubernetes 1.18 中，添加了一个新字段 `pathType`。这允许将路径明确声明为 `Exact` 或 `Prefix`。

### 指定 `IngressClass` {#specifying-ingress-class}

在 Kubernetes 1.18 中，添加了新资源 `IngressClass`，以替换 Ingress 资源上的 `kubernetes.io/ingress.class` 注解。
如果使用此资源，则需要将 `controller` 字段设置为 `istio.io/ingress-controller`。例如：

{{< text yaml >}}
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress
spec:
  ingressClassName: istio
  rules:
  - host: httpbin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 8000
{{< /text >}}

## 清除{#cleanup}

删除 `Ingress` 配置，然后关闭 [httpbin]({{< github_tree >}}/samples/httpbin) 服务：

{{< text bash >}}
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
