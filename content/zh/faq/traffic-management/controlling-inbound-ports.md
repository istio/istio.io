---
title: Sidecar 代理在哪些端口上截获入站流量？
weight: 20
---

Istio 默认截获所有端口的入站流量。
您可以通过 `traffic.sidecar.istio.io/includeInboundPorts` 这个 pod 注解指定一组端口来截获流量，或通过 `traffic.sidecar.istio.io/excludeOutboundPorts` 指定一组端口来放行流量，以更改这种默认行为。
