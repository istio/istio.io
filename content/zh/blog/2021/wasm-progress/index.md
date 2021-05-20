---
title: 一年之后 Istio 和 Envoy 的 WebAssembly 的可扩展性
description: 最新Envoy 和 Istio 上基于 WebAssembly 可扩展性工作。
publishdate: 2021-03-05
attribution: "Pengyuan Bian (Google)"
keywords: [wasm,extensibility,WebAssembly]
---

一年以前的今天，1.5 发布了，我们在 Istio 中引入了 [基于WebAssembly的可扩展性](/blog/2020/wasm-announce/)。
在过去的这一年中，Istio，Envoy 和 Proxy-Wasm 社区共同努力让 WebAssembly (Wasm)的可扩展性逐步稳定、可靠和易于使用。
我们可以通过 Istio 1.9 版本来了解对 Wasm 支持的更新，还有我们未来的计划。

## WebAssembly 支持合并进了上游的 Envoy 

在 Istio 的 Envoy 分支中添加了对 Wasm 的实验性支持和 Proxies(Proxy-Wasm) 的 WebAssembly ABI 后，
从社区早期使用者这里我们收集一些很好的反馈。与开发核心 Istio Wasm 扩展获得的经验相结合，这帮助我们让运行时不断成熟和稳定。

这些改进帮助 Wasm 支持在 2020 年 10 月直接合并进了 Envoy 上游，让 Wasm 支持变成了 Envoy 的官方发布内容。
这是一个重要的里程碑，因为它标示着：

* 运行时已经可以被广泛使用。
* 编程 ABI/API，扩展配置 API 和运行时已经是稳定了。
* 你可以预期发展出来一个使用支持该技术的大社区。

## `wasm-extensions` 的生态系统库

作为 Envoy Wasm 运行时的早期采集者，Istio 扩展和遥测工作组在开发扩展方面获得了很多经验。我们构建了几个一流的扩展，包括 [原数据交换](/docs/reference/config/proxy_extensions/metadata_exchange/)，[Prometheus 统计](/docs/reference/config/proxy_extensions/stats/)和 [属性生成器](/docs/reference/config/proxy_extensions/attributegen/)。
为了更广泛地分享我们的知识，我们在 `istio-ecosystem` git 组织下面创建了一个 [`wasm-extensions` 仓库](https://github.com/istio-ecosystem/wasm-extensions)。这个仓库有 2 个目的：

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
If the download fails, istio-agent will reject the ECDS update and prevent a bad configuration reaching Envoy. For more detail, please see [our docs on Wasm module distribution](/docs/ops/configuration/extensibility/wasm-module-distribution/).

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
我们很期待看到您如何用 Wasm 来扩展 Istio!