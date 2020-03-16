---
title: Extended and Improved WebAssemblyHub to Bring the Power of WebAssembly to Envoy and Istio
subtitle: A hub to build, publish, share and deploy WebAssembly Envoy extensions
description: Community partner tooling of Wasm for Istio by Solo.io.
publishdate: 2020-03-13
attribution: "Idit Levine (Solo.io)"
keywords: [wasm,extensibility,alpha,performance,operator]
---

*[Originally posted on the Solo.io blog](https://www.solo.io/blog/an-extended-and-improved-webassembly-hub-to-helps-bring-the-power-of-webassembly-to-envoy-and-istio/)*

As users look to adopt Envoy-based infrastructure like Istio to help them solve challenges with microservices communication, they inevitably find themselves needing to customize some part of that infrastructure to fit within their organization’s constraints. [WebAssembly (Wasm)](https://webassembly.org/) has emerged as a safe, secure, and dynamic environment for platform extension.

Last week's [announcement of Istio 1.5](/blog/2020/wasm-announce/), lays the foundation for bringing WebAssembly to the popular Envoy proxy. [Solo.io](https://solo.io) is collaborating with Google and the Istio community to simplify the overall experience of creating, sharing, and deploying WebAssembly extensions to Envoy and Istio. It wasn't that long ago that Google and others laid the foundation for containers, and Docker built a great user experience to make it consumable. Similarly, this effort making Wasm consumable by building the best user experience for WebAssembly on Istio.

Back in December 2019, Solo.io began an effort to provide a great developer experience for WebAssembly with the announcement of WebAssembly Hub by creating a workflow that allows developers to very quickly spin up a new WebAssembly project in C++ (we’re expanding this language choice, see below), build it using Bazel in Docker, and push it to an OCI-compliant registry. From there, operators had to  pull the module, and configure Envoy proxies themselves to load it from disk. Starting with beta support in [Gloo, an API Gateway built on Envoy](https://docs.solo.io/gloo/latest/), to declaratively and dynamically load the module, the Solo.io team wanted to bring the same effortless and secure experience to other Envoy-based frameworks as well - like Istio. 

There has been a lot of interest in the innovation in this area, and the Solo.io team has been working hard to further the capabilities of WebAssembly Hub and the workflows it supports. In conjuction with Istio 1.5, Solo.io is thrilled to announce new enhancements to WebAssembly Hub that evolve the viability of WebAssembly+Envoy for production, improve the developer experience, and streamline using Wasm with Envoy in Istio. 

## Evolving toward production
The Envoy community is working hard to bring Wasm support into the upstream project (right now it lives on a working development fork), with Istio declaring Wasm support an Alpha feature. In [Gloo 1.0 we also announced](https://www.solo.io/blog/announcing-gloo-1-0-a-production-ready-envoy-based-api-gateway/) early, non-production support for Wasm. Gloo is a modern API Gateway and Ingress Controller built on Envoy Proxy designed to connect, secure and control incoming traffic to an application environment. Gloo supports routing to legacy monoliths, microservices / Kubernetes and serverless functions for developers and for ops teams to shape and secure the incoming requests from external end users/clients to backend application services. Gloo is a Kubernetes and Istio native ingress gateway.

Although it’s still maturing in each individual project, there are things that can be done right now to improve the foundation for production support. 

The first area is standardizing what a WebAssembly extension for Envoy looks like. Solo.io, Google, and the Istio community have defined an open specification for bundling and distributing WebAssembly modules as OCI images. This specification provides a powerful model for distributing any type of Wasm module including Envoy extensions. 

This is open to the community - Join in the effort here: https://github.com/solo-io/wasm-image-spec

The next area is improving the experience of deploying Wasm extensions into an Envoy-based framework running in production. In the Kubernetes ecosystem, it is considered best practice in production to use declarative CRD-based configuration to manage cluster configuration. The new [WebAssembly Hub Operator](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/wasme_operator/) adds a single, declarative CRD which automatically deploys and configures Wasm filters to Envoy proxies running inside of a Kubernetes cluster. This operator enables GitOps workflows and cluster automation to manage Wasm filters without human intervention or imperative workflows. More info on the Operator coming soon on the blog. 

Lastly, the interactions between developers of Wasm extensions and the teams that deploy them need some kind of role-based access, organization management, and facilities to share, discover, and consume these extensions. The WebAssembly Hub adds team management features like permissions, organizations, user management, sharing and more. 

## Improving the developer experience
As developers want to target more languages and runtimes,the experience must be kept as simple and as productive as possible. Multi-language support and runtime ABI (Application Binary Interface) targets should be handled automatically in tooling. 

One of the benefits of Wasm is the ability to write modules in many languages. The collaboration between Solo.io and Google provides out-of-the-box support for Envoy filters written in C++, Rust and AssemblyScript. We will continue to add support for more languagues.

Wasm extensions utilize an Application Binary Interface (ABI) within the Envoy proxy to which they are deployed. The WebAssembly Hub provides strong ABI versioning guarantees between Envoy/Istio/Gloo to prevent unpredictable behavior and bugs. All you have to worry about is writing your extension code.

Lastly, like Docker, the WebAssembly Hub stores and distributes Wasm extensions as OCI images. This makes pushing, pulling, and running extensions as easy as Docker containers. Wasm extension images are versioned and cryptographically secure, making it safe to run extensions locally the same way you would in production. This allows users to easily build and push as well as trust the source when they pull down and deploy images.

## WebAssembly Hub with Istio

The WebAssembly Hub now fully automates the process of deploying Wasm extensions to Istio, (as well as other Envoy-based frameworks like [Gloo API Gateway](https://https://docs.solo.io/gloo/latest/)) installed in Kubernetes. With this deployment feature, the WebAssembly Hub relieves the operator or end user from having to manually configure the Envoy proxy in their Istio service mesh to use their WebAssembly modules.


Take a look at the following video to see just how easy it is to get started with WebAssembly and Istio:

* Part 1: https://www.youtube.com/watch?v=-XPTGXEpUp8
* Part 2: https://youtu.be/vuJKRnjh1b8

## Get Started
We hope that the WebAssembly Hub will become a meeting place for the community to share, discover and distribute Wasm extensions. By providing a great user experience, we hope to make developing, installing and running Wasm easier and more rewarding. Join us at the [WebAssembly Hub](https://webassemblyhub.io), share your extensions and [ideas](https://https://slack.solo.io), and join an [upcoming webinar](https://solo.zoom.us/webinar/register/WN_i8MiDTIpRxqX-BjnXbj9Xw). 
