---
title: 在谷歌云 Endpoints 服务中安装 Istio
description: 说明如何在谷歌云 Endpoints 服务中手动整合 Istio。
weight: 42
---

这篇文档展示了如何手动整合 Istio 和现有的谷歌云 Endpoints 服务。

## 开始之前

如果你没有一个端点服务，但是想尝试它，你可以按照这个[指令](https://cloud.google.com/endpoints/docs/openapi/get-started-kubernetes-engine)在 GKE 中创建一个 Endpoints 服务。你可以用下面的命令测试服务。

{{< text bash >}}
$ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${EXTERNAL_IP}:80/echo?key=${ENDPOINTS_KEY}"
{{< /text >}}

在 GKE 中安装 Istio，参考[在 Google Kubernetes Engine 中快速开始](/zh/docs/setup/kubernetes/prepare/platform-setup/gke)。

## HTTP Endpoints 服务

1.  使用 `--includeIPRanges` 将服务注入到网格中，通过该[指令](/zh/docs/tasks/traffic-management/egress/#直接调用外部服务)允许出口直接调用外部服务。否则，ESP 将无法接受谷歌云的控制。

1.  注入后，发出上面提到的测试命令确保调用 ESP 继续工作。

1.  如果你想通过 Ingress 访问服务，以下是创建 Ingress 的定义：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: simple-ingress
      annotations:
        kubernetes.io/ingress.class: istio
    spec:
      rules:
      - http:
          paths:
          - path: /echo
            backend:
              serviceName: esp-echo
              servicePort: 80
    EOF
    {{< /text >}}

1.  通过[指令](/zh/docs/tasks/traffic-management/ingress/#确定入口-ip-和端口)获取 Ingress IP 和端口。你可以通过 Ingress 验证 Endpoints 服务:

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "http://${INGRESS_HOST}:${INGRESS_PORT}/echo?key=${ENDPOINTS_KEY}"i
    {{< /text >}}

## 使用安全的 Ingress HTTPS Endpoints 服务

安全地访问一个网格 Endpoints 服务推荐的方式是通过配置了双向 TLS 认证的 ingress。

1.  在你的网格服务中导出 HTTP 端口。在 ESP 部署参数中添加 `"--http_port=8081"` 导出 HTTP 端口：

    {{< text yaml >}}
    - port: 80
      targetPort: 8081
      protocol: TCP
      name: http
    {{< /text >}}

1.  通过下面的命令在 Istio 中打开 TLS 双向认证：

    {{< text bash >}}
    $ kubectl edit cm istio -n istio-system
    {{< /text >}}

    并且取消注释：

    {{< text yaml >}}
    authPolicy: MUTUAL_TLS
    {{< /text >}}

1. 在此之后，你会发现访问 `EXTERNAL_IP` 不再生效， 因为 Istio 代理仅接受安全网格链接。通过 Ingress 访问有效是因为 Ingress 使 HTTP 终止。

1. 安全访问 Ingress，查看相关[说明](/zh/docs/tasks/traffic-management/secure-ingress/)。

1. 你可以通过安全的 Ingress 访问 Endpoints 服务来验证：

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${INGRESS_HOST}/echo?key=${ENDPOINTS_KEY}" -k
    {{< /text >}}

## 在 HTTPS Endpoints 服务中使用 `LoadBalancer EXTERNAL_IP`

这个方案使用 Istio 代理绕过 TCP。通过 ESP 的流量是安全的。这不是推荐的方法。

1. 将 HTTP port 的名字更新为 `tcp`

    {{< text yaml >}}
    - port: 80
      targetPort: 8081
      protocol: TCP
      name: tcp
    {{< /text >}}

1. 更新网格服务部署。请参阅 [Pods 和 Services 要求](/zh/docs/setup/kubernetes/additional-setup/requirements)中端口命名的规则。

1. 你可以通过安全的 Ingress 访问 Endpoints 服务来验证：

    {{< text bash >}}
    $ curl --request POST --header "content-type:application/json" --data '{"message":"hello world"}' "https://${EXTERNAL_IP}/echo?key=${ENDPOINTS_KEY}" -k
    {{< /text >}}
