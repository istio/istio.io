---
title: Is ztunnel a SPOF?
weight: 25
---

This misunderstanding arises primarily from concerns about the [ztunnel and waypoint proxies](https://istio.io/latest/docs/ambient/overview/). Ztunnel failures are scoped to a single node, which is considered a fallible component in a cluster. It behaves the same as other node-critical infrastructure running on every cluster such as the Linux kernel, container runtime, etc. In a properly designed system, node outages do not lead to cluster outages. [Learn more](https://blog.howardjohn.info/posts/ambient-spof/).