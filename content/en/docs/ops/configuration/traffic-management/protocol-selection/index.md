---
title: Protocol Selection
description: Information on how to specify protocols.
weight: 10
keywords: [protocol,protocol sniffing,protocol selection,protocol detection]
aliases:
  - /help/ops/traffic-management/protocol-selection
  - /help/ops/protocol-selection
  - /help/tasks/traffic-management/protocol-selection
  - /docs/ops/traffic-management/protocol-selection
---

Istio supports proxying all TCP traffic by default, but in order to provide additional capabilities,
such as routing and rich metrics, the protocol must be determined.
This can be done automatically or explicitly specified.

## Manual protocol selection

Protocols can be specified manually in the Service definition.

This can be configured in two ways:

- By the name of port the port, like `name: <protocol>[-<suffix>]`.
- In Kubernetes 1.18+, by the `appProtocol` field, like `appProtocol: <protocol>`.

The following protocols are supported:

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

\* These protocols are disabled by default to avoid accidentally enabling experimental features.
To enable them, configure the corresponding Pilot [environment variables](/docs/reference/commands/pilot-discovery/#envvars).

Below is an example of a Service that defines a `mysql` port by `appProtocol` and an `http` port by name:

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

## Automatic protocol selection

Istio can automatically detect HTTP and HTTP/2 traffic. If the protocol cannot automatically be determined, traffic will be treated as plain TCP traffic.

This feature is enabled by default. It can be turned off by providing the following install options:

- `--set values.pilot.enableProtocolSniffingForOutbound=false` to disable protocol detection for outbound listeners whose port protocol is not specified or unsupported.
- `--set values.pilot.enableProtocolSniffingForInbound=false` to disable protocol detection for inbound listeners whose port protocol is not specified or unsupported.
