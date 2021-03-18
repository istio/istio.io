---
title: Kubernetes Ingress
description: 展示如何配置Kubernetes Ingress对象，使得从服务网格外部可以访问网格内服务。
weight: 40
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---
此任务描述如何使用[Ingress Resource](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/)入口资源将Istio配置为在服务网格集群之外公开服务。

{{< tip >}}
建议使用[Istio Gateway](/zh/docs/tasks/traffic-management/ingress/ingress-control/)而不是Ingress来利用Istio提供的完整功能集，例如丰富的流量管理和安全功能。
{{< /tip >}}

## 准备工作{#before-you-begin}

请按照[Ingress网关任务](/zh/docs/tasks/traffic-management/ingress/ingress-control/)中的[准备工作](/zh/docs/tasks/traffic-management/ingress/ingress-control/#before-you-begin)、[确定Ingress IP和Ports](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)的说明进行操作。

## 使用Ingress resource配置ingress{#configuring-ingress-using-an-ingress-resource}

[Kubernetes Ingress 资源](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/)公开了从集群外到集群内服务的HTTP和HTTPS路由。

让我们看看如何在端口80上配置`Ingress`以实现HTTP流量。

1.  创建一个 `Ingress` 资源:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.k8s.io/v1beta1
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
          - path: /status/*
            backend:
              serviceName: httpbin
              servicePort: 8000
    EOF
    {{< /text >}}

    需要使用 `kubernetes.io/ingress.class` 注解来告知Istio网关控制器它应该处理此 `Ingress` ，否则它将被忽略。

1.  使用 _curl_ 访问 _httpbin_ 服务:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/status/200"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    注意，您需要使用 `-H` 标志将 _Host_ 的 HTTP header设置为"httpbin.example.com"，因为 `Ingress` 中已经配置为处理访问 "httpbin.example.com"的请求，但是在测试环境中，该host并没有相应的DNS绑定。

1.  访问未显式公开的其他URL时，将返回HTTP 404错误:

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## 下一步{#next-steps}

### TLS {#TLS}

`Ingress` 支持[TLS](https://kubernetes.io/zh/docs/concepts/services-networking/ingress/#tls)设置。 Istio支持此功能，但是引用的 `Secret` 必须存在于`istio-ingressgateway` 部署的名称空间（通常是 `istio-system` ）中。 [cert-manager](/zh/docs/ops/integrations/certmanager/)可用于生成这些证书。

### 指定路径类型{#specifying-path-type}

Istio默认路径类型为精确匹配，除非路径以 `/*` 或 `.*` 结尾，在这种情况下，路径类型为前缀匹配。不支持其他正则表达式。

在Kubernetes 1.18中，添加了一个新字段 `pathType` 。这允许将路径明确声明为`Exact` 或 `Prefix`。

### 指定 `IngressClass` {#specifying-ingress-class}

在Kubernetes 1.18中，添加了新资源 `IngressClass` ，以替换Ingress资源上的`kubernetes.io/ingress.class`注解。如果使用此资源，则需要将 `controller` 字段设置为 `istio.io/ingress-controller`。例如：

{{< text yaml >}}
apiVersion: networking.k8s.io/v1beta1
kind: IngressClass
metadata:
  name: istio
spec:
  controller: istio.io/ingress-controller
---
apiVersion: networking.k8s.io/v1beta1
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
          serviceName: httpbin
          servicePort: 8000
{{< /text >}}

## 清除{#cleanup}

删除 `Ingress` 配置，然后关闭 [httpbin]({{< github_tree >}}/samples/httpbin)服务：

{{< text bash >}}
$ kubectl delete ingress ingress
$ kubectl delete --ignore-not-found=true -f @samples/httpbin/httpbin.yaml@
{{< /text >}}
