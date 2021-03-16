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

## 手动协议选择{#manual-protocol-selection}

协议可以在 Service 定义中手动指定。

可以通过以下两种方式配置：

- 通过端口名称配置：`name: <protocol>[-<suffix>]`。
- 在版本 1.18+ 的Kubernetes，通过 `appProtocol` 字段配置：`appProtocol: <protocol>`。

支持以下协议：

- `HTTP`
- `HTTP2`
- `HTTPS`
- `TCP`
- `TLS`
- `gRPC`
- `gRPC-Web`
- `Mongo`
- `MySQL`\*
- `Redis`\*
- `UDP` (UDP 不会被代理，但可以将端口指定为 UDP)

\* 在默认情况下，这些协议是禁用的，目的是避免无意启用 Experimental Feature。
如需启用它们，需配置相应的 Pilot [环境变量](/zh/docs/reference/commands/pilot-discovery/#envvars)。

例如，Service 通过 `appProtocol` 、名称分别定义一个 `mysql` 端口和一个 `http` 端口：

{{< text yaml >}}
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - number: 3306
    name: database
    appProtocol: mysql
  - number: 80
    name: http-web
{{< /text >}}
