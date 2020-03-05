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

<!--
Note: this contains feature status from
https://docs.google.com/spreadsheets/d/1Nbjat-juyQ8AWhkq3njLckmHM8TRL4O-sjm9Bfr9zrU/edit#gid=0
-->

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
| [Locality load balancing](/docs/ops/configuration/traffic-management/locality-load-balancing/) | Beta
| Enabling custom filters in Envoy | Alpha
| CNI container interface | Alpha
| [Sidecar API](/docs/reference/config/networking/sidecar/) | Beta

### Observability

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration](/docs/tasks/observability/metrics/querying-metrics/) | Stable
| [Local Logging (STDIO)](/docs/tasks/observability/mixer/logs/collecting-logs/) | Stable
| [Statsd Integration](/docs/reference/config/policy-and-telemetry/adapters/statsd/) | Stable
| [Client and Server Telemetry Reporting](/docs/reference/config/policy-and-telemetry/) | Stable
| [Service Dashboard in Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/) | Stable
| [Istio Component Dashboard in Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/) | Stable
| [Distributed Tracing](/docs/tasks/observability/distributed-tracing/) | Stable
| [Stackdriver Integration](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Beta
| [Distributed Tracing to Zipkin / Jaeger](/docs/tasks/observability/distributed-tracing/) | Beta
| [Logging with Fluentd](/docs/tasks/observability/mixer/logs/fluentd/) | Beta
| [Trace Sampling](/docs/tasks/observability/distributed-tracing/overview/#trace-sampling) | Beta

### Security and policy enforcement

| Feature           | Phase
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [Pluggable Key/Cert Support for Istio CA](/docs/tasks/security/plugin-ca-cert/)        | Stable
| [Service-to-service mutual TLS](/docs/concepts/security/#mutual-tls-authentication)         | Stable
| [Kubernetes: Service Credential Distribution](/docs/concepts/security/#pki)   | Stable
| [VM: Service Credential Distribution](/docs/concepts/security/#pki)         | Beta
| [Mutual TLS Migration](/docs/tasks/security/authentication/mtls-migration)    | Beta
| [Cert management on Ingress Gateway](/docs/tasks/traffic-management/ingress/secure-ingress-sds) | Beta
| [Authorization](/docs/concepts/security/#authorization)   | Beta
| [End User (JWT) Authentication](/docs/concepts/security/#authentication)  | Alpha
| [OPA Checker](/docs/reference/config/policy-and-telemetry/adapters/opa/)    | Alpha

### Core

| Feature           | Phase
|-------------------|-------------------
| [Standalone Operator](/docs/setup/install/standalone-operator/) | Alpha
| [Kubernetes: Envoy Installation and Traffic Interception](/docs/setup/) | Stable
| [Kubernetes: Istio Control Plane Installation](/docs/setup/) | Stable
| [Attribute Expression Language](/docs/reference/config/policy-and-telemetry/expression-language/) | Stable
| Mixer Out-of-Process Adapter Authoring Model | Beta
| [Helm](/docs/setup/install/helm/) | Beta
| [Multicluster Mesh over VPN](/docs/setup/install/multicluster/) | Alpha
| [Kubernetes: Istio Control Plane Upgrade](/docs/setup/) | Beta
| Consul Integration | Alpha
| Basic Configuration Resource Validation | Beta
| Configuration Processing with Galley | Beta
| [Mixer Self Monitoring](/faq/mixer/#mixer-self-monitoring) | Beta
| [Custom Mixer Build Model](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) | deprecated
| [Out of Process Mixer Adapters (gRPC Adapters)](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide) | Beta
| [Istio CNI plugin](/docs/setup/additional-setup/cni/) | Alpha
| IPv6 support for Kubernetes | Alpha
| [Distroless base images for Istio](/docs/ops/configuration/security/harden-docker-images/) | Alpha

{{< idea >}}
Please get in touch by joining our [community](/about/community/) if there are features you'd like to see in our future releases!
{{< /idea >}}
