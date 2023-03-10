---
title: Istio and Envoy WebAssembly Extensibility, One Year On
description: An update on Envoy and Istio's WebAssembly-based extensibility effort.
publishdate: 2021-03-05
attribution: "Pengyuan Bian (Google)"
keywords: [wasm,extensibility,WebAssembly]
---

One year ago today, in the 1.5 release, we introduced [WebAssembly-based extensibility](/blog/2020/wasm-announce/) to Istio.
Over the course of the year, the Istio, Envoy, and Proxy-Wasm communities have continued our joint efforts to make WebAssembly (Wasm)
extensibility stable, reliable, and easy to adopt. Let's walk through the updates to Wasm support through the Istio 1.9 release,
and our plans for the future.

## WebAssembly support merged in upstream Envoy

After adding experimental support for Wasm and the WebAssembly for Proxies (Proxy-Wasm) ABI to Istio's fork of Envoy, we collected some great feedback from our community of early adopters.  This, combined with the experience gained from developing core Istio Wasm extensions, helped us mature and stabilize the runtime.
These improvements unblocked merging Wasm support directly into Envoy upstream in October 2020, allowing it to become part of all official Envoy releases.
This was a significant milestone, since it indicates that:

* The runtime is ready for wider adoption.
* The programming ABI/API, extension configuration API, and runtime behavior, are becoming stable.
* You can expect a larger community of adoption and support moving forward.

## `wasm-extensions` Ecosystem Repository

As an early adopter of the Envoy Wasm runtime, the Istio Extensions and Telemetry working group gained a lot of experience in developing extensions. We built several first-class extensions, including [metadata exchange](/docs/reference/config/proxy_extensions/metadata_exchange/), [Prometheus stats](https://archive.istio.io/v1.17/docs/reference/config/proxy_extensions/stats/), and [attribute generation](https://archive.istio.io/v1.17/docs/reference/config/proxy_extensions/attributegen/).
In order to share our learning more broadly, we created a [`wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions) in the `istio-ecosystem` organization. This repository serves two purposes:

* It provides canonical example extensions, covering several highly demanded features (such as [basic authentication](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)).
* It provides a guide for Wasm extension development, testing, and release. The guide is based on the same build tool chains and test frameworks that are used, maintained and tested by the Istio extensibility team.

The guide currently covers [WebAssembly extension development](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
and [unit testing](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md) with C++,
as well as [integration testing](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md) with a Go test framework,
which simulates a real runtime by running a Wasm module with the Istio proxy binary.
In the future, we will also add several more canonical extensions, such as an integration with Open Policy Agent, and header manipulation based on JWT tokens.

## Wasm module distribution via the Istio Agent

Prior to Istio 1.9, [Envoy remote data sources](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/base.proto#config-core-v3-remotedatasource) were needed to distribute remote Wasm modules to the proxy.
[In this example](https://gist.github.com/bianpengyuan/8377898190e8052ffa36e88a16911910),
you can see two `EnvoyFilter` resources are defined: one to add a remote fetch Envoy cluster, and the other one to inject a Wasm filter into the HTTP filter chain.
This method has a drawback: if remote fetch fails, either due to bad configuration or transient error, Envoy will be stuck with the bad configuration.
If a Wasm extension is configured as [fail closed](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/wasm/v3/wasm.proto#extensions-wasm-v3-pluginconfig), a bad remote fetch will stop Envoy from serving.
To fix this issue, [a fundamental change](https://github.com/envoyproxy/envoy/issues/9447) is needed to the Envoy xDS protocol to make it allow asynchronous xDS responses.

Istio 1.9 provides a reliable distribution mechanism out of the box by leveraging the xDS proxy inside istio-agent and Envoy's [Extension Configuration Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS).

istio-agent intercepts the extension config resource update from istiod, reads the remote fetch hint from it, downloads the Wasm module, and rewrites the ECDS configuration with the path of the downloaded Wasm module.
If the download fails, istio-agent will reject the ECDS update and prevent a bad configuration reaching Envoy. For more detail, please see [our docs on Wasm module distribution](/docs/tasks/extensibility/wasm-module-distribution/).

{{< image width="75%"
    link="./architecture-istio-agent-downloading-wasm-module.svg"
    alt="Remote Wasm module fetch flow"
    caption="Remote Wasm module fetch flow"
    >}}

## Istio Wasm SIG and Future Work

Although we have made a lot of progress on Wasm extensibility, there are still many aspects of the project that remain to be completed. In order to consolidate the efforts from various parties and better tackle the challenges ahead, we have formed an [Istio WebAssembly SIG](https://discuss.istio.io/t/introducing-wasm-sig/9930), with aim of providing a standard and reliable way for Istio to consume Wasm extensions. Here are some of the things we are working on:

* **A first-class extension API**: Currently Wasm extensions needs to be injected via Istio's `EnvoyFilter` API. A first-class extension API will make using Wasm with Istio easier, and we expect this to be introduced in Istio 1.10.
* **Distribution artifacts interoperability**: Built on top of Solo.io’s [WebAssembly OCI image spec effort](https://www.solo.io/blog/announcing-the-webassembly-wasm-oci-image-spec/), a standard Wasm artifacts format will make it easy to build, pull, publish, and execute.
* **Container Storage Interface (CSI) based artifacts distribution**: Using istio-agent to distribute modules is easy for adoption, but may not be efficient as each proxy will keep a copy of the Wasm module. As a more efficient solution, with [Ephemeral CSI](https://kubernetes-csi.github.io/docs/ephemeral-local-volumes.html), a DaemonSet will be provided which could configure storage for pods. Working similarly to a CNI plugin, a CSI driver would fetch the Wasm module out-of-band from the xDS flow and mount it inside the `rootfs` when the pod starts up.

If you would like to join us, the group will meet every other week Tuesdays at 2PM PT. You can find the meeting on the [Istio working group calendar](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings).

We look forward to seeing how you will use Wasm to extend Istio!
