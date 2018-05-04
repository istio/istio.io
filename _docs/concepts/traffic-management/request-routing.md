---
title: Request Routing
description: Describes how requests are routed between services in an Istio service mesh.

weight: 20

---
{% include home.html %}

This page describes how requests are routed between services in an Istio service mesh.

## Service model and service versions

As described in [Pilot](./pilot.html), the canonical representation
of services in a particular mesh is maintained by Pilot. The Istio
model of a service is independent of how it is represented in the underlying
platform (Kubernetes, Mesos, Cloud Foundry,
etc.). Platform-specific adapters are responsible for populating the
internal model representation with various fields from the metadata found
in the platform.

Istio introduces the concept of a service version, which is a finer-grained
way to subdivide service instances by versions (`v1`, `v2`) or environment
(`staging`, `prod`). These variants are not necessarily different API
versions: they could be iterative changes to the same service, deployed in
different environments (prod, staging, dev, etc.). Common scenarios where
this is used include A/B testing or canary rollouts. Istio's [traffic
routing rules](./rules-configuration.html) can refer to service versions to provide
additional control over traffic between services.

## Communication between services

{% include figure.html width='60%' ratio='100.42%'
    img='./img/pilot/ServiceModel_Versions.svg'
    alt='Showing how service versions are handled.'
    title='Service Versions'
    caption='Service Versions'
    %}

As illustrated in the figure above, clients of a service have no knowledge
of different versions of the service. They can continue to access the
services using the hostname/IP address of the service. The Envoy sidecar/proxy
intercepts and forwards all requests/responses between the client and the
service.

Envoy determines its actual choice of service version dynamically
based on the routing rules specified by the operator using Pilot. This
model enables the application code to decouple itself from the evolution of its dependent
services, while providing other benefits as well (see
[Mixer]({{home}}/docs/concepts/policy-and-control/mixer.html)). Routing
rules allow Envoy to select a version based
on criteria such as headers, tags associated with
source/destination, and/or by weights assigned to each version.

Istio also provides load balancing for traffic to multiple instances of
the same service version. You can find out more about this in [Discovery
and Load-Balancing](./load-balancing.html).

Istio does not provide a DNS. Applications can try to resolve the
FQDN using the DNS service present in the underlying platform (kube-dns,
mesos-dns, etc.).

## Ingress and egress

Istio assumes that all traffic entering and leaving the service mesh
transits through Envoy proxies. By deploying the Envoy proxy in front of
services, operators can conduct A/B testing, deploy canary services,
etc. for user-facing services. Similarly, by routing traffic to external
web services (for instance, accessing the Maps API, or a video service API)
via the sidecar Envoy, operators can add failure recovery features such as
timeouts, retries, circuit breakers, etc., and obtain detailed metrics on
the connections to these services.

{% include figure.html width='60%' ratio='28.88%'
    img='./img/pilot/ServiceModel_RequestFlow.svg'
    alt='Ingress and Egress through Envoy.'
    title='Request Flow'
    caption='Request Flow'
    %}

