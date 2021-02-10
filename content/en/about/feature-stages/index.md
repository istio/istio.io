---
title: Feature Status
description: List of features and their release stages.
weight: 10
aliases:
    - /docs/reference/release-roadmap.html
    - /docs/reference/feature-stages.html
    - /docs/welcome/feature-stages.html
    - /docs/home/roadmap.html
icon: feature-status
---

This page lists the relative maturity and support
level of every Istio feature. Please note that the phases (Alpha, Beta, and Stable) are applied to individual features
within the project, not to the project as a whole. Here is a high level description of what these labels mean.

## Feature phase definitions

|            | Alpha      | Beta         | Stable
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations.  If you use it in production and encounter a serious issue we may not be able to fix it for you, so be sure that you can continue to function if you have to disable it | Usable in production, not a toy anymore | Dependable, production hardened
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production-worthy. APIs are versioned, with automated version conversion for backward compatibility
|  **Performance**         | Not quantified or guaranteed     | Not quantified or guaranteed         | Performance (latency/scale) is quantified, documented, with guarantees against regression
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm. 1 year notice will be provided before changes
| **Security** | Security vulnerabilities will be handled publicly as simple bug fixes | Security vulnerabilities will be handled according to our [security vulnerability policy](/about/security-vulnerabilities/) | Security vulnerabilities will be handled according to our [security vulnerability policy](/about/security-vulnerabilities/)

## Istio features

Below is our list of existing features and their current phases. This information will be updated after every monthly release.

### Traffic management

| Feature           | Phase
|-------------------|-------------------
| Protocols: HTTP1.1 / HTTP2 / gRPC / TCP | Stable
| Protocols: Websockets / MongoDB  | Stable
| Traffic Control: label/content based routing, traffic shifting | Stable
| Resilience features: timeouts, retries, connection pools, outlier detection | Stable
| Gateway: Ingress, Egress for all protocols | Stable
| TLS termination and SNI Support in Gateways | Stable
| SNI (multiple certs) at ingress | Stable
| [Locality load balancing](/docs/tasks/traffic-management/locality-load-balancing/) | Beta
| Enabling custom filters in Envoy | Alpha
| CNI container interface | Alpha
| [Sidecar API](/docs/reference/config/networking/sidecar/) | Beta
| [DNS Proxying](/docs/ops/configuration/traffic-management/dns-proxy/) | Alpha
| [Kubernetes service-apis](/docs/tasks/traffic-management/ingress/service-apis/) | Alpha

### Observability

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration](/docs/tasks/observability/metrics/querying-metrics/) | Stable
| [Client and Server Telemetry Reporting](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/) | Stable
| [Service Dashboard in Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/) | Stable
| [Distributed Tracing](/docs/tasks/observability/distributed-tracing/) | Stable
| [Stackdriver Integration](/docs/reference/config/proxy_extensions/stackdriver/) | Stable
| [Distributed Tracing to Zipkin / Jaeger](/docs/tasks/observability/distributed-tracing/) | Beta
| [Trace Sampling](/docs/tasks/observability/distributed-tracing/configurability/#trace-sampling) | Beta
| [Request Classification](/docs/tasks/observability/metrics/classify-metrics/) | Beta

### Extensibility

| Feature           | Phase
|-------------------|-------------------
| WebAssembly Extension | Alpha

### Security and policy enforcement

| Feature           | Phase
|-------------------|-------------------
| [Service-to-service mutual TLS](/docs/concepts/security/#mutual-tls-authentication)         | Stable
| [Kubernetes: Service Credential Distribution](/docs/concepts/security/#pki)   | Stable
| [Certificate management on Ingress Gateway](/docs/tasks/traffic-management/ingress/secure-ingress) | Stable
| [Pluggable Key/Cert Support for Istio CA](/docs/tasks/security/cert-management/plugin-ca-cert/)        | Stable
| [Authorization](/docs/concepts/security/#authorization)   | Beta
| [End User (JWT) Authentication](/docs/concepts/security/#authentication)  | Beta
| [Automatic mutual TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) | Beta
| [VM: Service Credential Distribution](/docs/concepts/security/#pki)         | Beta
| [Mutual TLS Migration](/docs/tasks/security/authentication/mtls-migration)    | Beta

### Core

| Feature           | Phase
|-------------------|-------------------
| [Standalone Operator](/docs/setup/install/operator/) | Beta
| [Kubernetes: Envoy Installation and Traffic Interception](/docs/setup/) | Stable
| [Kubernetes: Istio Control Plane Installation](/docs/setup/) | Stable
| [Multicluster Mesh](/docs/setup/install/multicluster/) | Beta
| [External Control Plane](/docs/setup/additional-setup/external-controlplane/) | Alpha
| [Kubernetes: Istio Control Plane Upgrade](/docs/setup/upgrade/) | Beta
| Basic Configuration Resource Validation | Beta
| [Istio CNI plugin](/docs/setup/additional-setup/cni/) | Alpha
| IPv6 Support for Kubernetes | Alpha. Dual-stack IPv4 and IPv6 is not supported.
| [Distroless Base Images for Istio](/docs/ops/configuration/security/harden-docker-images/) | Alpha
| [Virtual Machine Integration](/docs/setup/install/virtual-machine/) | Beta
| [Helm Based Installation](/docs/setup/install/helm/) | Alpha

{{< idea >}}
Please get in touch by joining our [community](/about/community/) if there are features you'd like to see in our future releases!
{{< /idea >}}
