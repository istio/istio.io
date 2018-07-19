---
title: Feature Status
description: List of features and their release stages.
weight: 10
aliases:
    - /docs/reference/release-roadmap.html
    - /docs/reference/feature-stages.html
    - /docs/welcome/feature-stages.html
    - /docs/home/roadmap.html
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

### Traffic management

| Feature           | Phase
|-------------------|-------------------
| [Protocols: HTTP 1.1](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http_connection_management.html#http-protocols)  | Beta
| [Protocols: HTTP 2.0](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http_connection_management.html#http-protocols)  | Alpha
| [Protocols: gRPC](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/grpc)   | Alpha
| [Protocols: MongoDB](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/mongo)      | Alpha
| [Request Routing](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Fault Injection](/docs/tasks/traffic-management/fault-injection/)      | Alpha
| [Traffic Shifting](/docs/tasks/traffic-management/traffic-shifting/)      | Alpha
| [Circuit Break](/docs/tasks/traffic-management/circuit-breaking/)      | Alpha
| [Mirroring](/docs/tasks/traffic-management/mirroring/)      | Alpha
| [Ingress Traffic](/docs/tasks/traffic-management/ingress/)      | Alpha
| [Egress Traffic](/docs/tasks/traffic-management/egress/)      | Alpha
| [Egress TCP Traffic](/blog/2018/egress-tcp/)      | Alpha
| [Improved Routing Rules: Composite Service](/docs/reference/config/istio.networking.v1alpha3/) | Alpha
| [Quota / Redis Rate Limiting (Adapter and Server)](/docs/tasks/policy-enforcement/rate-limiting/) | Alpha
| [Memquota Implementation and Integration](/docs/tasks/telemetry/metrics-logs/) | Stable
| [Ingress TLS](/docs/tasks/traffic-management/ingress/) | Alpha
| Egress Policy and Telemetry | Alpha

### Observability

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration](/docs/tasks/telemetry/querying-metrics/) | Stable
| [Local Logging (STDIO)](/docs/examples/telemetry/) | Stable
| [Statsd Integration](/docs/reference/config/policy-and-telemetry/adapters/statsd/) | Stable
| [Service Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Stackdriver Integration](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Alpha
| [SolarWinds Integration](/docs/reference/config/policy-and-telemetry/adapters/solarwinds/) | Alpha
| [Service Graph](/docs/tasks/telemetry/servicegraph/) | Alpha
| [Distributed Tracing to Zipkin / Jaeger](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Istio Component Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Service Tracing](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Logging with Fluentd](/docs/tasks/telemetry/fluentd/) | Alpha
| [Client and Server Telemetry Reporting](/docs/concepts/policies-and-telemetry/) | Stable

### Security

| Feature           | Phase
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [Kubernetes: Service Credential Distribution](/docs/concepts/security/#mutual-tls-authentication)   | Stable
| [Pluggable Key/Cert Support for Istio CA](/docs/tasks/security/plugin-ca-cert/)        | Stable
| [Service-to-service mutual TLS](/docs/concepts/security/#mutual-tls-authentication)         | Stable
| [Authentication policy](/docs/concepts/security/#anatomy-of-an-authentication-policy)  | Alpha
| [VM: Service Credential Distribution](/docs/concepts/security/#key-management)         | Beta
| [Incremental mTLS](/docs/tasks/security/mtls-migration)    | Beta
| [OPA Checker]({{< github_file >}}/mixer/adapter/opa/README.md)    | Alpha
| [Authorization (RBAC)](/docs/concepts/security/#authorization)   | Alpha

### Core

| Feature           | Phase
|-------------------|-------------------
| [Kubernetes: Envoy Installation and Traffic Interception](/docs/setup/kubernetes/)        | Beta
| [Kubernetes: Istio Control Plane Installation](/docs/setup/kubernetes/) | Beta
| [Kubernetes: Istio Control Plane Upgrade](/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Kubernetes Service Discovery](/docs/setup/kubernetes/)         | Stable
| [Attribute Expression Language](/docs/reference/config/policy-and-telemetry/expression-language/)        | Stable
| [Mixer Adapter Authoring Model](/blog/2017/adapter-model/)        | Stable
| [VM: Envoy Installation, Traffic Interception and Service Registration](/docs/examples/integrating-vms/)    | Alpha
| [VM: Istio Control Plane Installation and Upgrade (Galley, Mixer, Pilot, CA)](https://github.com/istio/istio/issues/2083)  | Alpha
| VM: Ansible Envoy Installation, Interception and Registration  | Alpha
| [Pilot Integration into Consul](/docs/setup/consul/quick-start/) | Alpha
| [Pilot Integration into Cloud Foundry Service Discovery](/docs/setup/consul/quick-start/)    | Alpha
| [Basic Config Resource Validation](https://github.com/istio/istio/issues/1894) | Alpha
| [Mixer Telemetry Collection (Tracing, Logging, Monitoring)](/help/faq/mixer/#mixer-self-monitoring) | Alpha
| [Custom Mixer Build Model](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) | Alpha
| [Out of Process Mixer Adapters](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide) | Alpha
| Enable API attributes using an IDL | Alpha
| [Helm](/docs/setup/kubernetes/helm-install/) | Beta
| [Multicluster Mesh](/docs/setup/kubernetes/multicluster-install/) | Alpha

> {{< idea_icon >}}
Please get in touch by joining our [community](/about/community/) if there are features you'd like to see in our future releases!
