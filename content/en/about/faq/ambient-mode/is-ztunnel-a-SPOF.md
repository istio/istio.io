---
title: Is ztunnel a single point of failure?
weight: 25
---

Istio's ztunnel does not introduce a single point of failure (SPOF) into a Kubernetes cluster. Failures of ztunnel are confined to a single node, which is considered a fallible component in a cluster. It behaves the same as other node-critical infrastructure running on every cluster such as the Linux kernel, container runtime, etc. In a properly designed system, node outages do not lead to cluster outages. [Learn more](https://blog.howardjohn.info/posts/ambient-spof/).
