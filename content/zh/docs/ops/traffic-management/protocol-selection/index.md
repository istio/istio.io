---
title: 协议选择
description: 关于怎么声明协议的信息。
weight: 98
keywords: [protocol,protocol sniffing,protocol selection,protocol detection]
aliases:
    - /zh/help/ops/traffic-management/protocol-selection
    - /zh/help/ops/protocol-selection
    - /zh/help/tasks/traffic-management/protocol-selection
---

Istio 默认支持代理所有 TCP 流量，但为了提供附加的能力，比如路由和丰富的指标，使用什么协议必须被确定。协议可以被自动检测或者明确的声明确定。

## 手动协议选择{#manual-protocol-selection}

通过声明一个 Service 端口，协议可以被手动指定 `name: <protocol>[-<suffix>]`。
下列协议是被支持的：

- `grpc`
- `grpc-web`
- `http`
- `http2`
- `https`
- `mongo`
- `mysql`\*
- `redis`\*
- `tcp`
- `tls`
- `udp`

\* 这些协议默认被禁用以阻止偶然地产生试验性的特性。
要启用他们，请配置相应的 Pilot [环境变量](/zh/docs/reference/commands/pilot-discovery/#envvars)。

下面是一个 Service 例子，它定义了一个 `mysql` 端口 和一个 `http` 端口：

{{< text yaml >}}
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - number: 3306
    name: mysql
  - number: 80
    name: http-web
{{< /text >}}

## 自动协议选择（试验性的）{#automatic-protocol-selection-(experimental)}

Istio 可以自动检测出 HTTP 和 HTTP/2 流量。如果协议可以被自动确定，流量将会被当作普通 TCP 流量对待。

这个特性是试验性的并且默认被关闭。通过设置这些安装选项可以将其打开 `--set values.pilot.enableProtocolSniffingForOutbound=true --set values.pilot.enableProtocolSniffingForInbound=true`。
