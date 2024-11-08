---
title: "Fast, Secure, and Simple: Istio’s Ambient Mode Reaches General Availability in v1.24"
description: Our latest release signals ambient mode – service mesh without sidecars – is ready for everyone.
publishdate: 2024-11-07
attribution: "Lin Sun (Solo.io), for the Istio Steering and Technical Oversight Committees"
keywords: [ambient,sidecars]
---

We are proud to announce that Istio’s ambient data plane mode has reached General Availability, with the ztunnel, waypoints and APIs being marked as Stable by the Istio TOC. This marks the final stage in Istio's [feature phase progression](/docs/releases/feature-stages/), signaling that ambient mode is fully ready for broad production usage.

Ambient mesh — and its reference implementation with Istio’s ambient mode — [was announced in September 2022](/blog/2022/introducing-ambient-mesh/). Since then, our community has put in 26 months of hard work and collaboration, with contributions from Solo.io, Google, Microsoft, Intel, Aviatrix, Huawei, IBM, Red Hat, and many others. Stable status in 1.24 indicates the features of ambient mode are now fully ready for broad production workloads. This is a huge milestone for Istio, bringing Istio to production readiness without sidecars, and [offering users a choice](/docs/overview/dataplane-modes/).

## Why ambient mesh?

From the launch of Istio in 2017, we have observed a clear and growing demand for mesh capabilities for applications — but heard that many users found the resource overhead and operational complexity of sidecars hard to overcome. Challenges that Istio users shared with us include how sidecars can break applications after they are added, the large CPU and memory requirement for a proxy with every workload, and the inconvenience of needing to restart application pods with every new Istio release.

As a community, we designed ambient mesh from the ground up to tackle these problems, alleviating the previous barriers of complexity faced by users looking to implement service mesh. The new concept was named  ‘ambient mesh’ as it was designed to be transparent to your application, with no proxy infrastructure collocated with user workloads, no subtle changes to configuration required to onboard, and no application restarts required.
In ambient mode it is trivial to add or remove applications from the mesh. All you need to do is [label a namespace](/docs/ambient/usage/add-workloads/), and all applications in that namespace are instantly added to the mesh. This immediately secures all traffic within that namespace with industry-standard mutual TLS encryption — no other configuration or restarts required!.
Refer to the [Introducing Ambient Mesh blog](/blog/2022/introducing-ambient-mesh/) for more information on why we built Istio’s ambient mode.

## How does ambient mode make adoption easier?

The core innovation behind ambient mesh is that it slices Layer 4 (L4) and Layer 7 (L7) processing into two distinct layers. Istio’s ambient mode is powered by lightweight, shared L4 node proxies and optional L7 proxies, removing the need for traditional sidecar proxies from the data plane. This layered approach allows you to adopt Istio incrementally, enabling a smooth transition from no mesh, to a secure overlay (L4), to optional full L7 processing — on a per-namespace basis, as needed, across your fleet.

By utilizing ambient mesh, users bypass some of the previously restrictive elements of the sidecar model. Server-send-first protocols now work, most reserved ports are now available, and the ability for containers to bypass the sidecar — either maliciously or not — is eliminated.

The lightweight shared L4 node proxy is called the *[ztunnel](/docs/ambient/overview/#ztunnel)* (zero-trust tunnel). ztunnel drastically reduces the overhead of running a mesh by removing the need to potentially over-provision memory and CPU within a cluster to handle expected loads. In some use cases, the savings can exceed 90% or more, while still providing zero-trust security using mutual TLS with cryptographic identity, simple L4 authorization policies, and telemetry.

The L7 proxies are called *[waypoints](/docs/ambient/overview/#waypoint-proxies)*. Waypoints process L7 functions such as traffic routing, rich authorization policy enforcement, and enterprise-grade resilience. Waypoints run outside of your application deployments and can scale independently based on your needs, which could be for the entire namespace or for multiple services within a namespace. Compared with sidecars, you don’t need one waypoint per application pod, and you can scale your waypoint effectively based on its scope, thus saving significant amounts of CPU and memory in most cases.

The separation between the L4 secure overlay layer and L7 processing layer allows incremental adoption of the ambient mode data plane, in contrast to the earlier binary "all-in" injection of sidecars. Users can start with the secure L4 overlay, which offers a majority of features that people deploy Istio for (mTLS, authorization policy, and telemetry). Complex L7 handling such as retries, traffic splitting, load balancing, and observability collection can then be enabled on a case-by-case basis.

## Rapid exploration and adoption of ambient mode

The ztunnel image on Docker Hub has reached over [1 million downloads](https://hub.docker.com/search?q=istio), with ~63,000 pulls in the last week alone.

{{< image width="100%"
    link="./ztunnel-image.png"
    alt="Docker Hub downloads of Istio ztunnel!"
    >}}

We asked a few of our users for their thoughts on ambient mode’s GA:

{{< quote >}}
**Istio's implementation of a service mesh with their ambient mesh design has been a great addition to our Kubernetes clusters to simplify the team responsibilities and overall network architecture of the mesh. In conjunction with the Gateway API project it has given me a great way to enable developers to get their networking needs met at the same time as only delegating as much control as needed. While it's a rapidly evolving project it has been solid and dependable in production and will be our default option for implementing networking controls in a Kubernetes deployment going forth.**

— [Daniel Loader](https://uk.linkedin.com/in/danielloader), Lead Platform Engineer at Quotech

{{< /quote >}}

{{< quote >}}
**It is incredibly easy to install ambient mesh with the Helm chart wrapper. Migrating is as simple as setting up a waypoint gateway, updating labels on a namespace, and restarting. I’m looking forward to ditching sidecars and recuperating resources. Moreover, easier upgrades. No more restarting deployments!**

— [Raymond Wong](https://www.linkedin.com/in/raymond-wong-43baa8a2/), Senior Architect at Forbes
{{< /quote >}}

{{< quote >}}
**Istio’s ambient mode has served our production system since it became Beta. We are pleased by its stability and simplicity and are looking forward to additional benefits and features coming together with the GA status. Thanks to the Istio team for the great efforts!**

— Saarko Eilers, Infrastructure Operations Manager at EISST International Ltd
{{< /quote >}}

{{< quote >}}
**By Switching from AWS App Mesh to Istio in ambient mode, we were able to slash about 45% of the running containers just by removing sidecars and SPIRE agent DaemonSets. We gained many benefits, such as reducing compute costs or observability costs related to sidecars, eliminating many of the race conditions related to sidecars startup and shutdown, plus all the out-of-the-box benefits just by migrating, like mTLS, zonal awareness and workload load balancing.**

— [Ahmad Al-Masry](https://www.linkedin.com/in/ahmad-al-masry-9ab90858/), DevSecOps Engineering Manager at Harri
{{< /quote >}}

{{< quote >}}
**We chose Istio because we're excited about ambient mesh. Different from other options, with Istio, the transition from sidecar to sidecar-less is not a leap of faith. We can build up our service mesh infrastructure with Istio knowing the path to sidecar-less is a two way door.**

— [Troy Dai](https://www.linkedin.com/in/troydai/), Senior Staff Software Engineer at Coinbase
{{< /quote >}}

{{< quote >}}
**Extremely proud to see the fast and steady growth of ambient mode to GA, and all the amazing collaboration that took place over the past months to make this happen! We are looking forward to finding out how the new architecture is going to revolutionize the telcos world.**

— [Faseela K](https://www.linkedin.com/in/faseela-k-42178528/), Cloud Native Developer at Ericsson
{{< /quote >}}

{{< quote >}}
**We are excited to see the Istio dataplane evolve with the GA release of ambient mode and are actively evaluating it for our next-generation infrastructure platform. Istio's community is dynamic and welcoming, and ambient mesh is a testament to the community embracing new ideas and pragmatically working to improve developer experience operating Istio at scale.**

— [Tyler Schade](https://www.linkedin.com/in/tylerschade/), Distinguished Engineer at GEICO Tech
{{< /quote >}}

{{< quote >}}
**With Istio’s ambient mode reaching GA, we finally have a service mesh solution that isn’t tied to the pod lifecycle, addressing a major limitation of sidecar-based models. Ambient mesh provides a more lightweight, scalable architecture that simplifies operations and reduces our infrastructure costs by eliminating the resource overhead of sidecars.**

— [Bartosz Sobieraj](https://www.linkedin.com/in/bartoszsobieraj/), Platform Engineer at Spond
{{< /quote >}}

{{< quote >}}
**Our team chose Istio for its service mesh features and strong alignment with the Gateway API to create a robust Kubernetes-based hosting solution. As we integrated applications into the mesh, we faced resource challenges with sidecar proxies, prompting us to transition to ambient mode in Beta for improved scalability and security. We started with L4 security and observability through ztunnel, gaining automatic encryption of in-cluster traffic and transparent traffic flow monitoring. By selectively enabling L7 features and decoupling the proxy from applications, we achieved seamless scaling and reduced resource utilization and latency. This approach allowed developers to focus on application development, resulting in a more resilient, secure, and scalable platform powered by ambient mode.**

— [Jose Marques](https://www.linkedin.com/in/jdcmarques/), Senior DevOps at Blip.pt
{{< /quote >}}

{{< quote >}}
**We are using Istio to ensure strict mTLS L4 traffic in our mesh and we are excited for ambient mode. Compared to sidecar mode it's a massive save on resources and at the same time it makes configuring things even more simple and transparent.**

— [Andrea Dolfi](https://www.linkedin.com/in/andrea-dolfi-58b427128/), DevOps Engineer
{{< /quote >}}

## What is in scope?

The general availability of ambient mode means the following things are now considered stable:

- [Installing Istio with support for ambient mode](/docs/ambient/install/), with Helm or `istioctl`.
- [Adding your workloads to the mesh](/docs/ambient/usage/add-workloads/) to gain mutual TLS with cryptographic identity, [L4 authorization policies](/docs/ambient/usage/l4-policy/), and telemetry.
- [Configuring waypoints](/docs/ambient/usage/waypoint/) to [use L7 functions](/docs/ambient/usage/l7-features/) such as traffic shifting, request routing, and rich authorization policy enforcement.
- Connecting the Istio ingress gateway to workloads in ambient mode, supporting the Kubernetes Gateway APIs and all existing Istio APIs.
- Using waypoints for controlled mesh egress
- Using `istioctl` to operate waypoints, and troubleshoot ztunnel & waypoints.

Refer to the [feature status page](/docs/releases/feature-stages/#ambient-mode) for more information.

### Roadmap

We are not standing still! There are a number of features that we continue to work on for future releases, including some that are currently in Alpha/Beta.

In our upcoming releases, we expect to move quickly on the following extensions to ambient mode:

- Full support for sidecar and ambient mode interoperability
- Multi-cluster installations
- Multi-network support
- VM support

## What about sidecars?

Sidecars are not going away, and remain first-class citizens in Istio. You can continue to use sidecars, and they will remain fully supported. While we believe most use cases will be best served with a mesh in ambient mode, the Istio project remains committed to ongoing sidecar mode support.

## Try ambient mode today

With the 1.24 release of Istio and the GA release of ambient mode, it is now easier than ever to try out Istio on your own workloads.

- Follow the [getting started guide](/docs/ambient/getting-started/) to explore ambient mode.
- Read our [user guides](/docs/ambient/usage/) to learn how to incrementally adopt ambient for mutual TLS & L4 authorization policy, traffic management, rich L7 authorization policy, and more.
- Explore the [new Kiali 2.0 dashboard](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e) to visualize your mesh.

You can engage with the developers in the #ambient channel on [the Istio Slack](https://slack.istio.io), or use the discussion forum on [GitHub](https://github.com/istio/istio/discussions) for any questions you may have.
