---
title: Istio 0.1
weight: 100
aliases:
    - /docs/welcome/notes/0.1.html
---

Istio 0.1 is the initial [release](https://github.com/istio/istio/releases) of Istio. It works in a single Kubernetes cluster and supports the following features:
- Installation of Istio into a Kubernetes namespace with a single command.
- Semi-automated injection of Envoy proxies into Kubernetes pods.
- Automatic traffic capture for Kubernetes pods using iptables.
- In-cluster load balancing for HTTP, gRPC, and TCP traffic.
- Support for timeouts, retries with budgets, and circuit breakers.
- Istio-integrated Kubernetes Ingress support (Istio acts as an Ingress Controller).
- Fine-grained traffic routing controls, including A/B testing, canarying, red/black deployments.
- Flexible in-memory rate limiting.
- L7 telemetry and logging for HTTP and gRPC using Prometheus.
- Grafana dashboards showing per-service L7 metrics.
- Request tracing through Envoy with Zipkin.
- Service-to-service authentication using mutual TLS.
- Simple service-to-service authorization using deny expressions.
