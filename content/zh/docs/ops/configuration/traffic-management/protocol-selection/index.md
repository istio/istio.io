---
title: 协议选择
description: 关于如何声明协议。
weight: 10
keywords: [protocol,protocol sniffing,protocol selection,protocol detection]
aliases:
  - /zh/help/ops/traffic-management/protocol-selection
  - /zh/help/ops/protocol-selection
  - /zh/help/tasks/traffic-management/protocol-selection
  - /zh/docs/ops/traffic-management/protocol-selection
owner: istio/wg-networking-maintainers
test: no
---

Istio 默认支持代理所有 TCP 流量。包括 HTTP、HTTPS、gRPC 以及原始 TCP 协议。但为了提供额外的能力，比如路由和丰富的指标，必须确定协议。协议可以被自动检测或者手动声明。

使用非基于 TCP 的协议时，如 UDP，不会被 Istio 代理拦截，可以继续正常工作。但是不能在仅代理的组件中使用，如 Ingress 或 Egress Gateway。

## 自动协议选择{#automatic-protocol-selection}

Istio 可以自动检测出 HTTP 和 HTTP/2 流量。如果未自动检测出协议，流量将会视为普通 TCP 流量。

{{< tip >}}
Server First 协议，如 MySQL，不兼容自动协议选择。
查看更多[Server First 协议](/zh/docs/ops/deployment/requirements#server-first-protocols)
{{< /tip >}}

## 显式协议选择{#explicit-protocol-selection}

协议可以在 Service 定义中手动指定。

可以通过以下两种方式配置：

- 通过端口名称配置：`name: <protocol>[-<suffix>]`。
- 在版本 1.18+ 的Kubernetes，通过 `appProtocol` 字段配置：`appProtocol: <protocol>`。

请注意，由于网关可能终止 TLS 而协议可能被协商，因此网关的行为在某些情况下可能会有所不同。

支持以下协议：

| 协议                             | Sidecar 用途                                                                                                                                                         | Gateway 用途                                                                                                                                                         |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `http`                                | HTTP/1.1 明文流量                                                                                                                                              | HTTP（1.1 或 2）明文流量                                                                                                                                       |
| `http2`                               | HTTP/2 明文流量                                                                                                                                                | HTTP（1.1 或 2）明文流量                                                                                                                                       |
| `https`                               | TLS 加密的数据。由于 Sidecar 不解密 TLS 流量，因此这与 `tls` 相同。| TLS 加密的 HTTP（1.1 或 2）流量                                                                                                                                   |
| `tcp`                                 | 不透明的 TCP 数据流                                                                                                                                                  | 不透明的 TCP 数据流                                                                                                                                                  |
| `tls`                                 | TLS 加密数据                                                                                                                                                      | TLS 加密数据                                                                                                                                                      |
| `grpc`, `grpc-web`                                | 与 `http2` 相同                                                                                                                                                         | 与 `http2` 相同                                                                                                                                                         |  |
| `mongo`, `mysql`, `redis` | 实验性应用协议支持。要启用它们，请配置相应的 Pilot [环境变量](/zh/docs/reference/commands/pilot-discovery/#envvars)。如果未启用，则将其视为不透明的 TCP 数据流。 | 实验性应用协议支持。要启用它们，请配置相应的 Pilot [环境变量](/zh/docs/reference/commands/pilot-discovery/#envvars)。如果未启用，则将其视为不透明的 TCP 数据流。 |

以下示例定义了一个通过 `appProtocol` 定义 `https` 端口和通过 `name` 定义 `http` 端口的服务：

{{< text yaml >}}
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - port: 3306
    name: database
    appProtocol: mysql
  - port: 80
    name: http-web
{{< /text >}}

## HTTP 网关协议选择{#http-gateway-protocol-selection}

与 Sidecar 不同，网关默认无法自动检测转发请求到后端服务时所使用的具体 HTTP 协议。
因此，除非使用显式协议选择指定 HTTP/1.1（`http`）或 HTTP/2（`http2` 或 `grpc`），
否则网关将使用 HTTP/1.1 转发所有传入的 HTTP 请求。

除了使用显式协议选择外，您还可以通过为服务设置 [`useClientProtocol`](/zh/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings)
选项来指示网关使用与传入请求相同的协议转发请求。但需要注意，对于不支持 HTTP/2 的服务使用此选项可能存在风险，
因为 HTTPS 网关总是[宣传](https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation)支持 HTTP/1.1 和 HTTP/2。
因此，即使后端服务不支持 HTTP/2，比较新的客户端通常也会认为它支持 HTTP/2，并且选择使用它。
