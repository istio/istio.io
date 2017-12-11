---
title: Feature Status
overview: List of features and their release stages.

order: 10

layout: docs
type: markdown
redirect_from: "/docs/reference/release-roadmap.html"
---
{% include home.html %}

We have made changes to Istio's release model. Starting with 0.3.0, releases will be delivered on a monthly cadence. Going forward, 
you can expect a new release towards the end of every month. You can download the current version by visiting our
[release page](https://github.com/istio/istio/releases).

Each individual feature will go through the Alpha, Beta, and Stable phases. Please note that the phases are applied to individual features
within the product, not to the product as a whole. Here is a high level description of what these labels means:

## Feature Phase Definition

|            | Alpha      | Beta         | Stable     
|-------------------|-------------------|-------------------|-------------------
|   **Purpose**         | Demo-able, works end-to-end but has limitations     | Usable in production, not a toy anymore         | Dependable, production hardened      
|   **API**         | No guarantees on backward compatibility    | APIs are versioned         | Dependable, production worthy. APIs are versioned, with automated version conversion for backward compatibility
|  **Performance**         | Random     | Random         | Perf (latency/scale) is quantified, documented, with guarantees against regression 
|   **Deprecation Policy**        | None     | Weak - 3 months         | Dependable,  Firm 1 year  

## Istio 0.3.0 features status

Below is our list of existing features and their current phases. This information will be updated after every monthly release.

### Networking

| Feature           | Phase      
|-------------------|-------------------
| [Kubernetes Ingress](https://istio.io/docs/tasks/traffic-management/ingress.html)         | Alpha
| [Egress Rules](https://istio.io/docs/tasks/traffic-management/egress.html)               | Alpha
| [Protocols HTTP/1.1 & HTTP2](https://github.com/istio/istio/blob/master/pilot/model/service.go#L104)         | Beta
| [Protocols gRPC](https://github.com/istio/istio/blob/master/pilot/model/service.go#L97)     		   | Beta
| [Protocols TCP](https://github.com/istio/istio/blob/master/pilot/model/service.go#L107)         	   | Beta
| [Protocols: WebSocket](https://github.com/istio/istio/blob/master/pilot/proxy/envoy/testdata/websocket-route.yaml.golden)       | Alpha
| [Protocols: MongoDB](https://github.com/istio/istio/blob/master/pilot/model/service.go#L134)         | Alpha
| [Traffic Routing Rules](https://istio.io/docs/tasks/traffic-management/request-routing.html)      | Alpha
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
| [Kubernetes Integration](https://istio.io/docs/setup/kubernetes/)    | Alpha
| [Nomad/Consul Integration](https://istio.io/docs/setup/consul/quick-start.html)     		   | Alpha
| [Mesh Expansion (from Kubernetes into VMs)](https://istio.io/docs/guides/integrating-vms.html) | Alpha


### Security


| Feature           | Phase        
|-------------------|-------------------
| [Istio on Istio (secure istio components)](https://docs.google.com/document/d/1YzYPddihbLgJhme27-md9COn0NnKUKX_xCJ_GPXU4Fw/edit#heading=h.jbmfrt4h5lj0) | Alpha
| [Incremental mTLS](https://docs.google.com/document/d/1D7wZCQjVB72Wlwr5ZxP5WUmn3FUDr-XzfX8OodPXe8Y/edit)    | Alpha
| [VM Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)         | Alpha
| [Kubernetes Credential Distribution](https://istio.io/docs/concepts/security/mutual-tls.html)               | Beta
| [Istio mTLS](https://istio.io/docs/concepts/security/mutual-tls.html)         | Beta
| [Pluggable Key/Cert Support for Istio CA](https://istio.io/docs/tasks/security/plugin-ca-cert.html)        | Beta

Please get in touch by joining our [community]({{home}}/community) if there are features you'd like to see in our future releases!
