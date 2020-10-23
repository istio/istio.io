---
title: Traffic Requirements
description: Information on how Istio routes traffic, and requirements on applications it imposes
weight: 10
keywords: [requirements,traffic requirements]
owner: istio/wg-networking-maintainers
test: no
---

## Server First Protocols

Some protocols are "Server First" protocols, which means the server will send the first bytes. This may have an impact on
[`PERMISSIVE`](/docs/reference/config/security/peer_authentication/#PeerAuthentication-MutualTLS-Mode) mTLS and [Automatic protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection).

Both of these features work by inspecting the initial bytes of a connection to determine the protocol, which is incompatible with server first protocols.

In order to support these cases, follow the [Explicit protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) steps to declare the protocol of the application as `TCP`.

The following ports are known to be commonly carry server first protocols, and are automatically assumed to be `TCP`:

|Protocol|Port|
|--------|----|
| SMTP   |25  |
| DNS    |53  |
| MySQL  |3306|
| MongoDB|27017|

Additionally, TLS configuration must be configured. Because TLS communication is not server first, TLS encrypted server first traffic will not have issues with protocol detection. There are a few options to get things working

1. Configure `mTLS` mode `STRICT` for the server. This will enforce all traffic is TLS encrypted.
1. Configure `mTLS` mode `DISABLE` for the server. This will disable the TLS sniffing, allowing server first protocols to be used
1. Configure all clients to send `TLS` traffic, generally through a [`DestinationRule](/docs/reference/config/networking/destination-rule/#ClientTLSSettings) or relying on Auto mTLS.
1. Configure your application to send TLS traffic directly.

## Application Bind Address

When Istio captures inbound traffic, it will redirect it to the `localhost` address. As a result, applications should bind to either
`localhost` (`127.0.0.1` for IPv4 or `::1` for IPv6) or wildcard (`0.0.0.0` for IPv4 or `::` for IPv6). Applications listening on their
pod IP will need to be modified.

## Outbound traffic

In order to support Istio's traffic routing capabilities, traffic leaving a pod may be routed differently than
when a sidecar is not deployed.

For HTTP based traffic, traffic is routed based on the `Host` header. This may lead to unexpected behavior if the destination IP
and `Host` header are not aligned. For example, a request like `curl 1.2.3.4 -H "Host: httpbin.default"` will be routed to the `httpbin` service,
rather than `1.2.3.4`.

For Non-HTTP based traffic (including HTTPS), Istio does not have access to an `Host` header, so routing decisions are based on the Service IP address.

One implication of this is that direct calls to pods (for example, `curl <POD_IP>`), rather than Services, will not be matched. While the traffic may
be [passed through](/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services), it will not get the full Istio functionality
including mTLS encryption, traffic routing, and telemetry.

