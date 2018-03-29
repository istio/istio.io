---
title: Feature Status
overview: List of features and their release stages.

order: 10

layout: about
type: markdown
redirect_from:
  - "/docs/reference/release-roadmap.html"
  - "/docs/reference/feature-stages.html"
  - "/docs/welcome/feature-stages.html"
---
{% include home.html %}

This page lists the relative maturity and support
level of every Istio feature. Please note that the phases (Alpha, Beta, and Stable) are applied to individual features
within the project, not to the project as a whole. Here is a high level description of what these labels means:

## Feature Phase Definition

|            | Alpha      | Beta         | Stable     
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations     | Usable in production, not a toy anymore         | Dependable, production hardened      
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production-worthy. APIs are versioned, with automated version conversion for backward compatibility
|  **Performance**         | Not quantified or guaranteed     | Not quantified or guaranteed         | Perf (latency/scale) is quantified, documented, with guarantees against regression 
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm. 1 year notice will be provided before changes

## Istio features

Below is our list of existing features and their current phases. This information will be updated after every monthly release.

### Traffic Management

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
| [Memquota Implementation and Integration]({{home}}/docs/tasks/telemetry/metrics-logs.html) | Alpha
| [Ingress TLS]({{home}}/docs/tasks/traffic-management/ingress.html) | Alpha

### Observability


| Feature           | Phase      
|-------------------|-------------------
| [Prometheus Integration]({{home}}/docs/guides/telemetry.html)         | Beta
| [Local Logging (STDIO)]({{home}}/docs/guides/telemetry.html)               | Beta
| [Statsd Integration]({{home}}/docs/reference/config/adapters/statsd.html)         	   | Stable
| [Service Dashboard in Grafana]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html)       | Beta
| [Stackdriver Integration]({{home}}/docs/reference/config/adapters/stackdriver.html)       | Alpha
| [Service Graph]({{home}}/docs/tasks/telemetry/servicegraph.html)       | Alpha
| [Distributed Tracing to Zipkin / Jaeger]({{home}}/docs/tasks/telemetry/distributed-tracing.html)         | Alpha
| [Istio Component Dashboard in Grafana]({{home}}/docs/tasks/telemetry/using-istio-dashboard.html)  - **New to 0.5** | Alpha


### Security


| Feature           | Phase        
|-------------------|-------------------
| [Deny Checker]({{home}}/docs/reference/config/adapters/denier.html)         | Beta
| [List Checker]({{home}}/docs/reference/config/adapters/list.html)        | Beta
| [Kubernetes: Service Credential Distribution]({{home}}/docs/concepts/security/mutual-tls.html)               | Beta
| [Pluggable Key/Cert Support for Istio CA]({{home}}/docs/tasks/security/plugin-ca-cert.html)        | Stable
| [Service-to-service mutual TLS]({{home}}/docs/concepts/security/mutual-tls.html)         | Beta
| [Incremental Enablement of service-to-service mutual TLS]({{home}}/docs/tasks/security/per-service-mtls.html)  | Alpha
| [VM: Service Credential Distribution]({{home}}/docs/concepts/security/mutual-tls.html)         | Alpha
| [OPA Checker](https://github.com/istio/istio/blob/41a8aa4f75f31bf0c1911d844a18da4cff8ac584/mixer/adapter/opa/README.md)    | Alpha



### Core


| Feature           | Phase        
|-------------------|-------------------
| [Kubernetes: Envoy Installation and Traffic Interception]({{home}}/docs/setup/kubernetes/)        | Beta
| [Kubernetes: Istio Control Plane Installation]({{home}}/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Kubernetes Service Discovery]({{home}}/docs/setup/kubernetes/)         | Stable
| [Attribute Expression Language]({{home}}/docs/reference/config/mixer/expression-language.html)        | Beta
| [Mixer Adapter Authoring Model]({{home}}/blog/2017/adapter-model.html)        | Beta
| [VM: Envoy Installation, Traffic Interception and Service Registration]({{home}}/docs/guides/integrating-vms.html)    | Alpha
| [VM: Istio Control Plane Installation and Upgrade (Galley, Mixer, Pilot, CA)](https://github.com/istio/istio/issues/2083)  | Alpha
| [Kubernetes: Istio Control Plane Upgrade]({{home}}/docs/setup/kubernetes/) | Alpha
| [Pilot Integration into Consul]({{home}}/docs/setup/consul/quick-start.html)     		   | Alpha
| [Pilot Integration into Eureka]({{home}}/docs/setup/consul/quick-start.html)     		   | Alpha
| [Pilot Integration into Cloud Foundry Service Discovery]({{home}}/docs/setup/consul/quick-start.html)    | Alpha
| [Basic Config Resource Validation](https://github.com/istio/istio/issues/1894)         	   | Alpha




> <img src="{{home}}/img/bulb.svg" alt="Bulb" title="Help" style="width: 32px; display:inline" />
Please get in touch by joining our [community]({{home}}/community.html) if there are features you'd like to see in our future releases!
