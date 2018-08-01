---
title: Feature Status
description: List of features and their release stages.
weight: 10
aliases:
    - /docs/reference/release-roadmap.html
    - /docs/reference/feature-stages.html
    - /docs/welcome/feature-stages.html
    - /docs/home/roadmap.html
page_icon: /img/feature-status.svg
---

This page lists the relative maturity and support
level of every Istio feature. Please note that the phases (Alpha, Beta, and Stable) are applied to individual features
within the project, not to the project as a whole. Here is a high level description of what these labels means:

## Feature phase definitions

|            | Alpha      | Beta         | Stable
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations     | Usable in production, not a toy anymore         | Dependable, production hardened
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production-worthy. APIs are versioned, with automated version conversion for backward compatibility
|  **Performance**         | Not quantified or guaranteed     | Not quantified or guaranteed         | Performance (latency/scale) is quantified, documented, with guarantees against regression
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm. 1 year notice will be provided before changes

## Istio features

Below is our list of existing features and their current phases. This information will be updated after every monthly release.

### Traffic Management

| Feature           | Phase
|-------------------|-------------------
| Protocols: HTTP1.1 / HTTP2 / gRPC / TCP | Stable
| Protocols: Websockets / MongoDB  | Beta
| Traffic Control: label/content based routing, traffic shifting | Beta
| Resilience features: timeouts, retries, connection pools, outlier detection | Beta
| Gateway: Ingress, Egress for all protocols | Beta
| TLS termination and SNI Support in Gateways | Beta
| Enabling custom filters in Envoy | Alpha

### Telemetry

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration](/docs/tasks/telemetry/querying-metrics/) | Stable
| [Local Logging (STDIO)](/docs/examples/telemetry/) | Stable
| [Statsd Integration](/docs/reference/config/policy-and-telemetry/adapters/statsd/) | Stable
| [Client and Server Telemetry Reporting](/docs/concepts/policies-and-telemetry/) | Stable
| [Service Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Istio Component Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Stackdriver Integration](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Alpha
| [SolarWinds Integration](/docs/reference/config/policy-and-telemetry/adapters/solarwinds/) | Alpha
| [Service Graph](/docs/tasks/telemetry/servicegraph/) | Alpha
| [Distributed Tracing to Zipkin / Jaeger](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Service Tracing](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Logging with Fluentd](/docs/tasks/telemetry/fluentd/) | Alpha
| Trace Sampling | Alpha

### Security and Policy Enforcement

| Feature           | Phase
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [Pluggable Key/Cert Support for Istio CA](/docs/tasks/security/plugin-ca-cert/)        | Stable
| [Service-to-service mutual TLS](/docs/concepts/security/#mutual-tls-authentication)         | Stable
| [Kubernetes: Service Credential Distribution](/docs/concepts/security/#mutual-tls-authentication)   | Stable
| [VM: Service Credential Distribution](/docs/concepts/security/#pki)         | Beta
| [Mutual TLS Migration](/docs/tasks/security/mtls-migration)    | Beta
| [Authentication policy](/docs/concepts/security/#authentication-policies)  | Alpha
| [End User (JWT) Authentication](/docs/concepts/security/#authentication)  | Alpha
| [OPA Checker](/docs/reference/config/policy-and-telemetry/adapters/opa/)    | Alpha
| [Authorization (RBAC)](/docs/concepts/security/#authorization)   | Alpha

### Core

| Feature           | Phase
|-------------------|-------------------
| [Kubernetes: Envoy Installation and Traffic Interception](/docs/setup/kubernetes/)        | Stable
| [Kubernetes: Istio Control Plane Installation](/docs/setup/kubernetes/) | Stable
| [Attribute Expression Language](/docs/reference/config/policy-and-telemetry/expression-language/)        | Stable
| [Mixer Adapter Authoring Model](/blog/2017/adapter-model/)        | Stable
| [Helm](/docs/setup/kubernetes/helm-install/) | Beta
| [Multicluster Mesh](/docs/setup/kubernetes/multicluster-install/) | Beta
| [Kubernetes: Istio Control Plane Upgrade](/docs/setup/kubernetes/) | Beta
| [Consul Integration](/docs/setup/consul/quick-start/) | Alpha
| [Cloud Foundry Integration](/docs/setup/consul/quick-start/)    | Alpha
| Basic Configuration Resource Validation | Alpha
| [Mixer Self Monitoring](/help/faq/mixer/#mixer-self-monitoring) | Alpha
| [Custom Mixer Build Model](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) | Alpha
| [Out of Process Mixer Adapters (GRPC Adapters)](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide) | Alpha

> {{< idea_icon >}}
Please get in touch by joining our [community](/about/community/) if there are features you'd like to see in our future releases!
