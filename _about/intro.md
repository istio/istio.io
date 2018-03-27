---
title: What is Istio?
overview: Context about what problems Istio is designed to solve.

order: 0

layout: about
type: markdown
toc: false
redirect_from: /about.html
---

Istio is an open platform that provides a uniform way to connect, manage,
and secure microservices. Istio supports managing traffic flows between
microservices, enforcing access policies, and aggregating telemetry data,
all without requiring changes to the microservice code. Istio gives you:

- Automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic.

- Fine-grained control of traffic behavior with rich routing rules,
retries, failovers, and fault injection.

- A pluggable policy layer and configuration API supporting access controls,
rate limits and quotas.

- Automatic metrics, logs, and traces for all traffic within a cluster,
including cluster ingress and egress.

- Secure service-to-service communication in a cluster with strong 
identity-based authentication and authorization.

Istio can be deployed on [Kubernetes](https://kubernetes.io),
[Nomad](https://nomadproject.io) with [Consul](https://www.consul.io/). We
plan to add support for additional platforms such as
[Cloud Foundry](https://www.cloudfoundry.org/),
and [Apache Mesos](https://mesos.apache.org/) in the near future.
