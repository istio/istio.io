---
title: "Ambient Mesh Security Deep Dive"
description: "Digging into the security implications of the recently announced Istio ambient mesh, a sidecar-less data plane for Istio."
publishdate: 2022-09-07T09:00:00-06:00
attribution: "Ethan Jackson (Google), Yuval Kohavi (Solo.io), Justin Pettit (Google), Christian Posta (Solo.io)"
keywords: [ambient]
---

We recently announced Istio ambient mesh which is a sidecar-less data plane for Istio. As [stated in the announcement blog](/blog/2022/introducing-ambient-mesh/), the top concerns we address with ambient mesh are simplified operations, broader application compatibility, reduced infrastructure costs and improved performance. When designing the ambient data plane, we wanted to carefully balance the concerns around operations, cost, and performance while not sacrificing security or functionality. As the components of ambient run outside of the application pods, the security boundaries have changed -- we believe for the better. In this blog, we go into some detail about these changes and how they compare to a sidecar deployment.

{{< image link="./ambient-layers.png" caption="Layering of ambient mesh data plane" >}}

To recap, Istio ambient mesh introduces a layered mesh data plane with a secure overlay responsible for transport security and routing, that has the option to add L7 capabilities for namespaces that need them.
To understand more, please see the [announcement blog](/blog/2022/introducing-ambient-mesh/) and the [getting started blog](/blog/2022/get-started-ambient).
The secure overlay consists of a node-shared component, the ztunnel, that is responsible for L4 telemetry and mTLS which is deployed as a DaemonSet.
The L7 layer of the mesh is provided by waypoint proxies, full L7 Envoy proxies that are deployed per identity/workload type.
Some of the core implications of this design include:

* Separation of application from data plane
* Components of the secure overlay layer resemble that of a CNI
* Simplicity of operations is better for security
* Avoiding multi-tenant L7 proxies
* Sidecars are still a first-class supported deployment

## Separation of application and data plane

Although the primary goal of ambient mesh is simplifying operations of the service mesh, it does serve to improve security as well. Complexity breeds vulnerabilities and enterprise applications (and their transitive dependencies, libraries, and frameworks) are exceedingly complex and prone to vulnerabilities. From handling complex business logic to leveraging OSS libraries or buggy internal shared libraries, a user's application code is a prime target for attackers (internal or external). If an application is compromised, credentials, secrets, and keys are exposed to an attacker including those mounted or stored in memory. When looking at the sidecar model, an application compromise includes takeover of the sidecar and any associated identity/key material. In the Istio ambient mode, no data plane components run in the same pod as the application and therefore an application compromise does not lead to the access of secrets.

What about Envoy Proxy as a potential target for vulnerabilities? Envoy is an extremely hardened piece of infrastructure under intense scrutiny and [run at scale in critical environments](https://www.infoq.com/news/2018/12/envoycon-service-mesh/) (e.g., [used in production to front Google's network](https://cloud.google.com/load-balancing/docs/https)). However, since Envoy is software, it is not immune to vulnerabilities.  When those vulnerabilities do arise, Envoy has a robust CVE process for identifying them, fixing them quickly, and rolling them out to customers before they have the chance for wide impact.

Circling back to the earlier comment that "complexity breeds vulnerabilities", the most complex parts of Envoy Proxy is in its L7 processing, and indeed historically the majority of Envoy’s vulnerabilities have been in its L7 processing stack. But what if you just use Istio for mTLS? Why take the risk of deploying a full-blown L7 proxy which has a higher chance of CVE when you don't use that functionality? Separating L4 and L7 mesh capabilities comes into play here. While in sidecar deployments you adopt all of the proxy, even if you use only a fraction of the functionality, in ambient mode we can limit the exposure by providing a secure overlay and only layering in L7 as needed. Additionally, the L7 components run completely separate from the applications and do not give an attack avenue.

## Pushing L4 down into the CNI

The L4 components of the ambient data plane run as a DaemonSet, or one per node. This means it is shared infrastructure for any of the pods running on a particular node. This component is particularly sensitive and should be treated at the same level as any other shared component on the node such as any CNI agents, kube-proxy, kubelet, or even the Linux kernel. Traffic from workloads is redirected to the ztunnel which then identifies the workload and selects the right certificates to represent that workload in a mTLS connection.

The ztunnel uses a distinct credential for every pod which is only issued if the pod is currently running on the node. This ensures that the blast radius for a compromised ztunnel is that only credentials for pods currently scheduled on that node could be stolen. This is a similar property to other well implemented shared node infrastructure including other secure CNI implementations. The ztunnel does not use cluster-wide or per-node credentials which, if stolen, could immediately compromise all application traffic in the cluster unless a complex secondary authorization mechanism is also implemented.

If we compare this to the sidecar model, we notice that the ztunnel is shared and compromise could result in exfiltration of the identities of the applications running on the node. However, the likelihood of a CVE in this component is lower than that of an Istio sidecar since the attack surface is greatly reduced (only L4 handling); the ztunnel does not do any L7 processing. In addition, a CVE in a sidecar (with a larger attack surface with L7) is not truly contained to only that particular workload which is compromised. Any serious CVE in a sidecar is likely repeatable to any of the workloads in the mesh as well.

## Simplicity of operations is better for security

Ultimately, Istio is a critical piece of infrastructure that must be maintained. Istio is trusted to implement some of the tenets of zero-trust network security on behalf of applications and rolling out patches on a schedule or on demand is paramount. Platform teams often have predictable patching or maintenance cycles which is quite different from that of applications. Applications likely get updated when new capabilities and functionality are required and usually part of a project. This approach to application changes, upgrades, framework and library patches, is highly unpredictable, allows a lot of time to pass, and does not lend itself to safe security practices. Therefore, keeping these security features part of the platform and separate from the applications is likely to lead to a better security posture.

As we've identified in the announcement blog, operating sidecars can be more complex because of the invasive nature of them (injecting the sidecar/changing the deployment descriptors, restarting the applications, race conditions between containers, etc). Upgrades to workloads with sidecars require a bit more planning and rolling restarts that may need to be coordinated to not bring down the application. With ambient mesh, upgrades to the ztunnel can coincide with any normal node patching or upgrades, while the waypoint proxies are part of the network and can be upgraded completely transparently to the applications as needed.

## Avoiding multi-tenant L7 proxies

Supporting L7 protocols such as HTTP 1/2/3, gRPC, parsing headers, implementing retries, customizations with Wasm and/or Lua in the data plane is significantly more complex than supporting L4. There is a lot more code to implement these behaviors (including user-custom code for things like Lua and Wasm) and this complexity can lead to the potential for vulnerabilities. Because of this, CVEs have a higher chance of being discovered in these areas of L7 functionality.

{{< image link="./ambient-l7-data-plane.png" caption="Each namespace/identity has its own L7 proxies; no multi-tenant proxies" >}}

In ambient mesh, we do not share L7 processing in a proxy across multiple identities. Each identity (service account in Kubernetes) has its own dedicated L7 proxy (waypoint proxy) which is very similar to the model we use with sidecars. Trying to co-locate multiple identities and their distinct complex policies and customizations adds a lot of variability to a shared resource which leads to unfair cost attribution at best and total proxy compromise at worst.

## Sidecars are still a first-class supported deployment

We understand that some folks are comfortable with the sidecar model and their known security boundaries and wish to stay on that model. With Istio, sidecars are a first-class citizen to the mesh and platform owners have the choice to continue using them. If a platform owner wants to support both sidecar and ambient, they can. A workload with the ambient data plane can natively communicate with workloads that have a sidecar deployed. As folks better understand the security posture of ambient mesh, we are confident that ambient will be the preferred mode of Istio service mesh with sidecars used for specific optimizations.
