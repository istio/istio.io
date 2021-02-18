---
title: Progress of Envoy and Istio WebAssembly Extensibility
description: An update on Envoy and Istio WebAssembly based extensibility effort.
publishdate: 2021-02-09
attribution: "Pengyuan Bian (Google)"
keywords: [wasm,extensibility,WebAssembly]
---

Istio introduced initial [WebAssembly-based extensibility](/blog/2020/wasm-announce/) support in the 1.5 release.
Over the past year, Istio, Envoy, and Proxy-Wasm communities have continued the effort to make WebAssembly extensibility stable, reliable, and easy to adopt.
In this blog post, we will walk through the updates to Wasm support in the Istio 1.9 release.

## Proxy-Wasm (WebAssembly) support merged in upstream Envoy

After our initial experimental support was available, we collected great feedback from community early adopters.
Along with experience gained from development efforts on core Istio Wasm extensions, this feedback helped us mature and stabilize the runtime.
These improvements unblocked merging Wasm support directly into Envoy, allowing it to become part of all official Envoy releases (as of the Istio 1.8 release).
This is a significant milestone for Istio and Envoy Wasm efforts, since it indicates that:

* The runtime is ready for wider adoption.
* The programming ABI/API, extension configuration API, as well as runtime behavior are becoming stable.
* Better community support moving forward.

## Istio Wasm Extension Ecosystem

As one of the early adopters of Envoy WebAssembly runtime, Istio extensibility working group gained a lot of experience via developing several first class extensions, such as [metadata exchange](/docs/reference/config/proxy_extensions/metadata_exchange/), [Prometheus stats](/docs/reference/config/proxy_extensions/stats/), and [attribute generation](/docs/reference/config/proxy_extensions/attributegen/).
In order to share the learning broadly, a [`wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions) was created under `istio-ecosystem` org. This repository serves two purposes:

* Provides canonical example extensions, which also covers several highly demanded features such as [basic authentication](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth).
* Provides a guide for Wasm extension development, testing, and release. The guide is based on the same build tool chains and test frameworks that are used, maintained and tested by the Istio extensibility team.

Currently the existing guide covers [WebAssembly extension development](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
and [unit testing](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md) with C++,
as well as [integration testing](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md) with a GoLang test framework,
which simulates real runtime by running a Wasm module with the Istio proxy binary.
In the future, several more canonical extensions will also be added such as open policy agent, and header manipulation based on JWT token.

## Wasm Module Distribution via Istio Agent

Prior to Istio 1.9, [Envoy remote data source](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-remotedatasource) were needed to distribute remote Wasm modules to the proxy.
An example configuration could be found [here](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910),
where two `EnvoyFilter` resources are defined: one is to add a remote fetch Envoy cluster, and the other one is to inject a Wasm filter into HTTP filter chain.
However this method has a drawback: if remote fetch fails either due to bad configuration or transient error, Envoy will be stuck with the bad configuration.
If a Wasm extension is configured as [fail closed](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-pluginconfig), a bad remote fetch will stop Envoy from serving.
To fix this issue, [a fundamental change](https://github.com/envoyproxy/envoy/issues/9447) is needed to Envoy xDS protocol to make it allow asynchronous xDS response.

Istio 1.9 provides a reliable distribution mechanism out of the box by leveraging the XDS proxy inside istio-agent and Envoy [Extension Configuration Discovery Server](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS).
The following diagram shows the flow.
Istio-agent intercepts the extension config resource update from istiod, reads the remote fetch hint from it, downloads the Wasm module, and rewrites the ECDS configuration with the path of the downloaded Wasm module.
If download fails, istio-agent will reject the ECDS update and prevent bad configuration reaching Envoy. For more detail, please go through [this guide](/docs/ops/configuration/extensibility/wasm-module-distribution/).

{{< image width="75%"
    link="./architecture-istio-agent-downloading-wasm-module.svg"
    alt="Remote Wasm module fetch flow"
    caption="Remote Wasm module fetch flow"
    >}}

## Istio Wasm SIG and Future Work

Although we have made a lot of progress on Wasm extensibility, there are still many aspects of the Istio-Wasm project that remain to be completed. In order to consolidate the efforts from various parties and better tackle the challenges ahead, an Istio WebAssembly SIG has formed, which aims to provide a standard and reliable way to consume Wasm extensions at Istio ecosystem. Here is a non-exhaustive list of work items that the Istio Wasm SIG is focusing on:

* First class extension API. Currently Wasm extension needs to be injected via Istio `EnvoyFilter` API, which is not user friendly and hard to support.
  A first class extension API will be defined to make using Wasm with Istio easier and it is expected to be delivered with Istio 1.10 release.
* Distribution artifacts interoperability. Built on top of Solo’s [WebAssembly OCI image spec effort](https://www.solo.io/blog/announcing-the-webassembly-wasm-oci-image-spec/), a standard Wasm artifacts format will be defined to make it easy to build, pull, publish, and execute.
* Container Storage Interface (CSI) based artifacts distribution.
  Istio-agent based Wasm module distribution is easy to adopt, however it is not as efficient since each proxy will keep a copy of the Wasm module.
  As a more efficient solution, with [Ephemeral CSI](https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html), a DaemonSet will be provided which could configure storage for pods.
  Working similarly as CNI plugin, a CSI driver will fetch the Wasm module out of the band of XDS flow and mount it inside the pod `rootfs` when the pod starts up.
