---
title: Does Auto mTLS work for port exlusion?
weight: 80
---

No. When `traffic.sidecar.istio.io/excludeInboundPorts` is used on the server workloads, Istio still
configures the client Envoy to send mutual TLS by default. To change that, you need to configure
a Destination Rule with mutual TLS mode `DISABLE` to make client send plain text to those ports.
