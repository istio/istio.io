
#### Adding Glossary Entries

You should also add glossary entries for the key concepts. Create a new file named `gateway-api-glossary.md` in the `content/en/docs/reference/glossary` directory with the following content:

```markdown
---
title: Gateway API Glossary
description: Glossary of terms related to the Gateway API.
weight: 50
---

### Gateway

A Gateway describes a load balancer operating at the edge of the mesh, handling incoming or outgoing HTTP/TCP connections. It configures a set of listeners for inbound or outbound traffic.

### HTTPRoute

An HTTPRoute defines how HTTP traffic should be routed. It includes rules for matching requests and forwarding them to specific services.

### TCPRoute

Similar to HTTPRoute, but for TCP traffic. It defines rules for matching TCP connections and forwarding them.

### parentRefs

This field specifies the parent resources that a route is attached to. For example, an HTTPRoute might specify a Gateway as its parent.

### targetRefs

This field specifies the target resources that a route should forward traffic to. For example, an HTTPRoute might specify a Kubernetes Service as its target.
