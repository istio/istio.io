---
title: Kubernetes Service APIs
description: 描述如何使用Istio来配置Kubernetes API服务。
weight: 50
keywords: [traffic-management,ingress]
owner: istio/wg-networking-maintainers
test: yes
---

此任务描述如何使用Kubernetes[Service API](https://kubernetes-sigs.github.io/gateway-api/)配置Istio，将服务暴露到service mesh集群外。这些API是Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/)和[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) API的发展演进。

## 设置 {#setup}

1. 调用Service APIs 创建CRDs:

    {{< text bash >}}
    $ kubectl kustomize "github.com/kubernetes-sigs/service-apis/config/crd?ref=v0.1.0" | kubectl apply -f -
    {{< /text >}}

1. 安装Istio或重新配置Istio，启动Service APIs控制器:

    {{< text bash >}}
    $ istioctl install --set values.pilot.env.PILOT_ENABLED_SERVICE_APIS=true
    {{< /text >}}

1. 请按照 [确定入口网关IP和端口] (/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的说明进行操作，取得入口网关的外部IP地址。

## 配置网关 {#configuring-a-gateway}

参见 [Service APIs](https://kubernetes-sigs.github.io/gateway-api/) 文档中的APIs信息.

1. 部署一个测试应用:

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 部署 Service APIs 配置:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: GatewayClass
    metadata:
      name: istio
    spec:
      controller: istio.io/gateway-controller
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: Gateway
    metadata:
      name: gateway
      namespace: istio-system
    spec:
      gatewayClassName: istio
      listeners:
      - hostname: "*"
        port: 80
        protocol: HTTP
        routes:
          namespaces:
            from: All
          selector:
            matchLabels:
              selected: "yes"
          kind: HTTPRoute
    ---
    apiVersion: networking.x-k8s.io/v1alpha1
    kind: HTTPRoute
    metadata:
      name: http
      namespace: default
      labels:
        selected: "yes"
    spec:
      gateways:
        allow: All
      hostnames: ["httpbin.example.com"]
      rules:
      - matches:
        - path:
            type: Prefix
            value: /get
        filters:
        - type: RequestHeaderModifier
          requestHeaderModifier:
            add:
              my-added-header: added-value
        forwardTo:
        - serviceName: httpbin
          port: 8000
    EOF
    {{< /text >}}

1.  使用 _curl_ 访问刚才部署的 _httpbin_ 服务：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/get"
    HTTP/1.1 200 OK
    server: istio-envoy
    ...
    {{< /text >}}

    请注意，使用 `-H` 标志可以将 _Host_ HTTP标头设置为"httpbin.example.com"。这一步是必需的，因为 `HTTPRoute` 已配置为处理"httpbin.example.com"的请求，但是在测试环境中，该主机没有DNS绑定，只是将请求发送到入口IP。

1.  访问尚未显式公开的任何其他URL，将会收到HTTP 404错误：

    {{< text bash >}}
    $ curl -s -I -HHost:httpbin.example.com "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}
