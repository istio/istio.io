---
title: 在 Google Cloud Endpoints 服务上安装 Istio
description: 如何将 Istio 手动集成至 Google Cloud Endpoints 服务的说明。
weight: 10
aliases:
    - /zh/docs/guides/endpoints/index.html
    - /zh/docs/examples/endpoints/
---

该文档展示了如何将 Istio 手动集成至现成的 Google Cloud Endpoints 服务中。

## 开始之前{#before-you-begin}

如果您还没有 Endpoints 服务并想尝试一下，请按照[这个说明](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)在 GKE 上设置一个 Endpoints 服务。
设置完成后，您会得到一个 API key，将它存为 `ENDPOINTS_KEY` 环境变量，然后将 external IP 地址存为 `EXTERNAL_IP`。
您可以使用以下命令测试该服务：

{{< text bash >}}
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}"
{{< /text >}}

按照[使用 Google Kubernetes Engine 快速开始](/zh/docs/setup/platform-setup/gke)的说明为 GKE 安装 Istio。

## HTTP endpoints 服务{#HTTP-endpoints-service}

1. 按照[这篇说明](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)使用 `--includeIPRanges` 将 service 和 deployment 注入到网格中，以让 Egress 可以直接调用外部服务。
否则，ESP 将无法访问 Google cloud service control。

1. 注入后，使用上面同样的测试命令以确保访问 ESP 依然有效。

1. 如果您希望通过 Istio ingress 访问该服务，请创建如下网络定义：

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

1. 按照[这篇说明](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)获取 ingress 网关的 IP 和端口。
您可以使用以下命令检查一下通过 Istio ingress 访问 Endpoints 服务：

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:${INGRESS_PORT}/echo?key=${ENDPOINTS_KEY}"
    {{< /text >}}

## 使用安全 Ingress 的 HTTPS endpoints 服务{#HTTPS-endpoints-service-using-secured-Ingress}

安全地访问网格 Endpoints 服务的推荐方式是通过一个配置了 TLS 的 ingress。

1. 在启用严格双向 TLS 的情况下安装 Istio。确认下列命令的输出是 `STRICT` 还是空的：

    {{< text bash >}}
    $ kubectl get meshpolicy default -n istio-system -o=jsonpath='{.spec.peers[0].mtls.mode}'
    {{< /text >}}

1. 按照[这篇说明](/zh/docs/tasks/traffic-management/egress/egress-control/#direct-access-to-external-services)使用 `--includeIPRanges` 将 service 和 deployment 注入到网格中，以让 Egress 可以直接调用外部服务。
否则，ESP 将无法访问 Google cloud service control。

1. 然后，您将发现，`ENDPOINTS_IP` 已经无法访问了，因为 Istio 代理只接受安全的网格连接。
通过 Istio ingress 访问依然有效，因为 ingress 代理创建了与网格的双向 TLS 连接。

1. 按照[这篇说明](/zh/docs/tasks/traffic-management/ingress/secure-ingress-mount/)以让 ingress 上的访问更加安全。
