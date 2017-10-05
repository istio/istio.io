---
title: Release Notes
overview: What's been happening with Istio

order: 50

layout: docs
type: markdown
---

## Istio 0.2

#### General

- **Updated Config Model**. Istio now uses the Kubernetes Custom Resource Definition model to describe and store its configuration.
When running in Kubernetes environment, configuration can now be optionally managed using the `kubectl` command.

- **Multiple Namespace Support**. Istio control plane components are now in the dedicated "istio-system" namespace. Istio can manage 
services in other non-system namespaces.

- **Mesh Expansion**. Initial support for adding non-Kubernetes services (in the form of VMs and/or physical machines) to a mesh. This is an early version of
this features which has limitations (such as requiring a flat network across containers and VMs).

- **Multi-Platform Support**. Initial support for running Istio outside Kubernetes using Consul or Eureka as service registries. This feature can handle 
services across multiple service registries.

- **Automatic injection of sidecars**. Istio sidecar can automatically be injected into a Pod upon deployment using the [Initializers](https://kubernetes.io/docs/admin/extensible-admission-controllers/#what-are-initializers) alpha feature in Kubernetes.

#### Perf and Quality

There have been many performance and reliability improvements throughout the system. We don’t consider Istio 0.2 ready for production yet, but we’ve made excellent progress in that direction. Here are a few items of note:

- **Caching Client**. The Mixer client library used by Envoy now provides caching for Check calls and batching for Report calls, considerably reducing 
end-to-end overhead.

- **Avoid Hot Restarts**. The need to hot-restart Envoy has been mostly eliminated through effective use of LDS/RDS/CDS/EDS.

- **Reduced Memory Use**. Significantly reduced the size of the sidecar helper agent, from 50Mb to 7Mb.

- **Improved Mixer Latency**. Mixer now clearly delineates configuration-time vs. request-time computations, which avoids doing extra setup work at 
request-time for initial requests and thus delivers a smoother average latency. Better resource caching also contributes to better end-to-end perf.

- **Reduced Latency for Egress Traffic**. We now forward traffic to external services directly from the sidecar.

#### Traffic Management

- **Egress Rules**. It’s now possible to specify routing rules for egress traffic.

- **New Protocols**. Mesh-wide support for WebSocket connections, MongoDB proxying.

- **Other Improvements**. Ingress properly supports gRPC services, interfacing headless services, better support for health checks, and
Jaeger tracing.

#### Policy Enforcement & Telemetry

- **Ingress Policies**. Policies can now be applied to north-south traffic in addition to east-west traffic supported in 0.1.

- **Support for TCP Services**. In addition to the HTTP-level policy controls available in 0.1, 0.2 introduces support for TCP-centric policy controls for 
TCP services.

- **New Mixer API**. The API that Envoy uses to interact with Mixer has been completely redesigned for increased robustness, flexibility, and to support 
rich proxy-side caching and batching for increased performance.

- **New Mixer Adapter Model**. A new adapter composition model makes it easier to extend Mixer by adding whole new classes of adapters via templates. This 
new model will serve as the foundational building block for many features in the future.

- **Improved Mixer Build Model**. It’s now easier to build a Mixer binary that includes custom adapters.

- **Mixer Adapter Updates**. The built-in adapters have all been rewritten to fit into the new adapter model. The stackdriver adapter has been added for this
release. The experimental redisquota adapter has been removed in the 0.2 release, but is expected to come back in production quality for the 0.3 release.

- **Mixer Call Tracing**. Calls between Envoy and Mixer can now be traced and analyzed in the Zipkin dashboard.

#### Security

- **Mutual TLS for TCP Traffic**. In addition to HTTP traffic, mutual TLS is now supported for TCP traffic as well.

- **Identity Provisioning for VMs and Physical Machines**. Auth supports a new mechanism using a per-node agent for
identity provisioning. This agent runs on each node (VM / physical machine) and is responsible for generating and sending out the CSR
(Certificate Signing Request) to get certificates from Istio CA.

- **Bring Your Own CA Certificates**. Allows users to provide their own key and certificate for Istio CA.

- **Persistent CA Key/Certificate Storage**. Istio CA now supports storing signing key/certificates in
persistent storage to facilitate CA restarts. 

## Istio 0.1

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
