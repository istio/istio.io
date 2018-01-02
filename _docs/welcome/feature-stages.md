---
title: Feature Status
overview: List of features and their release stages.

order: 10

layout: docs
type: markdown
redirect_from:
  - "/docs/reference/release-roadmap.html"
  - "/docs/reference/feature-stages.html"
draft: true
---
{% include home.html %}

Starting with 0.3, Istio releases are delivered on a monthly cadence. You can download the current version by visiting our
[release page](https://github.com/istio/istio/releases). 

Please note that the phases (alpha, beta, and stable) are applied to individual features
within the product, not to the product as a whole. Here is a high level description of what these labels means:

## Feature Phase Definition

|            | Alpha      | Beta         | Stable     
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations     | Usable in production, not a toy anymore         | Dependable, production hardened      
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production-worthy. APIs are versioned, with automated version conversion for backward compatibility
|  **Performance**         | Not quantified or guaranteed     | Not quantified or guaranteed         | Perf (latency/scale) is quantified, documented, with guarantees against regression 
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm. 1 year notice will be provided before changes

## Istio 0.4 Features

Below is our list of existing features and their current phases. This information will be updated after every monthly release.

### Traffic Management

| Feature           | Phase      
|-------------------|-------------------
| [Memquota Implementation and Integration](https://istio.io/docs/tasks/telemetry/metrics-logs.html) - **New to 0.4** | Beta
| [Protocols: HTTP 1.1](https://github.com/istio/istio/blob/master/pilot/model/service.go#L104)  | Beta
| [Protocols: HTTP 2.0](https://github.com/istio/istio/blob/master/pilot/model/service.go#L101)  | Alpha
| [Protocols: gRPC](https://github.com/istio/istio/blob/master/pilot/model/service.go#L97)    | Alpha
| [Protocols: TCP](https://github.com/istio/istio/blob/master/pilot/model/service.go#L107)     | Alpha
| [Protocols: WebSocket](https://github.com/istio/istio/blob/master/pilot/proxy/envoy/testdata/websocket-route.yaml.golden)       | Alpha
| [Protocols: MongoDB](https://github.com/istio/istio/blob/master/pilot/model/service.go#L134)         | Alpha
| [Routing Rules: Retries](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Timeout](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Circuit Break](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Header Rewrite](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Routing Rules: Traffic Splitting](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| Bring your own service name / custom service names   - **New to 0.4**   | Alpha

### Observability


| Feature           | Phase      
|-------------------|-------------------
| [Local Logging (STDIO)](https://istio.io/docs/guides/telemetry.html)               | Beta
| [Statsd Integration](https://istio.io/docs/reference/config/mixer/adapters/statsd.html)         	   | Beta
| [Service Dashboard in Grafana](https://istio.io/docs/tasks/telemetry/using-istio-dashboard.html)       | Beta
| [Prometheus Integration](https://istio.io/docs/guides/telemetry.html)         | Alpha
| [Stackdriver Integration](https://istio.io/docs/reference/config/mixer/adapters/stackdriver.html)       | Alpha
| [Service Graph](https://istio.io/docs/tasks/telemetry/servicegraph.html)       | Alpha


### Security


| Feature           | Phase        
|-------------------|-------------------
| [Deny Checker](https://istio.io/docs/reference/config/mixer/adapters/denier.html)         | Beta
| [List Checker](https://istio.io/docs/reference/config/mixer/adapters/list.html)        | Beta
| [Kubernetes: Service Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)               | Beta
| [Pluggable Key/Cert Support for Istio CA](https://istio.io/docs/tasks/security/plugin-ca-cert.html)        | Beta
| [Service-to-service mutual TLS](https://istio.io/docs/concepts/security/mutual-tls.html)         | Beta
| [Incremental Enablement of service-to-service mutual TLS](https://docs.google.com/document/d/1D7wZCQjVB72Wlwr5ZxP5WUmn3FUDr-XzfX8OodPXe8Y/edit)    | Alpha
| [VM: Service Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)         | Alpha
| OPA Checker  - **New to 0.4**      | Alpha 



### Core


| Feature           | Phase        
|-------------------|-------------------
| [Kubernetes: Istio Data Plane: Envoy Installation and Traffic Interception](https://istio.io/docs/setup/kubernetes/)        | Beta
| [Kubernetes: Istio Control Plane Installation and Upgrade](https://istio.io/docs/setup/kubernetes/) | Beta
| [Pilot Integration into Kubernetes Service Discovery](https://istio.io/docs/setup/kubernetes/)         | Beta
| [VM: Istio Data Plane: Envoy Installation, Traffic Interception and Service Registration](https://istio.io/docs/guides/integrating-vms.html)    | Alpha
| [VM: Istio Control Plane: Installation and Upgrade (Galley, Mixer, Pilot, CA)](https://github.com/istio/istio/issues/2083)  | Alpha
| [Pilot Integration into Consul, Eureka and Cloud Foundry Service Discovery](https://istio.io/docs/setup/consul/quick-start.html)     		   | Alpha
| [Basic Config Resource Validation](https://github.com/istio/istio/issues/1894)         	   | Alpha
| [Distributed Tracing to Zipkin / Jaeger](https://istio.io/docs/tasks/telemetry/distributed-tracing.html)         | Alpha
| Logging, Monitoring, and Tracing of Istio components         | Alpha
| Attribute Expression Language        | Alpha
| Mixer Plugin Model        | Alpha



Please get in touch by joining our [community]({{home}}/community) if there are features you'd like to see in our future releases!
