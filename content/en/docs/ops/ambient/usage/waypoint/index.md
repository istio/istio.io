---
title: L7 Networking & Services with Waypoint
description: User guide for Istio Ambient L7 networking and services using waypoint proxy.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< warning >}}
Ambient is currently in [alpha status](/docs/releases/feature-stages/#feature-phase-definitions).

Please **do not run ambient in production** and be sure to thoroughly review the [feature phase definitions](/docs/releases/feature-stages/#feature-phase-definitions) before use. In particular, there are known performance, stability, and security issues in the `alpha` release. There are also functional caveats some of which are listed in the [Caveats section](#caveats) of this guide. There are also planned breaking changes, including some that will prevent upgrades. These are all limitations that will be addressed before graduation to `beta`. The current version of this guide is meant to assist early deployments and testing of the alpha version of ambient. The guide will continue to get updated as ambient itself evolves from alpha to beta status and beyond.
{{< /warning >}}

## Introduction

This guide provides instructions on how to set up and use the waypoint proxy layer in Istio ambient mesh.

Istio ambient mesh is a new way to deploy and manage microservices. In ambient mesh, workloads are no longer required to run sidecar proxies to participate in the service mesh. Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.

Ztunnel is used to handle L3 and L4 networking functions, such as mTLS authentication and L4 authorization. The waypoint proxy is an optional component that is Envoy-based and is responsible for L7 service mesh functionalities. For workloads that require L7 networking features, such as HTTP load balancing and fault injection, a waypoint proxy must be deployed.  It can also enforce L7 policies and collect L7 metrics.

{{<tip>}}

<!-- Pre-requisites & Supported Topologies -->

Before you begin, make sure that you have already read the [Ztunnel Networking sub-guide](../ztunnel/). This guide assumes that you have the following prerequisites in place:
1. Istio ambient mesh installed and configured
2. Ztunnel proxy is installed and running

{{</tip>}}

This guide describes the functionality and usage of the waypoint proxy and L7 networking functions using Istio ambient mesh. We use a sample user journey to describe these functions hence it would be useful to go through this guide in sequence. However we provide links to the sections below in case the reader would like to jump to the appropriate section.

* [Introduction](#introduction)
* [Deciding if you need a waypoint proxy](#deciding-if-you-need-a-waypoint-proxy)
* [Current challenges](#current-challenges)
<!-- * [Differences between Sidecar Mode and ambient Mode for waypoint proxy](#differences) -->
* [Deciding the scope of your waypoint proxy](#Deciding-the-scope-of-your-waypoint-proxy)
* [Functional overview](#functional-overview)
* [Deploying an application](#deploying-an-application)
* [Configuring waypoint proxy](#configuring-waypoint-proxy)
* [Monitoring the waypoint proxy & L7 networking](#monitoring-the-waypoint-proxy--l7-networking)
* [L7 fault injection](#l7-fault-injection)
* [L7 observability](#l7-observability)
* [L7 authorization policy](#l7-authorization-policy)
* [Co-existence of ambient/ L7 with Sidecar proxies](#Co-existence-of-ambient/-L7-with-side-car-proxies)
* [Control traffic towards waypoint proxy](##control-traffic-towards-waypoint-proxy)
* [Remove waypoint proxy layer](#remove-waypoint-proxy-layer)

## Deciding if you need a waypoint proxy

It's possible that the features offered by the secure overlay doesn’t meet your requirements. For instance, you need a rich Layer 7 authorization policy that sets up access based on a certain method and path. Alternatively you may like to conduct a canary test on the updated version of your service or introduce a new version without affecting current traffic. Or, you would like to receive metrics, HTTP access logs, and distributed tracing for some of your services. In order to accomplish these common cases, we'll go over how you can choose to enforce L7 processing with ambient mesh in this section.

### Benefits of using the waypoint proxy and L7 networking features

In summary, the waypoint proxy approach for the L7 processing layer offers the following four main advantages:

* Traffic resiliency - Timeout and retry, circuit breaking
* Security - Rich L7 authorization policy
* Observability - HTTP metrics, access logs, and tracing
* Traffic management - Dark launch, canary test

### When to use the waypoint proxy and L7 networking features

You should consider using the waypoint proxy and L7 networking features if your microservices architecture requires any of the following:

* L7 load balancing and routing: You need to distribute traffic across multiple instances of a workload based on factors such as request path, header values, or cookies.
Waypoint provides a variety of L7 load balancing and routing algorithms, including round robin, weighted round robin, and least connections. It also supports path-based routing and other advanced routing rules.
* L7 fault injection: You need to simulate faults in your microservices architecture such as delays, errors, and circuit breaks to test its resilience and prepare for real-world failures.
* Rate limiting: You need to protect workloads against denial-of-service attacks and improve performance.
* L7 observability: You need to collect metrics and traces from your microservices architecture to monitor its performance and troubleshoot problems.
* Rich Authz Policy: Enforce granular authorization control and manage authorization policies centrally as well as enhanced Security

### Getting started with the waypoint proxy and L7 networking features

To get started with the waypoint proxy and L7 networking features, you will need to deploy a waypoint proxy for each workload that requires L7 networking. You can do this using the Kubernetes Gateway resource. Once the waypoint proxy is deployed, you can configure L7 policies using the VirtualService, DestinationRule, and ServiceEntry resources.

This guide will provide more detailed instructions on how to deploy and configure the waypoint proxy and L7 networking features.

## Current challenges

Unlike Ztunnel proxies, waypoint proxies are not automatically installed with Istio ambient mesh. Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful `istioctl` command. The minimum Istio version required for Istio ambient mode is `1.18.0`. In general Istio in ambient mode supports the existing Istio APIs that are supported in sidecar proxy mode. Since the ambient functionality is currently at an alpha release level, the following is a list of feature restrictions or caveats in the current release of Istio's ambient functionality (as of the `1.20.0` release). These restrictions are expected to be addressed/removed in future software releases as ambient graduates to beta and eventually General Availability.

1. **`PeerAuthentication` Limitations:** As of now, not all components (i.e. waypoint proxies), support the `PeerAuthentication` resource in Istio ambient mode. Hence it is recommended to use the `STRICT` mTLS mode currently, this caveat shall be addressed as the feature moves toward beta status.

1. **No HTTP/3 support:** Waypoint supports HTTP/2, but there are some limitations with HTTP/3 support when using HBONE (HTTP-Based Overlay Network Encapsulation). HBONE is currently limited to HTTP/2 transport, so while waypoint can handle HTTP/2 traffic, it cannot yet fully support HTTP/3.

Despite these caveats, waypoint is a powerful tool for enabling L7 networking and services for Istio ambient workloads. It is a good choice for users who are looking for a way to run microservices-based applications in ambient mode.

### Environment used for this guide

For the environment used in this guide, refer to the [Installation user](../../install/) guide or [L4 Networking & mTLS with Ztunnel](../ztunnel/) guide on installing Istio in ambient mode on a Kubernetes cluster.

## Deciding the scope of your waypoint proxy

Waypoint proxies can be deployed at the namespace(default) or service account level. The scope you choose depends on your specific needs and requirements.

### Namespace-level scope

Deploying waypoint proxies at the namespace level provides a number of benefits, including:
- Simplified policy management: Policies are enforced at the namespace level, so you only need to define them once for all workloads in the namespace.
- Improved performance: Waypoint proxies can cache routing and policy information, which can improve performance for workloads in the namespace.
- Increased security: Waypoint proxies can enforce authorization policies at the namespace level, which can help to protect your workloads from unauthorized access.

However, deploying waypoint proxies at the namespace level also has some drawbacks, including:
- Limited granularity: You cannot apply different policies to different workloads in the same namespace.
- Increased resource consumption: Each namespace will require its own waypoint proxy, which can consume more resources.

### Service account-level scope

Deploying waypoint proxies at the service account level provides a number of benefits, including:
- Increased granularity: You can apply different policies to different workloads based on their service account.
- Reduced resource consumption: You only need to deploy a waypoint proxy for each service account that has workloads that require L7 routing or policy enforcement.

However, deploying waypoint proxies at the service account level also has some drawbacks, including:

* Increased complexity: Managing policies at the service account level can be more complex, especially if you have a large number of service accounts.
* Reduced caching: Waypoint proxies cannot cache routing and policy information at the service account level, which can reduce performance.

### How to choose the right scope for your waypoint proxies

The best scope for your waypoint proxies will depend on your specific needs and requirements. If you have a simple application with a small number of workloads, then namespace-level scope may be a good choice. However, if you have a more complex application with a large number of workloads or if you need to apply different policies to different workloads, then service account-level scope may be a better choice.

Here are some factors to consider when choosing the scope for your waypoint proxies:
* The number of workloads in your application
* The complexity of your application
* The need to apply different policies to different workloads
* The performance requirements of your application
* The resource requirements of your application

## Functional overview

The functional behavior of the waypoint proxy is dynamically configured by Istio to serve your application's configurations. This section takes a brief look at these functional aspects - detailed description of the internal design of the waypoint proxy is out of scope for this guide. The detailed functional overview from the Secure Overlay Networking was already discussed in the [Ztunnel L4 Networking Guide](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/usage/ztunnel/#functionaloverview) hence this section only focuses on functionalities and features that waypoint proxy provides.

{{< image width="100%"
link="waypoint-architecture.png"
caption="Waypoint architecture"
>}}

What is unique about the waypoint proxy is that it runs either per-namespace (default) or per-service account. By running outside of the application pod, a waypoint proxy can install, upgrade, and scale independently from the application pod, providing a centralized approach to managing L7 traffic and enforcing policies as well as reduce operational costs.

Upon deployment of a gateway resource using the `kubectl apply` command, Istio's control plane, istiod, assumes the role of the waypoint controller. Recognizing the gateway resource with the "istio.io/waypoint" gateway class name, istiod automatically deploys the waypoint proxy based on the specified configuration in the gateway resource.

The waypoint proxy's data plane operates at Layer 7, enabling it to fully parse connections into individual requests and apply policies based on request properties such as headers and credentials. This granular control over L7 traffic extends to a comprehensive suite of capabilities, including:
- HTTP 1.x, 2, or 3
- Request routing
- Advanced load balancing
- Request mirroring
- Fault injection
- Request retries
- gRPC-specific capabilities

Waypoint proxies are deployed either per-namespace or per-service account, providing granular control over L7 traffic management. This deployment model allows for independent scaling of waypoint proxies based on the request load for individual workloads. Unlike the traditional sidecar deployment approach, waypoint proxies can be scaled independently to better fit the incoming traffic for a service and match the actual workload usage, optimizing resource utilization and improving performance. You can think of these waypoint proxies as individual gateways per workload type as shown here -

{{< image width="100%"
link="waypoint-gateway-architecture.svg"
caption="The waypoint proxy is deployed per service account/ workload identity and can be thought of as a 'gateway per workload'"
>}}

The deployment of waypoint proxies can be handled by namespace owners, platform operators, or automated systems. Once a waypoint proxy is deployed, and a corresponding L7 policy is configured for a destination represented by the waypoint proxy, the secure overlay layer ensures that connection is routed to the correct L7 waypoint proxy for processing and policy enforcement as shown here -

{{< image width="100%"
link="waypoint-traffic-flow.svg"
caption="Traffic will flow through L7 waypoint proxies when there are L7 policies that need to be enforced for a particular service"
>}}

Tenancy for Layer 7 capabilities in the Istio ambient mesh is similar to the sidecar deployment model. L7 capabilities are not shared across multiple identities within a single L7 proxy. Each application has its own dedicated waypoint proxy, ensuring isolation of configuration and extensions (plug-ins, extensions, etc.) specific to individual workloads. This isolation prevents interference between workloads and facilitates independent management of L7 configurations.

Functionally, the waypoint proxy resembles the sidecar proxy but operates independently of application pods. It has its own CA client and XDS client, enabling secure communication with istiod. To obtain its identity certificate, the Waypoint proxy establishes a secure connection with istiod, requesting certification. Upon validating the presented token, istiod signs the Waypoint proxy's certificate, granting it access to the Istio control plane.

Subsequently, the waypoint proxy initiates communication with istioD, requesting XDS configuration to govern its operation. This configuration defines the L7 routing rules, policy enforcement mechanisms, and other parameters essential for managing L7 traffic.

In essence, the waypoint proxy serves as an L7 traffic management hub, decoupled from application pods and centrally managed by istioD. This architecture simplifies L7 configuration and policy enforcement, enabling efficient and scalable L7 services within Istio ambient deployments as shown in the figure -

{{< image width="100%"
link="waypoint-architecture-deep-dive.svg"
caption="Waypoint Architecture Deep Dive"
>}}

### Destination only waypoint

In contrast to traditional sidecar proxies, which reside alongside application pods, waypoint proxies operate solely on the server-side, acting as reverse proxies for L7 traffic. This approach streamlines L7 traffic management by centralizing policy enforcement to the destination workload's namespace or service account.

When a request originates from an application pod, it bypasses the client-side waypoint proxy and directly reaches the server-side waypoint proxy associated with the destination workload's namespace or service account. Istio enforces that all traffic coming into the namespace goes through the waypoint, which then enforces all policies for that namespace. Because of this, each waypoint only needs to know about configuration for its own namespace. Thus waypoint proxy assumes responsibility for enforcing all L7 policies and routing rules applicable to the destination workload.

{{< image width="100%"
link="destinationonly.svg"
caption="Waypoint proxies"
>}}

Destination-only waypoint simplifies the configuration process by eliminating the need for sidecar proxies and `exportTo` configurations. Waypoint proxies only need to be aware of the endpoints, pods, and workloads within their respective namespaces or service accounts. This streamlined approach reduces the complexity of L7 management and enables a more efficient use of resources.

{{< image width="100%"
link="destination-only-waypoint.svg"
caption="Waypoint proxies"
>}}

* **Policy Enforcement**: In traditional Istio deployments, both source-side and destination-side policies were employed, which often led to confusion for users regarding policy enforcement and troubleshooting. Destination-only waypoint simplifies this process by enforcing all policies exclusively at the destination workload's namespace or service account. This centralized approach eliminates the need to track policies across multiple locations, making it easier to understand, manage, and troubleshoot L7 security configurations.

{{< image width="100%"
link="policies-enforced (1).svg"
caption="Policy Enforced on Destination waypoint"
>}}

* **Mixed Environment**: In a mixed environment where clients may reside inside or outside the Istio mesh, destination-only waypoint ensures consistent policy enforcement regardless of the client's location. Since all policies are applied at the destination workload, users can be confident that security measures are consistently applied to all incoming traffic.

{{< image width="100%"
link="mixed-environment.svg"
caption="Waypoint proxies"
>}}

### Handling destinations without waypoint proxies

While destination-only waypoint offers centralized policy enforcement and simplified configuration, there may be instances where the destination workload doesn't have a waypoint proxy deployed. This could arise when connecting to external services beyond the control of the Istio mesh.

To address this scenario, the Istio community is actively developing mechanisms to route traffic to the egress gateway and enable policy enforcement for destinations without waypoint proxies. This functionality will allow users to configure resilience-enhancing policies, such as timeouts, for external services.

Please stay tuned for future blog posts and documentation updates that will provide detailed information on this evolving feature.

## Deploying an application

When someone with Istio admin privileges sets up Istio mesh, it becomes available for all users in specific namespaces. The examples below shows how Istio can be used transparently once it's successfully deployed in ambient mode and the namespaces are annotated accordingly.

### Basic application deployment without ambient

This section is Under Construction.
