---
title: Feature Status
description: List of features and their release stages.
weight: 10
redirect_from:
  - /docs/reference/release-roadmap.html
  - /docs/reference/feature-stages.html
  - /docs/welcome/feature-stages.html
---
{% include home.html %}

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
| [Routing Rules: Retry]({{home}}/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Timeout]({{home}}/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Circuit Break]({{home}}/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Header Rewrite]({{home}}/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Traffic Splitting]({{home}}/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Improved Routing Rules: Composite Service]({{home}}/docs/reference/config/istio.networking.v1alpha3.html) | Alpha
| [Quota / Redis Rate Limiting (Adapter and Server)]({{home}}/docs/tasks/policy-enforcement/rate-limiting.html) | Alpha
| [Memquota Implementation and Integration]({{home}}/docs/tasks/telemetry/metrics-logs.html) | Stable
| [Ingress TLS]({{home}}/docs/tasks/traffic-management/ingress.html) | Alpha
| Egress Policy and Telemetry | Alpha

### Observability

| Feature           | Phase
|-------------------|-------------------
| [Prometheus Integration]({{home}}/docs/guides/telemetry.html) | Beta
| [Local Logging (STDIO)]({{home}}/docs/guides/telemetry.html) | Stable
| [Statsd Integration]({{home}}/docs/reference/config/policy-and-telemetry/adapters/statsd.html) | Stable
| [Service Dashboard in Grafana]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html) | Beta
| [Stackdriver Integration]({{home}}/docs/reference/config/policy-and-telemetry/adapters/stackdriver.html) | Alpha
| [Service Graph]({{home}}/docs/tasks/telemetry/servicegraph.html) | Alpha
| [Distributed Tracing to Zipkin / Jaeger]({{home}}/docs/tasks/telemetry/distributed-tracing.html) | Alpha
| [Istio Component Dashboard in Grafana]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html) | Beta
| [Service Tracing]({{home}}/docs/tasks/telemetry/distributed-tracing.html) | Alpha

### Security

| Feature           | Phase
|-------------------|-------------------
| [Deny Checker]({{home}}/docs/reference/config/policy-and-telemetry/adapters/denier.html)         | Stable
| [List Checker]({{home}}/docs/reference/config/policy-and-telemetry/adapters/list.html)        | Stable
| [Kubernetes: Service Credential Distribution]({{home}}/docs/concepts/security/mutual-tls.html)   | Stable
| [Pluggable Key/Cert Support for Istio CA]({{home}}/docs/tasks/security/plugin-ca-cert.html)        | Stable
| [Service-to-service mutual TLS]({{home}}/docs/concepts/security/mutual-tls.html)         | Stable
| [Incremental Enablement of service-to-service mutual TLS]({{home}}/docs/tasks/security/per-service-mtls.html)  | Alpha
| [VM: Service Credential Distribution]({{home}}/docs/concepts/security/mutual-tls.html)         | Alpha
| [OPA Checker](https://github.com/istio/istio/blob/41a8aa4f75f31bf0c1911d844a18da4cff8ac584/mixer/adapter/opa/README.md)    | Alpha
| RBAC Mixer Adapter     | Alpha
| [API Keys]({{home}}/docs/reference/config/policy-and-telemetry/templates/apikey.html) | Alpha

### Core

| Feature           | Phase
|-------------------|-------------------
| [Kubernetes: Envoy Installation and Traffic Interception]({{home}}/docs/setup/kubernetes/)        | Beta
| [Kubernetes: Istio Control Plane Installation]({{home}}/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Kubernetes Service Discovery]({{home}}/docs/setup/kubernetes/)         | Stable
| [Attribute Expression Language]({{home}}/docs/reference/config/policy-and-telemetry/expression-language.html)        | Stable
| [Mixer Adapter Authoring Model]({{home}}/blog/2017/adapter-model.html)        | Stable
| [VM: Envoy Installation, Traffic Interception and Service Registration]({{home}}/docs/guides/integrating-vms.html)    | Alpha
| [VM: Istio Control Plane Installation and Upgrade (Galley, Mixer, Pilot, CA)](https://github.com/istio/istio/issues/2083)  | Alpha
| VM: Ansible Envoy Installation, Interception and Registration  | Alpha
| [Kubernetes: Istio Control Plane Upgrade]({{home}}/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Consul]({{home}}/docs/setup/consul/quick-start.html) | Alpha
| [Pilot Integration into Eureka]({{home}}/docs/setup/consul/quick-start.html) | Alpha
| [Pilot Integration into Cloud Foundry Service Discovery]({{home}}/docs/setup/consul/quick-start.html)    | Alpha
| [Basic Config Resource Validation](https://github.com/istio/istio/issues/1894) | Alpha
| Mixer Telemetry Collection (Tracing, Logging, Monitoring) | Alpha
| [Custom Mixer Build Model](https://github.com/istio/istio/wiki/Mixer-Adapter-Dev-Guide) | Alpha
| Enable API attributes using an IDL | Alpha
| [Helm]({{home}}/docs/setup/kubernetes/helm-install.html) | Alpha
| [Multicluster Mesh]({{home}}/docs/setup/kubernetes/multicluster-install.html) | Alpha

> <img src="{{home}}/img/bulb.svg" alt="Bulb" title="Help" style="width: 32px; display:inline" />
Please get in touch by joining our [community]({{home}}/community.html) if there are features you'd like to see in our future releases!
