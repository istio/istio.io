---
title: TLS Origination
test: n/a
---

TLS origination occurs when an Istio proxy (sidecar or egress gateway) is configured to accept unencrypted
internal HTTP connections, encrypt the requests, and then forward them to HTTPS servers that are secured
using simple or mutual TLS. This is the opposite of [TLS termination](https://en.wikipedia.org/wiki/TLS_termination_proxy)
where an ingress proxy accepts incoming TLS connections, decrypts the TLS, and passes unencrypted
requests on to internal mesh services.
