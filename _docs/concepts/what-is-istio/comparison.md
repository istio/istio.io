---
title: Istio vs. Other Software
overview: A comparison between Istio's and similar software.
              
order: 30

layout: docs
type: markdown
---

This page provides a comparison between Istio and similar software.

## Istio vs. Envoy

Envoy is one of the building blocks of Istio. In Istio, an Envoy instance is deployed as a sidecar to every running service. Together, this set of Envoy instances makes up the **data plane**.

Istio provides, amongst other things, several components which enable the data plane to retrieve and locally apply global policies (routing, load balancing, service discovery, etc.). Those components (the two main ones being [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Pilot]({{home}}/docs/concepts/traffic-management/pilot.html)) implement the Envoy [LDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/lds.proto), [CDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/cds.proto), [EDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/eds.proto), and [RDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/rds.proto) APIs, and they form the **control plane** of the service mesh.

For more detailed information about the data plane and the control plane, see the [Overview]({{home}}/docs/concepts/what-is-istio/overview.html) page.

## Istio vs. Linkerd

Similarly to Envoy, Linkerd is an intelligent proxy designed to be deployed as a sidecar to running applications. The set of Linkerd instances deployed accross a service mesh make up the **data plane**. Linkerd can be augmented with Namerd, a component enabling to centrally define policies (routing, load balancing, retries) which will be retrieved and applied locally by each individual Linkerd sidecar instance. The Namerd service forms the **control plane** of a Linkerd service mesh. In a sense, the Envoy equivalent to Namerd would be an implementation of the [LDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/lds.proto), [CDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/cds.proto), [EDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/eds.proto), and [RDS](https://www.envoyproxy.io/docs/envoy/latest/api-v2/rds.proto) APIs.

Istio operates at a different layer than Linkerd: it is a _platform_ composed of a data plane, a control plane (mainly composed of [Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html) and [Pilot]({{home}}/docs/concepts/traffic-management/pilot.html), and additional full-fledged components such as Prometheus, Grafana, and Zipkin. Istio also provides features such as [transparent mutual TLS]({{home}}/docs/concepts/security/mutual-tls.html) and [fault injection]({{home}}/docs/concepts/traffic-management/fault-injection.html) for chaos testing.

Note that Istio and Linkerd are not mutually exclusive: Istio can be deployed with Linkerd instead of Envoy as a sidecar proxy. Refer to the [Linkerd documentation](https://linkerd.io/getting-started/istio/) for more detail.

For more detailed information about the data plane and the control plane, see the [Overview]({{home}}/docs/concepts/what-is-istio/overview) page.