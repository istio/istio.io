---
title: About
overview: About Istio.

order: 0

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

Istio currently supports the [Kubernetes](https://kubernetes.io) platform,
and can also be run without Kubernetes using [Consul](https://www.consul.io/) or
[Eureka](https://github.com/Netflix/eureka) as the service registry. We
plan to add support for additional platforms such as
[Cloud Foundry](https://www.cloudfoundry.org/),
and [Apache Mesos](http://mesos.apache.org/) in the near future.
