---
title: ConflictingMeshGatewayVirtualServiceHosts
layout: analysis-message
---

This message occurs when Istio detects an overlap between virtual service
resources. For example, you have multiple virtual services defined to use the
same hostname and gateway.

To resolve this problem, check your Istio configuration, remove the conflicting
values and try again.
