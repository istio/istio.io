---
title: Announcing the alpha availability of WebAssembly Plugins
description: Introduction of Wasm Plugin API, and updates on Envoy and Istio's Wasm based plugins.
publishdate: 2021-11-25
attribution: "Daniel Grimm(Red Hat), Pengyuan Bian(Google), Takeshi Yoneda(Tetrate)"

keywords: [wasm,extensibility,WebAssembly]
---

[At the Istio 1.9 release](../wasm-progress/), we introduced experimental support for Wasm module distribution and Wasm extensions ecosystem repository for canonical examples and use cases of Wasm extension development. Over the past 9 months, the Istio, Envoy, and Proxy-Wasm communities have continued our joint efforts to make WebAssembly (Wasm) extensibility stable, reliable, and easy to adopt, and we are pleased to announce Alpha support for Wasm extensibility at Istio 1.12 release! Let’s walk through the updates to Wasm support through the Istio 1.12 release.

## New WasmPlugin API

With the new WasmPlugin API in the `extensions.istio.io` namespace, we’re introducing a new high-level API for extending the functionality of the Istio Proxy with custom WebAssembly (Wasm) modules. This effort builds on the excellent work that has gone into the [Proxy-Wasm](https://github.com/proxy-wasm) specification and implementation over the last two years. From now on, you no longer need to use `EnvoyFilter` resources to add custom Wasm modules to your proxies. Instead, you can now use WasmPlugin directly:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: your-filter
spec:
  selector:
    matchLabels:
      app: server
  phase: AUTHN
  priority: 10
  pluginConfig:
    someSetting: true
    someOtherSetting: false
    youNameIt:
    - first
    - second
  url: docker.io/your-org/your-filter:1.0.0
{{< /text >}}

There are a lot of similarities and a few differences between WasmPlugin and `EnvoyFilter`, so let’s go through the fields one by one. The above example deploys a Wasm module to all workloads (including gateway pods) that match it’s `selector` - this very much works the same as in an `EnvoyFilter`.

The next field below that is the `phase`. This determines where in the proxy’s filter chain the Wasm module will be injected. We have defined four distinct phases for injection:

AUTHN: this is prior to any Istio authentication filters, meaning it is executed even before the remote mTLS certificates are verified.
AUTHZ: just after the Istio authentication filters and before any authorization filters, i.e. before AuthorizationPolicies have been applied.
STATS:

`pluginConfig` is used for configuring your Wasm plugin. Whatever you put into this field will be encoded in JSON and passed on to your filter, where you can access it in the configuration callback of the Proxy-Wasm SDKs. For example, you can retrieve the config on `on_configure` in [Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk/blob/v0.1.4/src/dispatcher.rs#L255) or `OnPluginStart` call back in [Go SDK](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/v0.15.0/proxywasm/types/context.go#L74).

The `url` field specifies where to pull the Wasm module. You’ll notice that the `url` in this case is a docker URI - this is because apart from loading Wasm modules via HTTP, HTTPS and the local file system (using file://), we are introducing a container image format to package Wasm extensions for Istio.

## Wasm image specification

We believe that containers are the ideal way to store, publish and manage proxy extensions, so we worked with Solo.io to extend their existing Proxy-Wasm container format with a variant that aims to be compatible with all registries and CLI toolchain. Depending on your processes, you can now either build your proxy extension containers using solo’s wasme tool or straight up with your existing container CLI tooling such as Docker CLI or [buildah](https://buildah.io/). Istio supports both variants.

For detail, please refer to [the link here](https://github.com/solo-io/wasm/tree/master/spec), and learn [how to build OCI images](https://github.com/solo-io/wasm/tree/master/spec#how-can-i-build-images) that are consumable by Istio agent.

## Image fetcher in Istio agent

As of 1.9, Istio-agent provides a reliable solution for loading Wasm binaries fetched from remote HTTP sources configured in the `EnvoyFilters` by leveraging the xDS proxy inside istio-agent and Envoy’s Extension Configuration Discovery Service (ECDS). The same mechanism applies for the new Wasm API implementation in Istio 1.12, and you can use HTTP remote resources reliably without the concern that Envoy might get stuck in bad configurations when the remote fetch fails.

In addition, Istio 1.12 expands this capability to the Wasm OCI images. That means the Istio agent is now able to fetch Wasm images from any OCI registry including Docker Hub, Google Container Registry(GCR), Amazon Elastic Container Registry (Amazon ECR), etc. After fetching images, Istio-agent extracts and caches Wasm binaries from them, and then inserts them into Envoy filter chains.

{{< image width="75%"
    link="./istio-agent-architecture.svg"
    alt="Remote Wasm module fetch flow"
    caption="Remote Wasm module fetch flow"
    >}}

## Improvements in Envoy Wasm runtime

The Wasm runtime powered by V8 in Envoy has been shipped as of Istio 1.5, and there has been a lot of improvements since then.

First of all, some of the WASI (WebAssembly System Interface) system calls are supported now. For example, `clock_time_get` system call can be made from Wasm programs, which means that you can use `std::time::SystemTime::now()` in Rust or `time.Now().UnixNano()` in Go for Envoy Wasm extensions just like any other native platform. Another example is that `random_get` is supported by Envoy now, so the "crypto/rand" package is available in Go as a cryptographically secure random number generator. We are currently actively looking into file system support as we have seen the requests for reading and writing local files from Wasm programs running in Envoy.

Next is the improvement in debuggability. Now the Envoy runtime emits the stack trace of your program when it causes runtime errors, for example, when null pointer exceptions occur in C++, or the panic function is called in Go or Rust. Previously Envoy did not say anything about the cause of errors, but now you can see the trace which can be used to debug your programs:

{{< text plain >}}
Function: proxy_on_request_headers failed: Uncaught RuntimeError: unreachable
Proxy-Wasm plugin in-VM backtrace:
  0:  0xdbd - runtime._panic
  1:  0x103ab - main.anotherCalculation
  2:  0x10399 - main.someCalculation
  3:  0xea57 - main.myHeaderHandler
  4:  0xea15 - proxy_on_request_headers
{{< /text >}}

The above is an example output of the stack trace for Go SDK based Wasm extensions. You might notice that you want file names and lines in the trace lines -- that is another huge future work and is currently an open issue since it has something to do with the DWARF format for WebAssembly and the Exception Handling proposal to WebAssembly specification.

Also you can see strace equivalent logs emitted by Envoy. With Istio proxy’s component log level `wasm:trace`, we can observe all the system calls and Proxy-Wasm ABI calls that go across the boundary between Wasm virtual machines and Envoy. The following is an example log stream of such strace logs:

{{< text plain >}}
[host->vm] proxy_on_context_create(2, 1)
[host<-vm] proxy_on_context_create return: void
[host->vm] proxy_on_request_headers(2, 8, 1)
[vm->host] wasi_snapshot_preview1.random_get(86928, 32)
[vm<-host] wasi_snapshot_preview1.random_get return: 0
[vm->host] env.proxy_log(2, 87776, 18)
{{< /text >}}

This is especially useful to debug Wasm program’s execution at runtime, for example, to verify it is not making any malicious system calls.

The next one is about metrics. Wasm extensions have been able to define their own custom metrics and expose them in Envoy just like any other metric, but prior to Istio 1.12, all of these custom metrics are prefixed by `envoy_` Prometheus namespace and users were not be able to have their own namespaces. Now, you can choose whatever namespace you want, and your metrics are exposed in Envoy as-is without being prefixed by `envoy_`.

In addition to all of the above, we have fixed tons of bugs found in Envoy and refactored the original code. Notably now all of the Istio specific Wasm related codes in proxy have been removed, meaning that Istio telemetry and any other Proxy-Wasm based Istio extensions just depend on Proxy-Wasm ABI and the upstream Envoy implementation. This proves that the direction of the Proxy-Wasm project towards defining generic Wasm ABI to extend network proxies is on the right track.

## Future work and looking for feedback

Although we have announced the alpha availability of Wasm plugins, there are still a lot of aspects that are left to be completed. The one important thing is the "Image pull secrets” support in the Wasm API -- this way we would be able to consume the OCI images in the private repository easily in Istio. Others include signature verification of Wasm binaries, runtime improvements in Envoy, Proxy-Wasm SDK improvements, documentation, etc.

That means, this is just the beginning of the 1st-class Wasm support in Istio. We would love to hear feedback from users so that we could improve the developer experience with the Wasm plugins!
