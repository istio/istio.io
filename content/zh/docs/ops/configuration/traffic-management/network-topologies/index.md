---
title: 配置 Gateway 网络拓扑
description: 如何配置 Gateway 网络拓扑。
weight: 60
keywords: [traffic-management,ingress,gateway]
owner: istio/wg-networking-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

{{< boilerplate gateway-api-support >}}

## 向目的地的工作负载转发外部客户端属性（IP 地址、证书信息）{#forwarding-external-client-attributes-to-destination-workloads}

许多应用程序需要知道发起源请求的客户端 IP 地址和证书信息才能正常工作。
值得注意的是填充了客户端 IP 的日志、验证工具以及安全工具。
例如 Web Application Firewalls (WAF)，它应用这些信息来运行正确的规则集。
反向代理的主要工作内容是给服务提供客户端属性。为了向目的地的工作负载转发这些客户端属性，
代理使用  `X-Forwarded-For` (XFF) 和 `X-Forwarded-Client-Cert` (XFCC) 头。

如今的网络千差万别，无论网络拓扑结构如何，对这些多样化属性的支持都是必要的。
不管网络使用的是基于云的负载均衡、前置负载均衡、直接暴露在网络上的 Gateway、
为许多中间代理服务的 Gateway，还是没有指定其他部署拓扑等，这些信息都是需要保存和转发。

当 Istio 提供一个 [Ingress Gateway](/zh/docs/tasks/traffic-management/ingress/ingress-control/)，
鉴于上述多样化架构的复杂性，无法提供合理的默认值，将客户端属性正确转发到目标工作负载。
随着 Istio 多集群部署模式越来越普遍，这个问题需要被越来越重视。

了解关于 `X-Forwarded-For` 更多信息，参考 IETF 的 [RFC](https://tools.ietf.org/html/rfc7239)。

## 配置网络拓扑{#configuring-network-topologies}

XFF 和 XFCC 头的配置可以通过 `MeshConfig` 为所有 Gateway 工作负载进行全局设置，
也可以通过使用 Pod 注解给每个 Gateway 配置。例如，在安装或者升级期间，使用 `IstioOperator` 自定义资源去配置全局设置：

{{< text syntax=yaml snip_id=none >}}
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

在您的 Istio Ingress Gateway Pod 的 Spec 通过添加 `proxy.istio.io/config` 注解可以设置这两个配置。

{{< text syntax=yaml snip_id=none >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": <VALUE>, "forwardClientCertDetails": <ENUM_VALUE> } }'
{{< /text >}}

### 配置 X-Forwarded-For 头{#configuring-X-Forwarded-For-headers}

应用程序依靠反向代理来转发请求的客户端属性，如 `X-Forwarded-For` 头。
然而由于 Istio 可以部署多样性的网络拓扑，您必须设置 Istio 网关代理上游的可信代理数量 `numTrustedProxies`，
这样才能正确提取客户端地址。因为它将控制 Ingress Gateway 在 `X-Envoy-Eternal-Address` 头中填充的值，
该值可以被上游服务可靠地用于访问客户的原始 IP 地址。

例如，如果在 Istio Gateway 之前，有一个基于云的负载均衡和一个反向代理，设置 `numTrustedProxies` 为 `2`。

{{< idea >}}
需要注意的是，在 Istio Gateway 代理前面的所有代理必须先解析 HTTP 流量，并将每一次转发信息附加到
`X-Forwarded-For` 头中。如果 `X-Forwarded-For` 头中的条目数少于所配置的可信跳数
Envoy 就直接回调下游地址作为可信客户地址。
请参考 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for)
去了解如何确定 `X-Forwarded-For` 头文件和受信任的客户地址。
{{< /idea >}}

#### httpbin X-Forwarded-For 示例{#example-using-X-Forwarded-For-capability-with-httpbin}

1. 运行以下命令去创建一个 `topology.yaml` 的文件，并且设置 `numTrustedProxies` 为 `2`，然后安装 Istio：

    {{< text syntax=bash snip_id=install_num_trusted_proxies_two >}}
    $ cat <<EOF > topology.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          gatewayTopology:
            numTrustedProxies: 2
    EOF
    $ istioctl install -f topology.yaml
    {{< /text >}}

    {{< idea >}}
    如果你之前安装了 Istio Ingress Gateway，请在第 1 步之后重启所有 Ingress Gateway Pod。
    {{</ idea >}}

1. 创建一个 `httpbin` 命名空间：

    {{< text syntax=bash snip_id=create_httpbin_namespace >}}
    $ kubectl create namespace httpbin
    namespace/httpbin created
    {{< /text >}}

1. 启用 Sidecar 注入，设置 `istio-injection` 标签为 `enabled`：

    {{< text syntax=bash snip_id=label_httpbin_namespace >}}
    $ kubectl label --overwrite namespace httpbin istio-injection=enabled
    namespace/httpbin labeled
    {{< /text >}}

1. 在 `httpbin` 命名空间部署 `httpbin`：

    {{< text syntax=bash snip_id=apply_httpbin >}}
    $ kubectl apply -n httpbin -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. 部署一个 `httpbin` 相关的 Gateway：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=deploy_httpbin_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/httpbin-gateway.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=deploy_httpbin_k8s_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@
$ kubectl wait --for=condition=programmed gtw -n httpbin httpbin-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6) 基于您的 Istio Ingress Gateway 设置一个本地环境变量 `GATEWAY_URL`：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=export_gateway_url >}}
$ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=export_k8s_gateway_url >}}
$ export GATEWAY_URL=$(kubectl get gateways.gateway.networking.k8s.io httpbin-gateway -n httpbin -ojsonpath='{.status.addresses[0].value}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) 运行下面的 `curl` 命令，模拟在 `X-Forwarded-For` 头中包含代理地址的请求：

    {{< text syntax=bash snip_id=curl_xff_headers >}}
    $ curl -s -H 'X-Forwarded-For: 56.5.6.7, 72.9.5.6, 98.1.2.3' "$GATEWAY_URL/get?show_env=true"
    {
    "args": {
      "show_env": "true"
    },
      "headers": {
      "Accept": ...
      "Host": ...
      "User-Agent": ...
      "X-B3-Parentspanid": ...
      "X-B3-Sampled": ...
      "X-B3-Spanid": ...
      "X-B3-Traceid": ...
      "X-Envoy-Attempt-Count": ...
      "X-Envoy-External-Address": "72.9.5.6",
      "X-Forwarded-Client-Cert": ...
      "X-Forwarded-For": "56.5.6.7, 72.9.5.6, 98.1.2.3,10.244.0.1",
      "X-Forwarded-Proto": ...
      "X-Request-Id": ...
    },
      "origin": "56.5.6.7, 72.9.5.6, 98.1.2.3,10.244.0.1",
      "url": ...
    }
    {{< /text >}}

{{< tip >}}
在以上示例中，`$GATEWAY_URL` 被解析为 10.244.0.1。这可能与您的环境有所不同。
{{< /tip >}}

上面的输出显示了 `httpbin` 工作负载收到的请求头。当 Istio Gateway 收到这个请求时，
它将 `X-Envoy-External-Address` 头设置为您 curl 命令中 `X-Forwarded-For`
头中的第二个到最后一个（`numTrustedProxies: 2`）地址。此外，Gateway 在将其转发到
`httpbin` 工作负载之前，会将自己的 IP 附加到 `X-Forwarded-For` 头中。

### 配置 X-Forwarded-Client-Cert 头{#configuring-X-Forwarded-Client-Cert-headers}

从 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
参考 XFCC：

{{< quote >}}
x-forwarded-client-cert（XFCC）是一个代理头，
它表明了请求从客户端流向服务器的途中所流经的部分或全部客户端和代理的证书信息。
代理商可以选择在代理请求之前对 XFCC 头进行清理/附加/转发。
{{< /quote >}}

配置如何处理 XFCC 头文件，需要在 `IstioOperator` 中设置 `forwardClientCertDetails`：

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

其中 `ENUM_VALUE` 可以是以下类型：

| `ENUM_VALUE`          |                                                                                                                                |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------|
| `UNDEFINED`           | 没有设置字段。                                                                                                              |
| `SANITIZE`            | 不要向下一跳地址发送 XFCC 头。                                       |
| `FORWARD_ONLY`        | 当客户端连接为 mTLS（Mutual TLS）时，在请求中转发 XFCC 头。                                       |
| `APPEND_FORWARD`      | 当客户端连接为 mTLS 时，将客户端证书信息附加到请求的 XFCC头 中并转发。|
| `SANITIZE_SET`        | 当客户端连接为 mTLS 时，用客户端证书信息重置 XFCC 头，并将其发送到下一跳地址。这是 Gateway 的默认值。 |
| `ALWAYS_FORWARD_ONLY` | 无论客户端连接是否为 mTLS，总是在请求中转发 XFCC 头。                            |

参考 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)，
了解并使用此功能的示例。

## PROXY 协议{#PROXY-protocol}

[PROXY 协议](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)允许在不依赖 HTTP、`X-Forwarded-For` 和 `X-Envoy-External-Address` 头这类 7 层协议的情况下，在多个 TCP 代理之间交换和保存客户端属性。
此协议适用于外部 TCP 负载均衡器需要通过 Istio Gateway 将 TCP 流量代理到后端 TCP 服务并且仍然将客户端属性（例如源 IP）
暴露给上游 TCP 服务端点的场景。PROXY 协议可以通过 `EnvoyFilter` 启用。

{{< warning >}}
Envoy 转发 TCP 流量时仅支持 PROXY 协议。
有关更多详情以及某些重要的性能警告，请参见
[Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol)。

PROXY 协议不应该用于 L7 流量，也不应该在 L7 负载均衡器后使用 Istio Gateway。
{{< /warning >}}

如果外部负载均衡器配置为转发 TCP 流量并使用 PROXY 协议，Istio Gateway TCP 侦听器也必须配置为接受 PROXY 协议。
启用该功能需要在 Gateway 工作负载上使用 `EnvoyFilter` 添加
[Envoy PROXY 协议过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listener_filters/proxy_protocol)。示例：

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio: ingressgateway
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio.io/gateway-name: <GATEWAY_NAME>
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

客户端 IP 从 PROXY 协议中由 Gateway 获取，并在 `X-Forwarded-For` 和 `X-Envoy-External-Address` 头中设置（或附加）。
请注意，PROXY 协议与 `X-Forwarded-For` 和 `X-Envoy-External-Address` 等 L7 头互斥。
当 PROXY 协议与 `gatewayTopology` 配置一起使用时，在确定可信客户地址时会优先使用 `numTrustedProxies`
和接收到的 `X-Forwarded-For` 头，PROXY 协议客户端信息将被忽略。

请注意，上面的示例仅将 Gateway 配置为接受传入的 PROXY 协议 TCP 流量。
有关如何配置 Envoy 本身以使用 PROXY 协议与上游服务通信的示例，请参见
[Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol)。
