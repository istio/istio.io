---
title: On what ports does a sidecar proxy capture inbound traffic?
weight: 20
---

Istio captures inbound traffic on all ports by default.
You can override this behavior using the `traffic.sidecar.istio.io/includeInboundPorts` pod annotation
to specify an explicit list of ports to capture, or using `traffic.sidecar.istio.io/excludeOutboundPorts`
to specify a list of ports to bypass.
