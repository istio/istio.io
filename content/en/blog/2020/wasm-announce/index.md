---
title: Redefining extensibility in proxies - introducing WebAssembly to Envoy and Istio
subtitle: A new interface for extending proxy servers allows moving Istio extensibility from the control plane into the sidecar proxies themselves
description: The future of Istio extensibility using WASM.
publishdate: 2020-03-05
attribution: "Craig Box, Mandar Jog, John Plevyak, Louis Ryan, Piotr Sikora (Google), Yuval Kohavi, Scott Weiss (Solo.io)"
keywords: [wasm,extensibility,alpha,performance,operator]
---

Since adopting [Envoy](https://www.envoyproxy.io/) in 2016, the Istio project has always wanted to
provide a platform on top of which a rich set of extensions could be built, to meet the diverse
needs of our users. There are many reasons to add capability to the data plane of a service
mesh --- to support newer protocols, integrate with proprietary security controls, or enhance
observability with custom metrics, to name a few.

Over the last year and a half our team here at Google has been working on adding dynamic
extensibility to the Envoy proxy using [WebAssembly](https://webassembly.org/). We are delighted to
share that work with the world today, as well as
unveiling [WebAssembly (Wasm) for Proxies](https://github.com/proxy-wasm/spec) (Proxy-Wasm): an ABI,
which we intend to standardize; SDKs; and its first major implementation, the new,
lower-latency [Istio telemetry system](/docs/reference/config/telemetry).

We have also worked closely with the community to ensure that there is a great developer experience
for users to get started quickly. The Google team has been working closely with the team
at [Solo.io](https://solo.io) who have built the [WebAssembly Hub,](https://webassemblyhub.io/)
a service for building, sharing, discovering and deploying Wasm extensions.
With the WebAssembly Hub, Wasm extensions are as easy to manage, install and and run as containers.

This work is being released today in Alpha and there is still lots
of [work to be done](#next-steps), but we are excited to get this into the hands of developers
so they can start experimenting with the tremendous possibilities this opens up.

## Background

The need for extensibility has been a founding tenet of both the Istio and Envoy projects,
but the two projects took different approaches. Istio project focused on enabling a generic
out-of-process extension model called [Mixer](/docs/reference/config/policy-and-telemetry/mixer-overview/)
with a lightweight developer experience, while Envoy focused on in-proxy [extensions](https://www.envoyproxy.io/docs/envoy/latest/extending/extending).

Each approach has its share of pros and cons. The Istio model led to significant resource
inefficiencies that impacted tail latencies and resource utilization. This model was also
intrinsically limited - for example, it was never going to provide support for
implementing [custom protocol handling](https://blog.envoyproxy.io/how-to-write-envoy-filters-like-a-ninja-part-1-d166e5abec09).

The Envoy model imposed a monolithic build process, and required extensions to be written in C++,
limiting the developer ecosystem. Rolling out a new extension to the fleet required pushing new
binaries and rolling restarts, which can be difficult to coordinate, and risk downtime. This also
incentivized developers to upstream extensions into Envoy that were used by only a small
percentage of deployments, just to piggyback on its release mechanisms.

Over time some of the most performance-sensitive features of Istio have been upstreamed
into Envoy - [policy checks on traffic](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/security/rbac_filter),
and [telemetry reporting](/docs/reference/config/telemetry/metrics/), for example.
Still, we have always wanted to converge on a single stack for extensibility that imposes fewer
tradeoffs: something that decouples Envoy releases from its extension ecosystem, enables
developers to work in their languages of choice, and enables Istio to reliably roll out new
capability without downtime risk. Enter WebAssembly.

## What is WebAssembly?

[WebAssembly](https://webassembly.org/) (Wasm) is a portable bytecode format for executing code
written in [multiple languages](https://github.com/appcypher/awesome-wasm-langs) at
near-native speed. Its initial [design goals](https://webassembly.org/docs/high-level-goals/) align
well with the challenges outlined above, and it has sizable industry support behind it. Wasm
is the fourth standard language (following HTML, CSS and JavaScript) to run natively in all
the major browsers, having become a [W3C Recommendation](https://www.w3.org/TR/wasm-core-1/) in
December 2019. That gives us confidence in making a strategic bet on it.

While WebAssembly started life as a client-side technology, there are a number of advantages
to using it on the server. The runtime is memory-safe and sandboxed for security. There is a
large tooling ecosystem for compiling and debugging Wasm in its textual or binary format.
The [W3C](https://www.w3.org/) and [BytecodeAlliance](https://bytecodealliance.org/) have become
active hubs for other server-side efforts. For example, the Wasm community is standardizing
a ["WebAssembly System Interface" (WASI)](https://hacks.mozilla.org/2019/03/standardizing-wasi-a-webassembly-system-interface/)
at the W3C, with a sample implementation, which provides an OS-like abstraction to Wasm 'programs'.

## Bringing WebAssembly to Envoy

[Over the past 18 months](https://github.com/envoyproxy/envoy/issues/4272), we have been working
with the Envoy community to build Wasm extensibility into Envoy and contribute it upstream.
We're pleased to announce it is available as Alpha in the Envoy build shipped
with [Istio 1.5](/news/releases/1.5.x/announcing-1.5/), with source in
the [`envoy-wasm`](https://github.com/envoyproxy/envoy-wasm/) development fork and work ongoing to
merge it into the main Envoy tree. The implementation uses the WebAssembly runtime built into
Google's high performance [V8 engine](https://v8.dev/).

In addition to the underlying runtime, we have also built:

-   A generic Application Binary Interface (ABI) for embedding Wasm in proxies, which means compiled
 extensions will work across different versions of Envoy - or even other proxies, should they choose
 to implement the ABI

-   SDKs for easy extension development in [C++](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk),
 [Rust](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
 and [AssemblyScript](https://github.com/solo-io/proxy-runtime), with more to follow

-   Comprehensive [samples and instructions](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
    on how to deploy in Istio and standalone Envoy

-   Abstractions to allow for other Wasm runtimes to be used, including a 'null' runtime which
    simply compiles the extension natively into Envoy --- very useful for testing and debugging

Using Wasm for extending Envoy brings us several key benefits:

-   Agility: Extensions can be delivered and reloaded at runtime using the Istio control plane.
    This enables a fast develop → test → release cycle for extensions without
    requiring Envoy rollouts.

-   Stock releases: Once merging into the main tree is complete, Istio and others will be able to
    use stock releases of Envoy, instead of custom builds. This will also free the Envoy community
    to move some of the built-in extensions to this model, thereby reducing their
    supported footprint.

-   Reliability and isolation: Extensions are deployed inside a sandbox with resource constraints,
    which means they can now crash, or leak memory, without bringing the whole Envoy process down.
    CPU and memory usage can also be constrained.

-   Security: The sandbox has a clearly defined API for communicating with Envoy, so extensions
    only have access to, and can modify, a limited number of properties of a connection or request.
    Furthermore, because Envoy mediates this interaction, it can hide or sanitize sensitive
    information from the extension (e.g. "Authorization" and "Cookie" HTTP headers, or
    the client's IP address).

-   Flexibility: [over 30 programming languages can be compiled to WebAssembly](https://github.com/appcypher/awesome-wasm-langs),
    allowing developers from all backgrounds - C++, Go, Rust, Java, TypeScript, etc. - to write
    Envoy extensions in their language of choice.

"I am extremely excited to see WASM support land in Envoy; this is the future of Envoy
extensibility, full stop. Envoy's WASM support coupled with a community driven hub will unlock an
incredible amount of innovation in the networking space across both service mesh and API gateway
use cases. I can't wait to see what the community builds moving forward."
-- Matt Klein, Envoy creator.

For technical details of the implementation, look out for an upcoming post
to [the Envoy blog](https://blog.envoyproxy.io/).

The [Proxy-Wasm](https://github.com/proxy-wasm) interface between host environment and extensions
is deliberately proxy agnostic. We've built it into Envoy, but it was designed to be adopted by
other proxy vendors. We want to see a world where you can take an extension written for Istio and
Envoy and run it in other infrastructure; you'll hear more about that soon.

## Building on WebAssembly in Istio

Istio moved several of its extensions into its build of Envoy as part of the 1.5 release, in order
to significantly improve performance. While doing that work we have been testing to ensure those
same extensions can compile and run as Proxy-Wasm modules with no variation in behavior. We're not
quite ready to make this setup the default, given that we consider Wasm support to be Alpha;
however, this has given us a lot of confidence in our general approach and in the host
environment, ABI and SDKs that have been developed.

We have also been careful to ensure that the Istio control plane and
its [Envoy configuration APIs](/docs/reference/config/networking/envoy-filter/) are Wasm-ready.
We have samples to show how several common customizations such as custom header decoding or
programmatic routing can be performed which are common asks from users. As we move this support to
Beta, you will see documentation showing best practices for using Wasm with Istio.

Finally, we are working with the many vendors who have
written [Mixer adapters](/docs/reference/config/policy-and-telemetry/adapters/),
to help them with a migration to Wasm --- if that is the best path forward. Mixer will move to a
community project in a future release, where it will remain available for legacy use cases.

## Developer Experience

Powerful tooling is nothing without a great developer experience. Solo.io
[recently announced](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)
the release of [WebAssembly Hub](https://webassemblyhub.io/), a set of tools and repository for
building, deploying, sharing and discovering Envoy Proxy Wasm extensions for Envoy and Istio.

The WebAssembly Hub fully automates many of the steps required for developing and deploying Wasm
extensions. Using WebAssembly Hub tooling, users can easily compile their code - in any supported
language - into Wasm extensions. The extensions can then be uploaded to the Hub registry, and be
deployed and undeployed to Istio with a single command.

Behind the scenes the Hub takes care of much of the nitty-gritty, such as pulling in the correct
toolchain, ABI version verification, permission control, and more. The workflow also eliminates
toil with configuration changes across Istio service proxies by automating the deployment of your
extensions. This tooling helps users and operators avoid unexpected behaviors due to
misconfiguration or version mismatches.

The WebAssembly Hub tools provide a powerful CLI as well as an elegant and easy-to-use graphical
user interface. An important goal of the WebAssembly Hub is to simplify the experience around
building Wasm modules and provide a place of collaboration for developers to share and discover
useful extensions.

Check out the [getting started guide](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)
to create your first Proxy-Wasm extension.

## Next Steps

In addition to working towards a beta release, we are committed to making sure that there is a
durable community around Proxy-Wasm. The ABI needs to be finalized, and turning it into a standard
will be done with broader feedback within the appropriate standards body. Completing upstreaming
support into the Envoy mainline is still in progress. We are also seeking an appropriate
community home for the tooling and the WebAssembly Hub

## Learn more

-   WebAssembly SF talk (video): [Extensions for network proxies](https://www.youtube.com/watch?v=OIUPf8m7CGA), by John Plevyak

-   [Solo blog](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)

-   [Proxy-Wasm ABI specification](https://github.com/proxy-wasm/spec)

-   [Proxy-Wasm C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md) and
    its [developer documentation](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/master/docs/wasm_filter.md)

-   [Proxy-Wasm Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)

-   [Proxy-Wasm AssemblyScript SDK](https://github.com/solo-io/proxy-runtime)

-   [Tutorials](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/)

-   Videos on the [Solo.io Youtube Channel](https://www.youtube.com/channel/UCuketWAG3WqYjjxtQ9Q8ApQ)
