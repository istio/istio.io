---
title: Announcing Istio 0.2
linktitle: 0.2
description: Istio 0.2 announcement.
publishdate: 2017-10-10
subtitle: Improved mesh and support for multiple environments
aliases:
    - /blog/istio-0.2-announcement.html
    - /about/notes/older/0.2
    - /blog/2017/0.2-announcement
    - /docs/welcome/notes/0.2.html
    - /about/notes/0.2/index.html
    - /news/2017/announcing-0.2
    - /news/announcing-0.2
---

We launched Istio; an open platform to connect, manage, monitor, and secure microservices, on May 24, 2017. We have been humbled by the incredible interest, and
rapid community growth of developers, operators, and partners. Our 0.1 release was focused on showing all the concepts of Istio in Kubernetes.

Today we are happy to announce the 0.2 release which improves stability and performance, allows for cluster wide deployment and automated injection of sidecars in Kubernetes, adds policy and authentication for TCP services, and enables expansion of the mesh to include services deployed in virtual machines. In addition, Istio can now run outside Kubernetes, leveraging Consul/Nomad or Eureka. Beyond core features, Istio is now ready for extensions to be written by third party companies and developers.

## Highlights for the 0.2 release

### Usability improvements

- _Multiple namespace support_: Istio now works cluster-wide, across multiple namespaces and this was one of the top requests from community from 0.1 release.

- _Policy and security for TCP services_: In addition to HTTP, we have added transparent mutual TLS authentication and policy enforcement for TCP services as well. This will allow you to secure more of your
Kubernetes deployment, and get Istio features like telemetry, policy and security.

- _Automated sidecar injection_: By leveraging the alpha [initializer](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) feature provided by Kubernetes 1.7, envoy sidecars can now be automatically injected into application deployments when your cluster has the initializer enabled.  This enables you to deploy microservices using `kubectl`, the exact same command that you normally use for deploying the microservices without Istio.

- _Extending Istio_: An improved Mixer design that lets vendors write Mixer adapters to implement support for their own systems, such as application
management or policy enforcement. The
[Mixer Adapter Developer's Guide](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) can help
you easily integrate your solution with Istio.

- _Bring your own CA certificates_: Allows users to provide their own key and certificate for Istio CA and persistent CA key/certificate Storage. Enables storing signing key/certificates in persistent storage to facilitate CA restarts.

- _Improved routing & metrics_: Support for WebSocket, MongoDB and Redis  protocols. You can apply resilience features like circuit breakers on traffic to third party services. In addition to Mixer’s metrics, hundreds of metrics from Envoy are now visible inside Prometheus for all traffic entering, leaving and within Istio mesh.

### Cross environment support

- _Mesh expansion_: Istio mesh can now span services running outside of Kubernetes - like those running in virtual machines while enjoying benefits such as automatic mutual TLS authentication, traffic management, telemetry, and policy enforcement across the mesh.

- _Running outside Kubernetes_: We know many customers use other service registry and orchestration solutions like Consul/Nomad and Eureka. Istio Pilot can now run standalone outside Kubernetes, consuming information from these systems, and manage the Envoy fleet in VMs or containers.

## Get involved in shaping the future of Istio

We have a growing [roadmap](/pt-br/about/feature-stages/) ahead of us, full of great features to implement. Our focus next release is going to be on stability, reliability, integration with third party tools and multicluster use cases.

To learn how to get involved and contribute to Istio's future, check out our [community](https://github.com/istio/community) GitHub repository which
will introduce you to our working groups, our mailing lists, our various community meetings, our general procedures and our guidelines.

We want to thank our fantastic community for field testing new versions, filing bug reports, contributing code, helping out other community members, and shaping Istio by participating in countless productive discussions. This has enabled the project to accrue 3000 stars on GitHub since launch and hundreds of active community members on Istio mailing lists.

Thank you

## Release notes

### General

- **Updated Configuration Model**. Istio now uses the Kubernetes [Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
model to describe and store its configuration. When running in Kubernetes, configuration can now be optionally managed using the `kubectl`
command.

- **Multiple Namespace Support**. Istio control plane components are now in the dedicated `istio-system` namespace. Istio can manage
services in other non-system namespaces.

- **Mesh Expansion**. Initial support for adding non-Kubernetes services (in the form of VMs and/or physical machines) to a mesh. This is an early version of
this feature and has some limitations (such as requiring a flat network across containers and VMs).

- **Multi-Environment Support**. Initial support for using Istio in conjunction with other service registries
including Consul and Eureka.

- **Automatic injection of sidecars**. Istio sidecar can automatically be injected into a pod upon deployment using the
[Initializers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) alpha feature in Kubernetes.

### Performance and quality

There have been many performance and reliability improvements throughout the system. We don’t consider Istio 0.2 ready for production yet, but
we’ve made excellent progress in that direction. Here are a few items of note:

- **Caching Client**. The Mixer client library used by Envoy now provides caching for Check calls and batching for Report calls, considerably reducing
end-to-end overhead.

- **Avoid Hot Restarts**. The need to hot-restart Envoy has been mostly eliminated through effective use of LDS/RDS/CDS/EDS.

- **Reduced Memory Use**. Significantly reduced the size of the sidecar helper agent, from 50Mb to 7Mb.

- **Improved Mixer Latency**. Mixer now clearly delineates configuration-time vs. request-time computations, which avoids doing extra setup work at
request-time for initial requests and thus delivers a smoother average latency. Better resource caching also contributes to better end-to-end performance.

- **Reduced Latency for Egress Traffic**. We now forward traffic to external services directly from the sidecar.

### Traffic management

- **Egress Rules**. It’s now possible to specify routing rules for egress traffic.

- **New Protocols**. Mesh-wide support for WebSocket connections, MongoDB proxying,
and Kubernetes [headless services](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services).

- **Other Improvements**. Ingress properly supports gRPC services, better support for health checks, and
Jaeger tracing.

### Policy enforcement & telemetry

- **Ingress Policies**. In addition to east-west traffic supported in 0.1. policies can now be applied to north-south traffic.

- **Support for TCP Services**. In addition to the HTTP-level policy controls available in 0.1, 0.2 introduces policy controls for
TCP services.

- **New Mixer API**. The API that Envoy uses to interact with Mixer has been completely redesigned for increased robustness, flexibility, and to support
rich proxy-side caching and batching for increased performance.

- **New Mixer Adapter Model**. A new adapter composition model makes it easier to extend Mixer by adding whole new classes of adapters via templates. This
new model will serve as the foundational building block for many features in the future. See the
[Adapter Developer's Guide](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) to learn how
to write adapters.

- **Improved Mixer Build Model**. It’s now easier to build a Mixer binary that includes custom adapters.

- **Mixer Adapter Updates**. The built-in adapters have all been rewritten to fit into the new adapter model. The `stackdriver` adapter has been added for this
release. The experimental `redisquota` adapter has been removed in the 0.2 release, but is expected to come back in production quality for the 0.3 release.

- **Mixer Call Tracing**. Calls between Envoy and Mixer can now be traced and analyzed in the Zipkin dashboard.

### Security

- **Mutual TLS for TCP Traffic**. In addition to HTTP traffic, mutual TLS is now supported for TCP traffic as well.

- **Identity Provisioning for VMs and Physical Machines**. Auth supports a new mechanism using a per-node agent for
identity provisioning. This agent runs on each node (VM / physical machine) and is responsible for generating and sending out the CSR
(Certificate Signing Request) to get certificates from Istio CA.

- **Bring Your Own CA Certificates**. Allows users to provide their own key and certificate for Istio CA.

- **Persistent CA Key/Certificate Storage**. Istio CA now stores signing key/certificates in
persistent storage to facilitate CA restarts.

## Known issues

- **User may get periodical 404 when accessing the application**:  We have noticed that Envoy doesn't get routes properly occasionally
thus a 404 is returned to the user.  We are actively working on this [issue](https://github.com/istio/istio/issues/1038).

- **Istio Ingress or Egress reports ready before Pilot is actually ready**: You can check the `istio-ingress` and `istio-egress` pods status
in the `istio-system` namespace and wait a few seconds after all the Istio pods reach ready status.  We are actively working on this
[issue](https://github.com/istio/istio/pull/1055).

- **A service with Istio Auth enabled can't communicate with a service without Istio**: This limitation will be removed in the near future.
