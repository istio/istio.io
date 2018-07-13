---
title: TLS Origination
---

TLS origination occurs when an Istio proxy (sidecar or egress gateway) is configured to accept unencrypted
internal HTTP connections, and then encrypt the request before forwarding it to either a simple or mutual TLS
secured HTTPS server. This is the opposite of [TLS termination](https://en.wikipedia.org/wiki/TLS_termination_proxy)
where an ingress proxy accepts incoming TLS connections, decrypts the TLS, and passes unencrypted
requests on to internal mesh services.
