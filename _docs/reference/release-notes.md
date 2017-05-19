---
title: Release Notes
overview: What's been happening with Istio.

order: 50

layout: docs
type: markdown
---

## Istio v0.1

Istio v0.1 is the initial release of Istio. It works in a single Kubernetes cluster with a small number of services. Istio v0.1 supports the following features:
- Installation of Istio into a Kubernetes namespace with a single command.
- Injection of Envoy proxies into Kubernetes pods using `istioctl kube-inject`.
- Automatic traffic capture for Kubernetes pods using iptables.
- In-cluster load balancing for HTTP, gRPC, and TCP traffic.
- Basic Kubernetes Ingress and Egress support.
- Fine-grained traffic routing controls.
- Flexible in-memory rate limiting.
- L7 telemetry and logging for HTTP and gRPC using prometheus.
- Grafana dashboards showing per-service L7 metrics.
- Service to service Authentication using Mututal TLS.
- Simple service to service Authorization using deny expressions.
