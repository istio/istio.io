---
title: TLS & Tunneling
description: Understanding Istio's secure tunneling protocol.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

## Understanding the HBONE protocol

HBONE (HTTP Based Overlay Network Encapsulation) is an Istio-specific term. It is a mechanism to transparently multiplex TCP streams related to many different application connections over a single, mTLS encrypted network connection - an encrypted tunnel.

In its current implementation within Istio, the HBONE protocol composes 3 open standards:

- [HTTP/2](https://httpwg.org/specs/rfc7540.html)
- [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT)
- [Mutual TLS (mTLS)](https://datatracker.ietf.org/doc/html/rfc8446)

HTTP CONNECT is used to establish a tunnel connection, mTLS is used to secure and encrypt that connection, and HTTP/2 is used to multiplex application connection streams over that single secured and encrypted tunnel, and convey additional stream-level metadata.

## Security and tenancy

As enforced by the mTLS spec, each underlying tunnel connection must have a unique source and unique destination identity, and those identities must be used to establish encryption for that connection.

This means that application connections over the HBONE protocol to the same destination identity will be multiplexed across the same shared, encrypted and secured underlying HTTP/2 connection - in effect, each unique source and destination must get their own dedicated, secure tunnel connection, even if that underlying dedicated connection is handling multiple application-level connections.

## Implementation details

By Istio convention, ztunnel and other proxies that understand the HBONE protocol expose listeners on TCP port 15008.

As HBONE is merely a combination of HTTP/2, HTTP CONNECT, and mTLS, the HBONE tunnel packets that flow between HBONE-enabled proxies looks like the following figure:

{{< image width="100%"
link="hbone-packet.png"
caption="HBONE L3 packet format"
>}}

Additional use cases of HBONE and HTTP tunneling (such as UDP) will be investigated in the future as ambient mode and standards evolve.
