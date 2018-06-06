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
| [Protocols: TCP](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/tcp_proxy)    | Alpha
| [Protocols: WebSocket](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/websocket)      | Alpha
| [Protocols: MongoDB](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/mongo)      | Alpha
| [Routing Rules: Retry](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Routing Rules: Timeout](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Routing Rules: Circuit Break](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Routing Rules: Header Rewrite](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Routing Rules: Traffic Splitting](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [Improved Routing Rules: Composite Service](/docs/reference/config/istio.networking.v1alpha3/) | Alpha
| [Quota / Redis Rate Limiting (Adapter and Server)](/docs/tasks/policy-enforcement/rate-limiting/) | Alpha
| [Memquota Implementation and Integration](/docs/tasks/telemetry/metrics-logs/) | Stable
| [Ingress TLS](/docs/tasks/traffic-management/ingress/) | Alpha
| Egress Policy and Telemetry | Alpha

### Observability

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration](/docs/guides/telemetry/) | Beta
| [Local Logging (STDIO)](/docs/guides/telemetry/) | Stable
| [Statsd Integration](/docs/reference/config/policy-and-telemetry/adapters/statsd/) | Stable
| [Service Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Stackdriver Integration](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Alpha
| [Service Graph](/docs/tasks/telemetry/servicegraph/) | Alpha
| [Distributed Tracing to Zipkin / Jaeger](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Istio Component Dashboard in Grafana](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Service Tracing](/docs/tasks/telemetry/distributed-tracing/) | Alpha

### Security

| Feature           | Phase
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [Kubernetes: Service Credential Distribution](/docs/concepts/security/mutual-tls/)   | Stable
| [Pluggable Key/Cert Support for Istio CA](/docs/tasks/security/plugin-ca-cert/)        | Stable
| [Service-to-service mutual TLS](/docs/concepts/security/mutual-tls/)         | Stable
| [Authentication policy](/docs/concepts/security/authn-policy/)  | Alpha
| [VM: Service Credential Distribution](/docs/concepts/security/mutual-tls/)         | Alpha
| [OPA Checker](https://github.com/istio/istio/blob/{{<branch_name>}}/mixer/adapter/opa/README.md)    | Alpha
| RBAC Mixer Adapter     | Alpha
| [API Keys](/docs/reference/config/policy-and-telemetry/templates/apikey/) | Alpha

### Core

| Feature           | Phase
|-------------------|-------------------
| [Kubernetes: Envoy Installation and Traffic Interception](/docs/setup/kubernetes/)        | Beta
| [Kubernetes: Istio Control Plane Installation](/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Kubernetes Service Discovery](/docs/setup/kubernetes/)         | Stable
| [Attribute Expression Language](/docs/reference/config/policy-and-telemetry/expression-language/)        | Stable
| [Mixer Adapter Authoring Model](/blog/2017/adapter-model/)        | Stable
| [VM: Envoy Installation, Traffic Interception and Service Registration](/docs/guides/integrating-vms/)    | Alpha
| [VM: Istio Control Plane Installation and Upgrade (Galley, Mixer, Pilot, CA)](https://github.com/istio/istio/issues/2083)  | Alpha
| VM: Ansible Envoy Installation, Interception and Registration  | Alpha
| [Kubernetes: Istio Control Plane Upgrade](/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Consul](/docs/setup/consul/quick-start/) | Alpha
| [Pilot Integration into Eureka](/docs/setup/consul/quick-start/) | Alpha
| [Pilot Integration into Cloud Foundry Service Discovery](/docs/setup/consul/quick-start/)    | Alpha
| [Basic Config Resource Validation](https://github.com/istio/istio/issues/1894) | Alpha
| Mixer Telemetry Collection (Tracing, Logging, Monitoring) | Alpha
| [Custom Mixer Build Model](https://github.com/istio/istio/wiki/Mixer-Adapter-Dev-Guide) | Alpha
| Enable API attributes using an IDL | Alpha
| [Helm](/docs/setup/kubernetes/helm-install/) | Alpha
| [Multicluster Mesh](/docs/setup/kubernetes/multicluster-install/) | Alpha

> {{< idea_icon >}}
Please get in touch by joining our [community](/community/) if there are features you'd like to see in our future releases!
