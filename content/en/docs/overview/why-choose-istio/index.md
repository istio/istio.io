---
title: Why choose Istio?
description: Compare Istio to other service mesh solutions.
weight: 20
keywords: [comparison]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio pioneered the concept of a sidecar-based service mesh when it launched in 2017. Out of the gate, the project included the features that would come to define a service mesh, including standards-based mutual TLS for zero-trust networking, smart traffic routing, and observability through metrics, logs and tracing.

Since then, the project has driven advances in the mesh space including [multi-cluster & multi-network topologies](/docs/ops/deployment/deployment-models/), [extensibility via WebAssembly](/docs/concepts/wasm/), the [development of the Kubernetes Gateway API](/blog/2022/gateway-api-beta/), and moving the mesh infrastructure away from application developers with [ambient mode](/docs/ambient/overview/).

Here are a few reasons we think you should use Istio as your service mesh.

## Simple and powerful

Kubernetes has hundreds of features and dozens of APIs, but you can get started with it with just one command. We've built Istio to be the same way. Progressive disclosure means you can use a small set of APIs, and only turn the more powerful knobs if you have the need. Other "simple" service meshes spent years catching up to the feature set Istio had on day 1.

It is better to have a feature and not need it, than to need it and not have it!

## The Envoy proxy {#envoy}

From the beginning, Istio has been powered by the {{< gloss >}}Envoy{{< /gloss >}} proxy, a high performance service proxy initially built by Lyft. Istio was the first project to adopt Envoy, and [the Istio team were the first external committers](https://eng.lyft.com/envoy-7-months-later-41986c2fd443). Envoy would go on to become [the load balancer that powers Google Cloud](https://cloud.google.com/load-balancing/docs/https) as well as the proxy for almost every other service mesh platform.

Istio inherits all the power and flexibility of Envoy, including world-class extensibility using WebAssembly that was [developed in Envoy by the Istio team](/blog/2020/wasm-announce/).

## Community

Istio is a true community project. In 2023, there were 10 companies who made over 1,000 contributions each to Istio, with no single company exceeding 25%. ([See the numbers here](https://istio.devstats.cncf.io/d/5/companies-table?var-period_name=Last%20year&var-metric=contributions&orgId=1)).

No other service mesh project has the breadth of support from the industry as Istio.

## Packages

We make stable binary releases available to everyone, with every release, and commit to continue doing so. We publish free and regular security patches for [our latest release and a number of prior releases](/docs/releases/supported-releases/). Many of our vendors will support older versions, but we believe that engaging a vendor should not be a requirement to be safe in a stable open source project.

## Alternatives considered

A good design document includes a section on alternatives that were considered, and ultimately rejected.

### Why not "use eBPF"?

We do - where it's appropriate! Istio can be configured to use {{< gloss >}}eBPF{{< /gloss >}} [to route traffic from pods to proxies](/blog/2022/merbridge/). This shows a small performance increase over using `iptables`.

Why not use it for everything? No-one does, because no-one actually can.

eBPF is a virtual machine that runs inside the Linux kernel. It was designed for functions guaranteed to complete in a limited compute envelope to avoid destabilizing kernel behavior, such as those that perform simple L3 traffic routing or application observability. It was not designed for long running or complex functions like those found in Envoy: that's why operating systems have [user space](https://en.wikipedia.org/wiki/User_space_and_kernel_space)! eBPF maintainers have theorized that it could eventually be extended to support running a program as complex as Envoy, but this is a science project and unlikely to have real world practicality.

Other meshes that claim to "use eBPF" actually use a per-node Envoy proxy, or other user space tools, for much of their functionality.

### Why not use a per-node proxy?

Envoy is not inherently multi-tenant. As a result, we have major security and stability concerns with commingling complex processing rules for L7 traffic from multiple unconstrained tenants in a shared instance. Since Kubernetes, by default can schedule a pod from any namespace onto any node, the node is not an appropriate tenancy boundary. Budgeting and cost attribution are also major issues, as L7 processing costs a lot more than L4.

In ambient mode, we strictly limit our ztunnel proxy to L4 processing - [just like the Linux kernel](https://blog.howardjohn.info/posts/ambient-spof/). This reduces the vulnerability surface area significantly, and allows us to safely operate a shared component. Traffic is then forwarded off to Envoy proxies that operate per-namespace, such that no Envoy proxy is ever multi-tenant.

## I have a CNI. Why do I need Istio?

Today, some CNI plugins are starting to offer service mesh-like functionality as an add-on that sits on top of their own CNI implementation. For example, they may implement their own encryption schemes for traffic between nodes or pods, workload identity, or support some amount of transport-level policy by redirecting traffic to a L7 proxy. These service mesh addons are non-standard, and as such can only work on top of the CNI that ships them. They also offer varying feature sets. For example, solutions built on top of Wireguard cannot be made FIPS-compliant.

For this reason, Istio has implemented its zero-trust tunnel (ztunnel) component, which transparently and efficiently provides this functionality using proven, industry-standard encryption protocols. [Learn more about ztunnel](/docs/ambient/overview).

Istio is designed to be a service mesh that provides a consistent, highly secure, efficient, and standards-compliant service mesh implementation providing a [powerful set of L7 policies](/docs/concepts/security/#authorization), [platform-agnostic workload identity](/docs/concepts/security/#istio-identity), using [industry-proven mTLS protocols](/docs/concepts/security/#mutual-tls-authentication) - in any environment, with any CNI, or even across clusters with different CNIs.
