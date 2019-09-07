---
title: Kubernetes - How can I enable Istio sidecar to actively capture the inbound traffic on port list instead of using the automatical inbound port detection?
weight: 20
---

You can restore the white list capture ports model by overriding pod annotation `traffic.sidecar.istio.io/includeInboundPorts` to port list. Contrarily, to bypass the interception on certain ports, you can add pod annotation `traffic.sidecar.istio.io/excludeOutboundPorts` with bypass port list.
