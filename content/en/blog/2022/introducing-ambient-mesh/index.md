---
title: "Introducing Ambient Mesh"
description: "A new dataplane mode for Istio without sidecars."
publishdate: 2022-09-07T07:00:00-06:00
attribution: "John Howard (Google), Ethan J. Jackson (Google), Yuval Kohavi (Solo.io), Idit Levine (Solo.io), Justin Pettit (Google), Lin Sun (Solo.io)"
keywords: [ambient]
---

Today, we are excited to introduce "ambient mesh", a new Istio data plane mode that’s designed for simplified operations, broader application compatibility, and reduced infrastructure cost. Ambient mesh gives users the option to forgo sidecar proxies in favor of a mesh data plane that’s integrated into their infrastructure, all while maintaining Istio’s core features of zero-trust security, telemetry, and traffic management.  We are sharing a preview of ambient mesh with the Istio community that we are working to bring to production readiness in the coming months.

## Istio and sidecars

Since its inception, a defining feature of Istio’s architecture has been the use of _sidecars_ – programmable proxies deployed alongside application containers.  Sidecars allow operators to reap Istio’s benefits, without requiring applications to undergo major surgery and its associated costs.

{{< image width="100%"
    link="traditional-istio.png"
    caption="Istio’s traditional model deploys Envoy proxies as sidecars within the workloads’ pods"
    >}}

Although sidecars have significant advantages over refactoring applications, they do not provide a perfect separation between applications and the Istio data plane. This results in a few limitations:

* **Invasiveness** - Sidecars must be "injected" into applications by modifying their Kubernetes pod spec and redirecting traffic within the pod.   As a result, installing or upgrading sidecars requires restarting the application pod, which can be disruptive for workloads.
* **Underutilization of resources** - Since the sidecar proxy is dedicated to its associated workload, the CPU and memory resources must be provisioned for worst case usage of each individual pod. This adds up to large reservations that can lead to underutilization of resources across the cluster.
* **Traffic breaking** - Traffic capture and HTTP processing, as typically done by Istio’s sidecars, is computationally expensive and can break some applications with non-conformant HTTP implementations.

While sidecars have their place — more on that later — we think there is a need for a less invasive and easier option that will be a better fit for many service mesh users.

## Slicing the layers

Traditionally, Istio implements all data plane functionality, from basic encryption through advanced L7 policy, in a single architectural component: the sidecar.
In practice, this makes sidecars an all-or-nothing proposition.
Even if a workload just needs simple transport security, administrators still need to pay the operational cost of deploying and maintaining a sidecar.
Sidecars have a fixed operational cost per workload that does not scale to fit the complexity of the use case.

Ambient mesh takes a different approach.
It splits Istio’s functionality into two distinct layers.
At the base, there’s a secure overlay that handles routing and zero trust security for traffic.
Above that, when needed, users can enable L7 processing to get access to the full range of Istio features.
The L7 processing mode, while heavier than the secure overlay, still runs as an ambient component of the infrastructure, requiring no modifications to application pods.

{{< image width="100%"
    link="ambient-layers.png"
    caption="Layers of the ambient mesh"
    >}}

This layered approach allows users to adopt Istio in a more incremental fashion, smoothly transitioning from no mesh, to the secure overlay, to full L7 processing — on a per-namespace basis, as needed.   Furthermore, workloads running in different ambient modes, or with sidecars, interoperate seamlessly, allowing users to mix and match capabilities based on the particular needs as they change over time.

## Building an ambient mesh

Ambient mesh uses a shared agent, running on each node in the Kubernetes cluster.  This agent is a zero-trust tunnel (or **_ztunnel_**), and its primary responsibility is to securely connect and authenticate elements within the mesh.  The networking stack on the node redirects all traffic of participating workloads through the local ztunnel agent. This fully separates the concerns of Istio’s data plane from those of the application, ultimately allowing operators to enable, disable, scale, and upgrade the data plane without disturbing applications. The ztunnel performs no L7 processing on workload traffic, making it significantly leaner than sidecars.  This large reduction in complexity and associated resource costs make it amenable to delivery as shared infrastructure.

Ztunnels enable the core functionality of a service mesh: zero trust.  A secure overlay is created when ambient is enabled for a namespace.  It provides workloads with mTLS, telemetry, authentication, and L4 authorization, without terminating or parsing HTTP.

{{< image width="100%"
    link="ambient-secure-overlay.png"
    caption="Ambient mesh uses a shared, per-node ztunnel to provide a zero-trust secure overlay"
    >}}

After ambient mesh is enabled and a secure overlay is created, a namespace can be configured to utilize L7 features.
This allows a namespace to implement the full set of Istio capabilities, including the [Virtual Service API](/docs/reference/config/networking/virtual-service/), [L7 telemetry](/docs/reference/config/telemetry/), and [L7 authorization policies](/docs/reference/config/security/authorization-policy/).
Namespaces operating in this mode use one or more Envoy-based **_waypoint proxies_** to handle L7 processing for workloads in that namespace.
Istio’s control plane configures the ztunnels in the cluster to pass all traffic that requires L7 processing through the waypoint proxy.
Importantly, from a Kubernetes perspective, waypoint proxies are just regular pods that can be auto-scaled like any other Kubernetes deployment.
We expect this to yield significant resource savings for users, as the waypoint proxies can be auto-scaled to fit the real time traffic demand of the namespaces they serve, not the maximum worst-case load operators expect.

{{< image width="100%"
    link="ambient-waypoint.png"
    caption="When additional features are needed, ambient mesh deploys waypoint proxies, which ztunnels connect through for policy enforcement"
    >}}

Ambient mesh uses HTTP CONNECT over mTLS to implement its secure tunnels and insert waypoint proxies in the path, a pattern we call HBONE (HTTP-Based Overlay Network Environment). HBONE provides for a cleaner encapsulation of traffic than TLS on its own while enabling interoperability with common load-balancer infrastructure. FIPS builds are used by default to meet compliance needs. More details on HBONE, its standards-based approach, and plans for UDP and other non-TCP protocols will be provided in a future blog.

Mixing sidecars and ambient in a single mesh does not introduce limitations on the capabilities or security properties of the system. The Istio control plane ensures that policies are properly enforced regardless of the deployment model chosen. Ambient simply introduces an option that has better ergonomics and more flexibility.

## Why no L7 processing on the local node?

The ambient mesh uses a shared ztunnel agent on the node, which handles the zero trust aspects of the mesh, while L7 processing happens in the waypoint proxy in separately scheduled pods. Why bother with the indirection, and not just use a shared full L7 proxy on the node?  There are several reasons for this:

* Envoy is not inherently multi-tenant. As a result, we have security concerns with commingling complex processing rules for L7 traffic from multiple unconstrained tenants in a shared instance. By strictly limiting to L4 processing, we reduce the vulnerability surface area significantly.
* The mTLS and L4 features provided by the ztunnel need a much smaller CPU and memory footprint when compared to the L7 processing required in the waypoint proxy. By running waypoint proxies as a shared namespace resource, we can scale them independently based on the needs of that namespace, and its costs are not unfairly distributed across unrelated tenants.
* By reducing ztunnel’s scope we allow for it to be replaced by other secure tunnel implementations that can meet a well-defined interoperability contract.

## But what about those extra hops?

With ambient mesh, a waypoint isn’t necessarily guaranteed to be on the same node as the workloads it serves. While at first glance this may appear to be a performance concern, we’re confident that latency will ultimately be in-line with Istio’s current sidecar implementation. We’ll discuss more in a dedicated performance blog post, but for now we’ll summarize with two points:

* The majority of Istio’s network latency does not, in fact, come from the network ([modern cloud providers have extremely fast networks)](https://www.clockwork.io/there-is-no-upside-to-vm-colocation/).  Instead the biggest culprit is the intensive L7 processing Istio needs to implement its sophisticated feature set.  Unlike sidecars, which implement two L7 processing steps for each connection (one for each sidecar), ambient mesh collapses these two steps into one.  In most cases, we expect this reduced processing cost to compensate for an additional network hop.
* Users often deploy a mesh to enable a zero-trust security posture as a first-step and then selectively enable L7 capabilities as needed.  Ambient mesh allows those users to bypass the cost of L7 processing entirely when it’s not needed.

## Resource overhead

Overall we expect ambient mesh to have fewer and more predictable resource requirements for most users.
The ztunnel’s limited responsibilities allows it to be deployed as a shared resource on the node.
This will substantially reduce the per-workload reservations required for most users.
Furthermore, since the waypoint proxies are normal Kubernetes pods, they can be dynamically deployed and scaled based on the real-time traffic demands of the workloads they serve.

Sidecars, on the other hand, need to reserve memory and CPU for the worst case for each workload.
Making these calculations are complicated, so in practice administrators tend to over-provision.
This leads to underutilized nodes due to high reservations that prevent other workloads from being scheduled.
Ambient mesh’s lower fixed per-node overhead and dynamically scaled waypoint proxies will require far fewer resource reservations in aggregate, leading to more efficient use of a cluster.

## What about security?

With a radically new architecture naturally comes questions around security.  The [ambient security blog](/blog/2022/ambient-security/) does a deep dive, but we’ll summarize here.

Sidecars co-locate with the workloads they serve and as a result, a vulnerability in one compromises the other.
In the ambient mesh model, even if an application is compromised, the ztunnels and waypoint proxies can still enforce strict security policy on the compromised application’s traffic.
Furthermore, given that Envoy is a mature battle-tested piece of software used by the world's largest network operators, it is likely less vulnerable than the applications it runs alongside.

While the ztunnel is a shared resource, it only has access to the keys of the workloads currently on the node it’s running.
Thus, its blast radius is no worse than any other encrypted CNI that relies on per-node keys for encryption.
Also, given the ztunnel’s limited L4 only attack surface area and Envoy’s aforementioned security properties, we feel this risk is limited and acceptable.

Finally, while the waypoint proxies are a shared resource, they are limited to serving just one service account.
This makes them no worse than sidecars are today; if one waypoint proxy is compromised, the credential associated with that waypoint is lost, and nothing else.

## Is this the end of the road for the sidecar?

Definitely not.
While we believe ambient mesh will be the best option for many mesh users going forward, sidecars continue to be a good choice for those that need dedicated data plane resources, such as for compliance or performance tuning.
Istio will continue to support sidecars, and importantly, allow them to interoperate seamlessly with ambient mesh.
In fact, the ambient mesh code we’re releasing today already supports interoperation with sidecar-based Istio.

## Learn more

Take a look at a short video to watch Christian run through the Istio ambient mesh components and demo some capabilities:

<iframe width="560" height="315" src="https://www.youtube.com/embed/nupRBh9Iypo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Get involved

What we have released today is an early version of ambient mesh in Istio, and it is very much still under active development. We are excited to share it with the broader community and look forward to getting more people involved in shaping it as we move to production readiness in 2023.

We would love your feedback to help shape the solution.
A build of Istio which supports ambient mesh is available to [download and try](/blog/2022/get-started-ambient/) in the [Istio Experimental repo]({{< github_raw >}}/tree/experimental-ambient).
A list of missing features and work items is available in the [README]({{< github_raw >}}/blob/experimental-ambient/README.md).
Please try it out and [let us know what you think!](https://slack.istio.io/)

_Thank you to the team that contributed to the launch of ambient mesh!_
* _Google: Craig Box, John Howard, Ethan J. Jackson, Abhi Joglekar, Steven Landow, Oliver Liu, Justin Pettit, Doug Reid, Louis Ryan, Kuat Yessenov, Francis Zhou_
* _Solo.io: Aaron Birkland, Kevin Dorosh, Greg Hanson, Daniel Hawton, Denis Jannot, Yuval Kohavi, Idit Levine, Yossi Mesika, Neeraj Poddar, Nina Polshakova, Christian Posta, Lin Sun, Eitan Yarmush_
