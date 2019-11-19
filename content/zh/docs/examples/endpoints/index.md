---
title: 安装 Istio 到 Google Cloud Endpoints 服务
description: 介绍如何手动将 Google Cloud Endpoints 服务和 Istio 集成。
weight: 42
aliases:
    - /zh/docs/guides/endpoints/index.html
---

本文档说明了如何手动将 Istio 与现有 Google Cloud Endpoints 服务集成。

## 开始之前{#before-you-begin}

如果您没有 Endpoints 服务，但是想尝试一下，
可以按照该[说明指南](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)在 GKE 上安装 Endpoints 服务。
安装完成后，您应该能获取到 API 密钥，并将其存储在环境变量 `ENDPOINTS_KEY` 和外部 IP 地址 `EXTERNAL_IP` 中。
您可以使用以下命令对服务进行测试：

{{< text bash >}}
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}"
{{< /text >}}

要在 GKE 上安装 Istio，请参考 [Google Kubernetes Engine 快速开始](/zh/docs/setup/platform-setup/gke)

## HTTP Endpoints 服务{#http-endpoints-service}

1. 通过该[说明指南](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)，
使用 `--includeIPRanges` 将服务和 Deployment 注入到网格中，这样 Egress 能够直接调用外部服务。
否则，ESP 将无法访问 Google cloud 服务控件。

1. 注入以后，发出与上述相同的测试命令，以确保 ESP 调用在持续工作。

1.  如果您想通过 Istio ingress 来访问服务，创建以下网络定义：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: echo-gateway
    spec:
      selector:
        istio: ingressgateway # use Istio default gateway implementation
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - "*"
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: echo
    spec:
      hosts:
      - "*"
      gateways:
      - echo-gateway
      http:
      - match:
        - uri:
            prefix: /echo
        route:
        - destination:
            port:
              number: 80
            host: esp-echo
    ---
    EOF
    {{< /text >}}

1.  通过该[说明指南](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)获取 ingress 网关 IP 和端口。
您可以通过 Istio ingress 来验证将要访问到的 Endpoints 服务。

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:${INGRESS_PORT}/echo?key=${ENDPOINTS_KEY}"
    {{< /text >}}

## 使用安全加固的 Ingress 访问 HTTPS Endpoints service{#https-endpoints-service-using-secured-ingress}

安全地访问网格 Endpoints 服务的推荐方式是通过配置了 TLS 的 ingress。

1.  在启用严格双向 TLS 的情况下安装 Istio。确认以下命令的输出结果为 `STRICT` 或为空：

    {{< text bash >}}
    $ kubectl get meshpolicy default -n istio-system -o=jsonpath='{.spec.peers[0].mtls.mode}'
    {{< /text >}}

1.  通过该[说明指南](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)，
使用 `--includeIPRanges` 将服务和 Deployment 重新注入到网格中，这样 Egress 可以直接调用外部服务。
否则，ESP 将无法访问到 Google cloud 服务控件。

1.  然后，您将发现对 `ENDPOINTS_IP` 的访问将不再有效，因为 Istio 的代理只接受安全的网格连接。
通过 Istio ingress 进行的访问应该依然有效，因为在网格里的 ingress 代理会初始化双向 TLS 连接。

1.  要确保 ingress 的访问安全性，请参考[说明指南](/zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/)。
