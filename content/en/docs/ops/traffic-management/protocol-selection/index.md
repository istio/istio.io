---
title: Protocol Selection
description: Information on how to specify protocols.
weight: 98
keywords: [protocol,protocol sniffing,protocol selection,protocol detection]
aliases:
    - /help/ops/traffic-management/protocol-selection
    - /help/ops/protocol-selection
    - /help/tasks/traffic-management/protocol-selection
---

Istio supports proxying all TCP traffic by default, but in order to provide additional capabilities, such as routing and rich metrics, the protocol must be determined. This can be done automatically or explicitly specified.

## Automatic Protocol Selection

By default, Istio will automatically detect HTTP and HTTP/2 traffic. If the protocol cannot automatically be determined, traffic will be treated as plain TCP traffic.

This feature can be turned off by providing the Helm value `--set pilot.enableProtocolSniffing=false`.

## Manual Protocol Selection

Other protocols must be specified manually by naming the Service port to the protocol. The port name should match either `protocol` or `protocol-suffix`.

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

\* These protocols are disabled by default to avoid accidentally enabling experimental features. To enable them, Pilot [environment variables](/docs/reference/commands/pilot-discovery/#envvars) must be configured

Below is an example of a Service that defines a `mysql` port and an `http` port:

```yaml
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - number: 3306
    name: mysql
  - number: 80
    name: http-web
```
