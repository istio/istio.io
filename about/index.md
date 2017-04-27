---
title: About
index: true

order: 0

bodyclass: about
layout: about
type: markdown
---

# About

Istio is an open platform that provides a uniform way to connect, manage,
and secure microservices. Istio supports managing traffic flows between
microservices, enforcing access policies, and aggregating telemetry data,
all without requiring changes to the microservice code. Istio gives you:

- Automatic load balancing for HTTP, gRPC, and TCP traffic.

- Fine-grained control of traffic behavior with rich routing rules,
retries, failovers, and fault injection.

- A pluggable policy layer and configuration API supporting access controls,
rate limits and quotas.

- Automatic metrics, logs, and traces for all traffic within a cluster,
including cluster ingress and egress.

- Secure service-to-service authentication with strong identity assertions
between services in a cluster.

Istio currently only supports the Kubernetes platform, although we plan support
for additional platforms such as CloudFoundry, Mesos, and bare metal in the near future.
