---
title: Introduction to Using Gateway API for Istio Users
description: Learn how to use the Gateway API with Istio.
weight: 50
---

## Overview

The Gateway API is a set of resources designed to configure networking in Kubernetes clusters. It provides a more expressive and extensible way to define how traffic should be routed within a cluster. For Istio users, understanding the Gateway API is essential for leveraging its full potential in managing traffic flows.

## Key Concepts

1. **Gateway**: A Gateway describes a load balancer operating at the edge of the mesh, handling incoming or outgoing HTTP/TCP connections. It configures a set of listeners for inbound or outbound traffic.

2. **HTTPRoute**: An HTTPRoute defines how HTTP traffic should be routed. It includes rules for matching requests and forwarding them to specific services.

3. **TCPRoute**: Similar to HTTPRoute, but for TCP traffic. It defines rules for matching TCP connections and forwarding them.

4. **parentRefs**: This field specifies the parent resources that a route is attached to. For example, an HTTPRoute might specify a Gateway as its parent.

5. **targetRefs**: This field specifies the target resources that a route should forward traffic to. For example, an HTTPRoute might specify a Kubernetes Service as its target.

## Example Configuration

Below is an example configuration demonstrating how to use the Gateway API with Istio:

```yaml
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: Gateway
metadata:
  name: my-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    routes:
      kind: HTTPRoute
      name: my-route
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: HTTPRoute
metadata:
  name: my-route
  namespace: default
spec:
  parentRefs:
  - name: my-gateway
    namespace: istio-system
  rules:
  - matches:
    - path:
        type: Prefix
        value: /my-service
    forwardTo:
    - targetRef:
        kind: Service
        name: my-service
        namespace: default
      port: 80
