---
title: L7 Networking & Services with Waypoint
description: User guide for Istio Ambient L7 networking and services using waypoint proxy.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

{{< warning >}}
Ambient is currently in [alpha status](/docs/releases/feature-stages/#feature-phase-definitions).

Please **do not run ambient in production** and be sure to thoroughly review the [feature phase definitions](/docs/releases/feature-stages/#feature-phase-definitions) before use.
In particular, there are known performance, stability, and security issues in the `alpha` release. There are also functional caveats some of which are listed in the [Caveats section](#caveats) of this guide. There are also planned breaking changes, including some that will prevent upgrades. These are all limitations that will be addressed before graduation to `beta`. The current version of this guide is meant to assist early deployments and testing of the alpha version of `ambient`. The guide will continue to get updated as `ambient` itself evolves from alpha to beta status and beyond. 
{{< /warning >}}

## Introduction

This guide provides instructions on how to set up and use the Waypoint proxy layer in Istio Ambient Mesh.

Istio Ambient Mesh is a new way to deploy and manage microservices. In Ambient Mesh, workloads are no longer required to run sidecar proxies to participate in the service mesh. Ambient splits Istio’s functionality into two distinct layers, a secure overlay layer and a Layer 7 processing layer.

Ztunnel proxy is used to handle L3 and L4 networking functions, such as mTLS authentication and L4 authorization. For workloads that require L7 networking features, such as HTTP load balancing and fault injection, a waypoint proxy can be deployed. The waypoint proxy is an optional component that is Envoy-based and is responsible for terminating workload HTTP traffic and parsing workload HTTP headers. They also enforce L7 policies and collect L7 metrics.

{{<tip>}}

<!-- Pre-requisites & Supported Topologies -->

Before you begin, make sure that you have already read the [Ztunnel Networking sub-guide](../ztunnel/). This guide assumes that you have the following prerequisites in place:
1. Istio Ambient Mesh installed and configured
2. Ztunnel proxy is installed and running
3. Mutual TLS (mTLS) enabled and configured

{{</tip>}}

This guide describes the functionality and usage of the waypoint proxy and L7 networking functions using Istio Ambient Mesh. We use a sample user journey to describe these functions hence it would be useful to go through this guide in sequence. However we provide links to the sections below in case the reader would like to jump to the appropriate section.

* [Introduction](#introduction)
* [Deciding if you need A Waypoint Proxy](#deciding-if-you-need-a-waypoint-proxy)
* [Current Challenges](#current-challenges)
<!-- * [Differences between Sidecar Mode and Ambient Mode for Waypoint Proxy](#differences) -->
* [Deciding the scope of your Waypoint Proxy](#Deciding-the-scope-of-your-Waypoint-Proxy)
* [Functional Overview](#functional-overview)
* [Deploying an Application](#deploying-an-application)
* [Configuring Waypoint proxy](#configuring-waypoint-proxy)
* [Monitoring the Waypoint Proxy & L7 Networking](#monitoring-the-waypoint-proxy--l7-networking)
* [L7 Fault Injection](#l7-fault-injection)
* [L7 Observability](#l7-observability)
* [L7 Authorization Policy](#l7-authorization-policy)
* [Co-existence of Ambient/ L7 with Side car proxies](#Co-existence-of-Ambient/-L7-with-Side-car-proxies)
* [Control Traffic towards Waypoint Proxy](##control-traffic-towards-waypoint-proxy)
* [Remove Waypoint proxy layer](#remove-waypoint-proxy-layer)

## Deciding if you need A Waypoint proxy

It's possible that the features offered by the secure overlay doesn’t meet your requirements. For instance, you need a rich Layer 7 authorization policy that sets up access based on a certain method and path. Alternatively you may like to conduct a canary test on the updated version of your service or introduce a new version without affecting current traffic. Or, you would like to receive metrics, HTTP access logs, and distributed tracing for some of your services. In order to accomplish these common cases, we'll go over how you can choose to enforce L7 processing with ambient mesh in this section.

### Benefits of using the waypoint proxy and L7 networking features

In summary, the waypoint proxy approach for the L7 processing layer offers the following three main advantages:

- Security - Rich L7 authorization policy
- Observability - HTTP metrics, access logs, and tracing
- Traffic management - Dark launch, canary test

The waypoint proxy and L7 networking features provide a number of benefits, including:

- Improved performance and scalability: Waypoint proxies are designed to be lightweight and efficient, which can improve the performance and scalability of your microservices architecture.
- Increased flexibility: The waypoint proxy allows you to implement a wide range of L7 networking features, such as HTTP load balancing, fault injection, and observability.
- Simplified operations: By deploying a waypoint proxy, you can simplify the operation of your microservices architecture by reducing the number of components that need to be managed.

### When to use the waypoint proxy and L7 networking features

You should consider using the waypoint proxy and L7 networking features if your microservices architecture requires any of the following:

- L7 load balancing and routing: You need to distribute traffic across multiple instances of a workload based on factors such as request path, header values, or cookies.
Waypoint provides a variety of L7 load balancing and routing algorithms, including round robin, weighted round robin, and least connections. It also supports path-based routing and other advanced routing rules.
- L7 fault injection: You need to simulate faults in your microservices architecture such as delays, errors, and circuit breaks to test its resilience and prepare for real-world failures.
- Rate limiting: You need to protect workloads against denial-of-service attacks and improve performance.
- L7 observability: You need to collect metrics and traces from your microservices architecture to monitor its performance and troubleshoot problems.

### Getting started with the waypoint proxy and L7 networking features

To get started with the waypoint proxy and L7 networking features, you will need to deploy a waypoint proxy for each workload that requires L7 networking. You can do this using the Kubernetes Gateway resource. Once the waypoint proxy is deployed, you can configure L7 policies using the VirtualService, DestinationRule, and ServiceEntry resources.

This guide will provide more detailed instructions on how to deploy and configure the waypoint proxy and L7 networking features.

## Current Challenges

Unlike Ztunnel proxies, Waypoint proxies are not automatically installed with Istio ambient mesh. Waypoint proxies are deployed declaratively using Kubernetes Gateway resources or the helpful `istioctl` command. The minimum Istio version required for Istio ambient mode is `1.18.0`. In general Istio in ambient mode supports the existing Istio APIs that are supported in sidecar proxy mode. Since the ambient functionality is currently at an alpha release level, the following is a list of feature restrictions or caveats in the current release of Istio's ambient functionality (as of the `1.19.0` release). These restrictions are expected to be addressed/removed in future software releases as ambient graduates to beta and eventually General Availability.

1. **Kubernetes only:** Istio in ambient mode is currently limited to deployment on Kubernetes clusters, excluding non-Kubernetes endpoints like virtual machines.

2. **Single Cluster Support:** Multi-cluster deployments are not supported in Istio ambient mode; only single-cluster configurations are currently viable.

3. **K8s CNI Restrictions:** Istio in ambient mode does not currently work with every Kubernetes CNI implementation. Additionally, with some plugins, certain CNI functions (in particular Kubernetes `NetworkPolicy` and Kubernetes Service Load balancing features) may get transparently bypassed in the presence of Istio ambient mode. The exact set of supported CNI plugins as well as any CNI feature caveats are currently under test and will be formally documented as Istio's ambient mode approaches the beta release.

4. **TCP/IPv4 only:** In the current release, TCP over IPv4 is the only protocol supported for transport on an Istio secure overlay tunnel (this includes protocols such as HTTP that run between application layer endpoints on top of the TCP/ IPv4 connection).

5. **No Dynamic switching to Ambient mode:** Enabling ambient mode is only possible during the deployment of a new Istio mesh control plane using an ambient profile or helm configuration. An existing Istio mesh deployed using a pre-ambient profile for instance can not be dynamically switched to also enable ambient mode operation.

6. **Restrictions with Istio `PeerAuthentication`:** as of the time of writing, the `PeerAuthentication` resource is not supported by all components (i.e. waypoint proxies) in Istio ambient mode. Hence it is recommended to only use the `STRICT` mTLS mode currently. Like many of the other alpha stage caveats, this shall be addressed as the feature moves toward beta status.

6. **`PeerAuthentication` Limitations:** As of now, not all components (i.e. Waypoint proxies), support the `PeerAuthentication` resource in Istio Ambient mode. Hence it is recommended to use the `STRICT` mTLS mode currently, this caveat shall be addressed as the feature moves toward beta status.

7. **istioctl CLI Gaps:** Minor functional gaps may exist in the Istio CLI's output displays related to ambient mode. These will be addressed as the feature matures.

In addition to this general caveats, there are also some specific caveats to be aware of when using Waypoint with certain protocols:

- Waypoint only supports Ambient workloads. It does not support sidecar proxy workloads. 
- HTTP: Waypoint does not support all HTTP features, such as HTTP/2 and chunked encoding.
- gRPC: Waypoint does not support all gRPC features, such as HTTP/2 transport and protocol multiplexing.
- WebSocket: Waypoint does not support WebSocket.

Despite these caveats, Waypoint is a powerful tool for enabling L7 networking and services for Istio Ambient workloads. It is a good choice for users who are looking for a way to run microservices-based applications in Ambient mode.

Here is a table summarizing the caveats of Waypoint:

| Caveat | Description |
| ------------- | ------------- |
| Maturity | Waypoint is still under development |
| Features | Waypoint only supports L7 load balancing and routing |
|Integration | Waypoint is not yet fully integrated with the Istio control plane | Support | Waypoint only supports Ambient workloads | HTTP | Waypoint does not support all HTTP features | 
gRPC | Waypoint does not support all gRPC features | Websocket | Waypoint does not support WebSocket |

In addition to these caveats, it is also important to note that Waypoint is a new feature, and it is not yet as mature as Istio's sidecar proxy. As a result, users may experience some performance or stability issues when using Waypoint. However, the Ambient mesh team is actively working to address these issues, and they are committed to making Waypoint a production-ready feature.

Overall, Waypoint is a powerful tool for enabling L7 networking and services for Istio Ambient workloads. However, users should be aware of the caveats and limitations listed above before deploying Waypoint in production.

### Environment used for this guide

For the examples in this guide, we used a deployment of Istio version `1.19.0` on a `kinD` cluster of version `0.20.0` running Kubernetes version `1.27.3`. However these should also work on any Kubernetes cluster at version `1.24.0` or later and Istio version `1.18.0` or later. It would be recommended to have a cluster with more than 1 worker node in order to fully exercise the examples described in this guide. Refer to the [Installation user](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/usage/install/) guide or [Getting started guide](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/getting-started/) on installing Istio in ambient mode on a Kubernetes cluster.

## Deciding the scope of your Waypoint proxy

Waypoint proxies can be deployed at the namespace or service account level. The scope you choose depends on your specific needs and requirements.

### Namespace-level scope

Deploying Waypoint proxies at the namespace level provides a number of benefits, including:
- Simplified policy management: Policies are enforced at the namespace level, so you only need to define them once for all workloads in the namespace.
- Improved performance: Waypoint proxies can cache routing and policy information, which can improve performance for workloads in the namespace.
- Increased security: Waypoint proxies can enforce authorization policies at the namespace level, which can help to protect your workloads from unauthorized access.

However, deploying Waypoint proxies at the namespace level also has some drawbacks, including:
- Limited granularity: You cannot apply different policies to different workloads in the same namespace.
- Increased resource consumption: Each namespace will require its own Waypoint proxy, which can consume more resources.

### Service account-level scope

Deploying Waypoint proxies at the service account level provides a number of benefits, including:
- Increased granularity: You can apply different policies to different workloads based on their service account.
- Reduced resource consumption: You only need to deploy a Waypoint proxy for each service account that has workloads that require L7 routing or policy enforcement.

However, deploying Waypoint proxies at the service account level also has some drawbacks, including:

- Increased complexity: Managing policies at the service account level can be more complex, especially if you have a large number of service accounts.
- Reduced caching: Waypoint proxies cannot cache routing and policy information at the service account level, which can reduce performance.

### How to choose the right scope for your Waypoint proxies

The best scope for your Waypoint proxies will depend on your specific needs and requirements. If you have a simple application with a small number of workloads, then namespace-level scope may be a good choice. However, if you have a more complex application with a large number of workloads or if you need to apply different policies to different workloads, then service account-level scope may be a better choice.

Here are some factors to consider when choosing the scope for your Waypoint proxies:
- The number of workloads in your application
- The complexity of your application
- The need to apply different policies to different workloads
- The performance requirements of your application
- The resource requirements of your application

## Functional Overview

The functional behaviour of the waypoint proxy is dynamically configured by Istio to serve your applications configurations. This section takes a brief look at these functional aspects - detailed description of the internal design of the waypoint proxy is out of scope for this guide. The detailed functional overview from the Secure Overlay Networking was already discussed in the [Ztunnel L4 Networking Guide](https://deploy-preview-13635--preliminary-istio.netlify.app/latest/docs/ops/ambient/usage/ztunnel/#functionaloverview) hence this section only focuses on functionalities and features that Waypoint Proxy provides.

{{< image width="100%"
link="waypoint-architecture.png"
caption="Waypoint architecture"
>}}

What is unique about the waypoint proxy is that it runs either per-namespace (default) or per-service account. By running outside of the application pod, a waypoint proxy can install, upgrade, and scale independently from the application pod, providing a centralized approach to managing L7 traffic and enforcing policies as well as reduce operational costs.

Upon deployment of a gateway resource using the `kubectl apply` command, Istio's control plane, IstioD, assumes the role of the Waypoint controller. Recognizing the gateway resource with the "istio.io/waypoint" gateway class name, istiod automatically deploys the Waypoint proxy based on the specified configuration in the gateway resource.

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
caption="The waypoint proxy is deployed per service account/ workload identity and can be thought of as a “gateway per workload”"
>}}

The deployment of waypoint proxies can be handled by namespace owners, platform operators, or automated systems. Once a waypoint proxy is deployed, and a corresponding L7 policy is configured for a destination represented by the waypoint proxy, the secure overlay layer ensures that connection is routed to the correct L7 waypoint proxy for processing and policy enforcement as shown here - 

{{< image width="100%"
link="waypoint-traffic-flow.svg"
caption="Traffic will flow through L7 waypoint proxies when there are L7 policies that need to be enforced for a particular service"
>}}

Tenancy for Layer 7 capabilities in the Istio ambient mesh is similar to the sidecar deployment model. L7 capabilities are not shared across multiple identities within a single L7 proxy. Each application has its own dedicated waypoint proxy, ensuring isolation of configuration and extensions (plug-ins, extensions, etc.) specific to individual workloads. This isolation prevents interference between workloads and facilitates independent management of L7 configurations.

Functionally, the Waypoint proxy resembles the sidecar proxy but operates independently of application pods. It has its own CA client and XDS client, enabling secure communication with istioD. To obtain its identity certificate, the Waypoint proxy establishes a secure connection with istioD, requesting certification. Upon validating the presented token, istioD signs the Waypoint proxy's certificate, granting it access to the Istio control plane.

Subsequently, the Waypoint proxy initiates communication with istioD, requesting XDS configuration to govern its operation. This configuration defines the L7 routing rules, policy enforcement mechanisms, and other parameters essential for managing L7 traffic.

In essence, the Waypoint proxy serves as an L7 traffic management hub, decoupled from application pods and centrally managed by istioD. This architecture simplifies L7 configuration and policy enforcement, enabling efficient and scalable L7 services within Istio Ambient deployments as shown in the figure - 

{{< image width="100%"
link="waypoint-architecture-deep-dive.svg"
caption="Waypoint Architecture Deep Dive"
>}}

### Destination Only Waypoint

In contrast to traditional sidecar proxies, which reside alongside application pods, Waypoint proxies operate solely on the server-side, acting as reverse proxies for L7 traffic. This approach streamlines L7 traffic management by centralising policy enforcement to the destination workload's namespace or service account.

When a request originates from an application pod, it bypasses the client-side Waypoint proxy and directly reaches the server-side Waypoint proxy associated with the destination workload's namespace or service account. Istio enforces that all traffic coming into the namespace goes through the waypoint, which then enforces all policies for that namespace. Because of this, each waypoint only needs to know about configuration for its own namespace. Thus Waypoint proxy assumes responsibility for enforcing all L7 policies and routing rules applicable to the destination workload.

{{< image width="100%"
link="destinationonly.svg"
caption="Waypoint Proxies"
>}}

Destination-only Waypoint simplifies the configuration process by eliminating the need for sidecar proxies and "exportTo" configurations. Waypoint proxies only need to be aware of the endpoints, pods, and workloads within their respective namespaces or service accounts. This streamlined approach reduces the complexity of L7 management and enables a more efficient use of resources.

{{< image width="100%"
link="destination-only-waypoint.svg"
caption="Waypoint Proxies"
>}}

- **Policy Enforcement**: In traditional Istio deployments, both source-side and destination-side policies were employed, which often led to confusion for users regarding policy enforcement and troubleshooting. Destination-only Waypoint simplifies this process by enforcing all policies exclusively at the destination workload's namespace or service account. This centralized approach eliminates the need to track policies across multiple locations, making it easier to understand, manage, and troubleshoot L7 security configurations.

{{< image width="100%"
link="policies-enforced (1).svg"
caption="Policy Enforced on Destination Waypoint"
>}}

- **Mixed Environment**: In a mixed environment where clients may reside inside or outside the Istio mesh, destination-only Waypoint ensures consistent policy enforcement regardless of the client's location. Since all policies are applied at the destination workload, users can be confident that security measures are consistently applied to all incoming traffic.

{{< image width="100%"
link="mixed-environment.svg"
caption="Waypoint Proxies"
>}}

### Handling Destinations without Waypoint Proxies

While destination-only Waypoint offers centralized policy enforcement and simplified configuration, there may be instances where the destination workload doesn't have a waypoint proxy deployed. This could arise when connecting to external services beyond the control of the Istio mesh.

To address this scenario, the Istio community is actively developing mechanisms to route traffic to the egress gateway and enable policy enforcement for destinations without waypoint proxies. This functionality will allow users to configure resilience-enhancing policies, such as timeouts, for external services.

Please stay tuned for future blog posts and documentation updates that will provide detailed information on this evolving feature.

## Deploying an Application

When someone with Istio admin privileges sets up Istio mesh, it becomes available for all users in specific namespaces. The examples below shows how Istio can be used transparently once it's successfully deployed in ambient mode and the namespaces are annotated accordingly.

### Basic application deployment without Ambient

This section is Under Construction...