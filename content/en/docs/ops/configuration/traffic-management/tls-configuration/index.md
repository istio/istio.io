---
title: Understanding TLS Configuration
linktitle: TLS Configuration
description: How to configure TLS settings to secure network traffic.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

One of Istio's most important features is the ability to lock down and secure network traffic to, from,
and within the mesh. However, configuring TLS settings can be confusing and a common source of misconfiguration.
This document attempts to explain the various connections involved when sending requests in Istio and how
their associated TLS settings are configured.
Refer to [TLS configuration mistakes](/docs/ops/common-problems/network-issues/#tls-configuration-mistakes)
for a summary of some the most common TLS configuration problems.

## Sidecars

Sidecar traffic has a variety of associated connections. Let's break them down one at a time.

{{< image width="100%"
    link="sidecar-connections.svg"
    alt="Sidecar proxy network connections"
    title="Sidecar connections"
    caption="Sidecar proxy network connections"
    >}}

1. **External inbound traffic**
    This is traffic coming from an outside client that is captured by the sidecar.
    If the client is inside the mesh, this traffic may be encrypted with Istio mutual TLS.
    By default, the sidecar will be configured to accept both mTLS and non-mTLS traffic, known as `PERMISSIVE` mode.
    The mode can alternatively be configured to `STRICT`, where traffic must be mTLS, or `DISABLE`, where traffic must be plaintext.
    The mTLS mode is configured using a [`PeerAuthentication` resource](/docs/reference/config/security/peer_authentication/).

1. **Local inbound traffic**
    This is traffic going to your application service, from the sidecar. This traffic will always be forwarded as-is.
    Note that this does not mean it's always plaintext; the sidecar may pass a TLS connection through.
    It just means that a new TLS connection will never be originated from the sidecar.

1. **Local outbound traffic**
    This is outgoing traffic from your application service that is intercepted by the sidecar.
    Your application may be sending plaintext or TLS traffic.
    If [automatic protocol selection](/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)
    is enabled, Istio will automatically detect the protocol. Otherwise you should use the port name in the destination service to
    [manually specify the protocol](/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).

1. **External outbound traffic**
    This is traffic leaving the sidecar to some external destination. Traffic can be forwarded as is, or a TLS connection can
    be initiated (mTLS or standard TLS). This is controlled using the TLS mode setting in the `trafficPolicy` of a
    [`DestinationRule` resource](/docs/reference/config/networking/destination-rule/).
    A mode setting of `DISABLE` will send plaintext, while `SIMPLE`, `MUTUAL`, and `ISTIO_MUTUAL` will originate a TLS connection.

The key takeaways are:

- `PeerAuthentication` is used to configure what type of mTLS traffic the sidecar will accept.
- `DestinationRule` is used to configure what type of TLS traffic the sidecar will send.
- Port names, or automatic protocol selection, determines which protocol the sidecar will parse traffic as.

## Auto mTLS

As described above, a `DestinationRule` controls whether outgoing traffic uses mTLS or not.
However, configuring this for every workload can be tedious. Typically, you want Istio to always use mTLS
wherever possible, and only send plaintext to workloads that are not part of the mesh (i.e., ones without sidecars).

Istio makes this easy with a feature called "Auto mTLS". Auto mTLS works by doing exactly that. If TLS settings are
not explicitly configured in a `DestinationRule`, the sidecar will automatically determine if
[Istio mutual TLS](/about/faq/#difference-between-mutual-and-istio-mutual) should be sent.
This means that without any configuration, all inter-mesh traffic will be mTLS encrypted.

## Gateways

Any given request to a gateway will have two connections.

{{< image width="100%"
    link="gateway-connections.svg"
    alt="Gateway network connections"
    title="Gateway connections"
    caption="Gateway network connections"
    >}}

1. The inbound request, initiated by some client such as `curl` or a web browser. This is often called the "downstream" connection.

1. The outbound request, initiated by the gateway to some backend. This is often called the "upstream" connection.

Both of these connections have independent TLS configurations.

Note that the configuration of ingress and egress gateways are identical.
The `istio-ingress-gateway` and `istio-egress-gateway` are just two specialized gateway deployments.
The difference is that the client of an ingress gateway is running outside of the mesh while in the case of an egress gateway,
the destination is outside of the mesh.

### Inbound

As part of the inbound request, the gateway must decode the traffic in order to apply routing rules.
This is done based on the server configuration in a [`Gateway` resource](/docs/reference/config/networking/gateway/).
For example, if an inbound connection is plaintext HTTP, the port protocol is configured as `HTTP`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: Gateway
...
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
{{< /text >}}

Similarly, for raw TCP traffic, the protocol would be set to `TCP`.

For TLS connections, there are a few more options:

1. What protocol is encapsulated?
    If the connection is HTTPS, the server protocol should be configured as `HTTPS`.
    Otherwise, for a raw TCP connection encapsulated with TLS, the protocol should be set to `TLS`.

1. Is the TLS connection terminated or passed through?
    For passthrough traffic, configure the TLS mode field to `PASSTHROUGH`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
    {{< /text >}}

    In this mode, Istio will route based on SNI information and forward the connection as-is to the destination.

1. Should mutual TLS be used?
    Mutual TLS can be configured through the TLS mode `MUTUAL`. When this is configured, a client certificate will be
    requested and verified against the configured `caCertificates` or `credentialName`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1beta1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: MUTUAL
          caCertificates: ...
    {{< /text >}}

### Outbound

While the inbound side configures what type of traffic to expect and how to process it, the outbound configuration controls
what type of traffic the gateway will send. This is configured by the TLS settings in a `DestinationRule`,
just like external outbound traffic from [sidecars](#sidecars), or [auto mTLS](#auto-mtls) by default.

The only difference is that you should be careful to consider the `Gateway` settings when configuring this.
For example, if the `Gateway` is configured with TLS `PASSTHROUGH` while the `DestinationRule` configures TLS origination,
you will end up with [double encryption](/docs/ops/common-problems/network-issues/#double-tls).
This works, but is often not the desired behavior.

A `VirtualService` bound to the gateway needs care as well to
[ensure it is consistent](/docs/ops/common-problems/network-issues/#gateway-mismatch)
with the `Gateway` definition.
