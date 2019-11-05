---
title: 协议选择
description: 关于怎么声明协议的信息。
weight: 98
keywords: [协议,协议嗅探,协议选择,协议探测]
aliases:
    - /help/ops/traffic-management/protocol-selection
    - /help/ops/protocol-selection
    - /help/tasks/traffic-management/protocol-selection
---

Istio 默认支持代理所有 TCP 流量， 但为了提供附加的能力，
比如路由和丰富的指标， 使用什么传输协议必须被检测出来。
This can be done automatically or explicitly specified.

## Manual protocol selection

Protocols can be specified manually by naming the Service port `name: <protocol>[-<suffix>]`.
The following protocols are supported:

- `grpc`
- `http`
- `http2`
- `https`
- `mongo`
- `mysql`\*
- `redis`\*
- `tcp`
- `tls`
- `udp`

\* These protocols are disabled by default to avoid accidentally enabling experimental features.
To enable them, configure the corresponding Pilot [environment variables](/docs/reference/commands/pilot-discovery/#envvars).

Below is an example of a Service that defines a `mysql` port and an `http` port:

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

## Automatic protocol selection (experimental)

Istio can automatically detect HTTP and HTTP/2 traffic. If the protocol cannot automatically be determined, traffic will be treated as plain TCP traffic.

This feature is experimental and off by default. It can be turned on by providing the install options `--set values.pilot.enableProtocolSniffingForOutbound=true --set values.pilot.enableProtocolSniffingForInbound=true`.

