---
title: Does Auto mutual TLS exclude ports set using "excludeInboundPorts" annotation?
weight: 80
---

No. When `traffic.sidecar.istio.io/excludeInboundPorts` is used on server workloads, Istio still
configures the client Envoy to send mutual TLS by default. To change that, you need to configure
a Destination Rule with mutual TLS mode set to `DISABLE` to have clients send plain text to those
ports.
