---
title: "Zero Configuration Istio"
description: Understanding the benefits Istio brings, even when no configuration is used.
publishdate: 2021-02-25
attribution: "John Howard (Google)"
---

When a new user encounters Istio for the first time, they are sometimes overwhelmed by the vast feature
set it exposes. Unfortunately, this can give the impression that Istio is needlessly complex
and not fit for small teams or clusters.

One great part about Istio, however, is that it aims to bring as much value to users out of the box without any configuration at all.
This enables users to get most of the benefits of Istio with minimal efforts. For some users with simple requirements, custom configurations
may never be required at all. Others will be able to incrementally add Istio configurations once they are more comfortable and as they need them, such as to add
ingress routing, fine-tune networking settings, or lock down security policies.

## Getting started

To get started, check out our [getting started](/docs/setup/getting-started/) documentation, where you will learn how to install Istio.
If you are already familiar, you can simply run `istioctl install`.

Next, we will explore all the benefits Istio provides us, without any configuration or changes to application code.

## Security

Istio automatically enables [mutual TLS](/docs/concepts/security/#mutual-tls-authentication) for traffic between pods in the mesh.
This enables applications to forgo complex TLS configuration and certificate management, and offload all transport layer security to the sidecar.

Once comfortable with automatic TLS, you may choose to [allow only mTLS traffic](/docs/tasks/security/authentication/mtls-migration/), or configure custom [authorization policies](/docs/tasks/security/authorization/) for your needs.

## Observability

Istio automatically generates detailed telemetry for all service communications within a mesh.
This telemetry provides observability of service behavior, empowering operators to troubleshoot, maintain, and optimize their applications – without imposing any additional burdens on service developers.
Through Istio, operators gain a thorough understanding of how monitored services are interacting, both with other services and with the Istio components themselves.

All of this functionality is added by Istio without any configuration. [Integrations](/docs/ops/integrations/) with tools such as Prometheus, Grafana, Jaeger, Zipkin, and Kiali are also available.

For more information about the observability Istio provides, check out the [observability overview](/docs/concepts/observability/).

## Traffic Management

While Kubernetes provides a lot of networking functionality, such as service discovery and DNS, this is done at Layer 4, which can have unintended inefficiencies.
For example, in a simple HTTP application sending traffic to a service with 3 replicas, we can see unbalanced load:

{{< text bash >}}
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
Hostname=echo-cb96f8d94-2ssll
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
Hostname=echo-cb96f8d94-879sn
{{< /text >}}

The problem here is Kubernetes will determine the backend to send to when the connection is established, and all future requests on the same connection will be sent to the same backend.
In our example here, our first 5 requests are all sent to `echo-cb96f8d94-2ssll`, while our next set (using a new connection) are all sent to `echo-cb96f8d94-879sn`.
Our third instance never receives any requests.

With Istio, HTTP traffic (including HTTP/2 and gRPC) is automatically detected, and our services will automatically be load balanced per _request_, rather than per _connection_:

{{< text bash >}}
$ curl http://echo/{0..5} -s | grep Hostname
Hostname=echo-cb96f8d94-wf4xk
Hostname=echo-cb96f8d94-rpfqz
Hostname=echo-cb96f8d94-cgmxr
Hostname=echo-cb96f8d94-wf4xk
Hostname=echo-cb96f8d94-rpfqz
Hostname=echo-cb96f8d94-cgmxr
{{< /text >}}

Here we can see our requests are [round-robin](/docs/concepts/traffic-management/#load-balancing-options) load balanced between all backends.

In addition to these better defaults, Istio offers customization of a [variety of traffic management settings](/docs/concepts/traffic-management/), including timeouts, retries, and much more.
