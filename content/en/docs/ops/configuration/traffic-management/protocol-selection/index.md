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
owner: istio/wg-networking-maintainers
test: no
---

Istio supports proxying any TCP traffic. This includes HTTP, HTTPS, gRPC, as well as raw TCP protocols.
In order to provide additional capabilities, such as routing and rich metrics, the protocol must be determined. This can be done automatically or explicitly specified.

Non-TCP based protocols, such as UDP, are not proxied. These protocols will continue to function as normal, without
any interception by the Istio proxy but cannot be used in proxy-only components such as ingress or egress gateways.

## Automatic protocol selection

Istio can automatically detect HTTP and HTTP/2 traffic. If the protocol cannot automatically be determined, traffic will be treated as plain TCP traffic.

The following protocols are known to be incompatible with automatic protocol selection, and must be
[explicitly declared](#explicit-protocol-selection) or they will be treated as TCP:

|Protocol|Port|
|--------|----|
| SMTP   |25  |
| DNS    |53  |
| MySQL  |3306|
| MongoDB|27017|

### Server first protocols

Some protocols are "Server First" protocols, which means the server will send the first bytes. In these cases, automatic protocol detection
will not function correctly, as Istio will determine the protocol based on the initial bytes. If you are using a server first protocol, you should
follow the explicit protocol selection instructions, below, to declare the protocol.

Additionally, plaintext requests to servers configured in `mTLS` [`PERMISSIVE` mode](/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode) will fail. 
This can be addressed with any of the following steps:

* Configure `mTLS` mode `STRICT` for the server. This will enforce all traffic is TLS encrypted.
* Configure `mTLS` mode `DISABLE` for the server. This will disable the TLS sniffing, allowing server first protocols to be used
* Configure all clients to send `TLS` traffic, generally through a [`DestinationRule](/docs/reference/config/networking/destination-rule/#ClientTLSSettings). 

{{< tip >}}
Since TLS communication is not server first, any TLS based traffic will support protocol detection, even if it is wrapping a protocol that does not support detection, such as MySQL.
{{< /tip >}}

## Explicit protocol selection

Protocols can be specified manually in the Service definition.

This can be configured in two ways:

- By the name of the port: `name: <protocol>[-<suffix>]`.
- In Kubernetes 1.18+, by the `appProtocol` field: `appProtocol: <protocol>`.

The following protocols are supported:

- `http`
- `http2`
- `https`
- `tcp`
- `tls`
- `grpc`
- `grpc-web`
- `mongo`
- `mysql`\*
- `redis`\*
- `udp` (UDP will not be proxied, but the port can be explicitly declared as UDP)

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
