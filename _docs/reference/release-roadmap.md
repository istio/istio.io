---
title: Feature Status
overview: List of features and their stages.

order: 60

layout: docs
type: markdown
---

We have made some changes to Istio release model. Starting 0.3.0, the releases will be drively by monthly schedule. Going forward, you can expect a new release between 15th to 25th of every month. You can download the current version by visiting https://github.com/istio/istio/releases.

Each individual feature will go through the Alpha, Beta, and Stable phases. Please note that the stages are applied to individual features within the product, not to the product as a whole. Here is a high level description of what these labels means:

## Feature Phase Definition

|            | Alpha      | Beta         | Stable     
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations     | Usable in production, not a toy anymore         | Dependable, production hardened      
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production worthy. APIs are versioned, with automated version conversion for back compat  
|  **Performance**         | Random     | Random         | Perf (latency/scale) is quantified, documented, with guarantees against regression. 
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm 1 year  


## Istio Features (as of 0.3.0)
Here is the map of our existing features and their phases. This information will be updated after every monthly release.

### Config /APIs


| Feature           | Phase      
|-------------------|-------------------
| [Mesh-wide Settings](https://istio.io/docs/reference/config/service-mesh.html) | Alpha
| [Basic config validation](https://github.com/istio/istio/issues/1894)    | Alpha
| [Ingress Controller](https://istio.io/docs/tasks/traffic-management/ingress.html)         | Alpha
| [Basic Egress](https://istio.io/docs/tasks/traffic-management/egress.html)               | Alpha
| [Protocols HTTP 1.1](https://github.com/istio/istio/blob/master/pilot/model/service.go#L104)         | Beta
| [Protocols HTTP 2.0](https://github.com/istio/istio/blob/master/pilot/model/service.go#L101)        | Alpha
| [Protocols gRPC](https://github.com/istio/istio/blob/master/pilot/model/service.go#L97)     		   | Alpha
| [Protocols TCP](https://github.com/istio/istio/blob/master/pilot/model/service.go#L107)         	   | Alpha
| [Protocols: WebSocket](https://github.com/istio/istio/blob/master/pilot/proxy/envoy/testdata/websocket-route.yaml.golden)       | Alpha
| [Protocols: MongoDB](https://github.com/istio/istio/blob/master/pilot/model/service.go#L134)         | Alpha
| [Basic Routing Rules](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
| [Distributed Tracing Zipkin / Jaeger](https://istio.io/docs/tasks/telemetry/distributed-tracing.html)        | Beta
| [Istioctl CLI](https://istio.io/docs/reference/commands/istioctl.html)        | Alpha

### Integrations


| Feature           | Phase      
|-------------------|-------------------
| [Mixer Adapter Authoring Model](https://github.com/istio/istio/blob/master/mixer/doc/adapters.md) | Alpha
| [Mixer Configuration Model](https://istio.io/docs/concepts/policy-and-control/mixer-config.html)    | Alpha
| [Prometheus Adapter](https://istio.io/docs/guides/telemetry.html)         | Beta
| [Local Logging Adapter (STDIO, File)](https://istio.io/docs/guides/telemetry.html)               | Beta
| [Deny Adapter](https://istio.io/docs/reference/config/mixer/adapters/denier.html)         | Beta
| [ListCheck Adapter](https://istio.io/docs/reference/config/mixer/adapters/list.html)        | Beta
| [Kubernetes Attributes Adapter](https://istio.io/docs/reference/config/mixer/adapters/kubernetes.html)     		   | Alpha
| [Statsd Adapter](https://istio.io/docs/reference/config/mixer/adapters/statsd.html)         	   | Beta
| [Tracing Adapter](https://github.com/istio/old_mixer_repo/issues/797)       | Alpha
| [Mixer Telemetry Collection](https://github.com/istio/old_mixer_repo/issues/63)         | Alpha
| [Support for Mixer in Envoy (Mixer Client Library)](https://github.com/istio/mixerclient)      | Alpha

### Environments


| Feature           | Phase        
|-------------------|-------------------
| [VM: Basic Envoy Installation, Interception and Registration for VMs](https://istio.io/docs/guides/integrating-vms.html) | Alpha
| [Kubernetes: Istio Installation](https://istio.io/docs/setup/kubernetes/)    | Alpha
| [Kubernetes: Envoy Installation](https://goo.gl/jhng56)               | Alpha
| [Kubernetes: Pilot supports K8s Service Discovery](https://istio.io/docs/setup/kubernetes/)         | Alpha
| [Kubernetes: Traffic Interception](https://istio.io/docs/setup/kubernetes/)        | Beta
| [Integration into Consul Service Discovery](https://istio.io/docs/setup/consul/quick-start.html)     		   | Alpha
| [Bring your own service name/DNS](https://docs.google.com/document/d/1If-t_g7CZnRX_dc0NG4y6CRGoI5FhkgUCqnNmPt9eFY/edit)         	   | Alpha


### Security


| Feature           | Phase        
|-------------------|-------------------
| [Istio on Istio (secure istio components)](https://docs.google.com/document/d/1YzYPddihbLgJhme27-md9COn0NnKUKX_xCJ_GPXU4Fw/edit#heading=h.jbmfrt4h5lj0) | Alpha
| [Incremental mTLS](https://docs.google.com/document/d/1D7wZCQjVB72Wlwr5ZxP5WUmn3FUDr-XzfX8OodPXe8Y/edit)    | Alpha
| [VM Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)         | Alpha
| [Kubernetes Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)               | Beta
| [Istio mTLS](https://istio.io/docs/concepts/security/mutual-tls.html)         | Beta
| [Pluggable Key/Cert Support for Istio CA](https://istio.io/docs/tasks/security/plugin-ca-cert.html)        | Beta

### User Interface


| Feature           | Phase       
|-------------------|-------------------
| [Grafana Dashboard](https://istio.io/docs/tasks/telemetry/using-istio-dashboard.html) | Alpha
| [Service Graph](https://istio.io/docs/tasks/telemetry/servicegraph.html)    | Alpha


### Performance and Scalability


| Feature           | Phase       
|-------------------|-------------------
| [Initial scenarios, manual baseline](https://docs.google.com/document/d/1LG5sZRwjL5l8h2e9dCbai27yr9gVezzsrJaHT6mICiM/edit#) | Alpha
| [Reproducible oss characterization tool (Fortio)](https://github.com/istio/fortio/issues)    | Alpha
| [Mixer bottom up perf](https://github.com/istio/old_mixer_repo/issues/1472)    | Alpha

Please get in touch if there are features you'd like to see in our future releases!
