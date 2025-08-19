---
title: Announcing the alpha availability of WebAssembly Plugins
description: Introduction to the new Wasm Plugin API and updates to the Wasm-based plugin support in Envoy and Istio.
publishdate: 2021-12-16
attribution: "Daniel Grimm (Red Hat), Pengyuan Bian (Google), Takeshi Yoneda (Tetrate)"

keywords: [wasm,extensibility,WebAssembly]
---

[Istio 1.9 introduced](../wasm-progress/) experimental support for WebAssembly (Wasm) module distribution and a Wasm extensions ecosystem repository with canonical examples and use cases for extension development. Over the past 9 months, the Istio, Envoy, and Proxy-Wasm communities have continued our joint effort to make Wasm extensibility stable, reliable, and easy to adopt, and we are pleased to announce Alpha support for Wasm extensibility in Istio 1.12! In the following sections, we'll walk through the updates that have been made to the Wasm support for the 1.12 release.

## New WasmPlugin API

With the new `WasmPlugin` CRD in the `extensions.istio.io` namespace, we’re introducing a new high-level API for extending the functionality of the Istio proxy with custom Wasm modules. This effort builds on the excellent work that has gone into the [Proxy-Wasm](https://github.com/proxy-wasm) specification and implementation over the last two years. From now on, you no longer need to use `EnvoyFilter` resources to add custom Wasm modules to your proxies. Instead, you can now use a `WasmPlugin` resource:

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

There are a lot of similarities and a few differences between `WasmPlugin` and `EnvoyFilter`, so let’s go through the fields one by one.

The above example deploys a Wasm module to all workloads (including gateway pods) that match the `selector` field - this very much works the same as in an `EnvoyFilter`.

The next field below that is the `phase`. This determines where in the proxy’s filter chain the Wasm module will be injected. We have defined four distinct phases for injection:

* `AUTHN`: prior to any Istio authentication and authorization filters.
* `AUTHZ`: after the Istio authentication filters and before any first-class authorization filters, i.e., before `AuthorizationPolicy` resources have been applied.
* `STATS`: after all authorization filters and prior to the Istio stats filter.
* `UNSPECIFIED_PHASE`: let the control plane decide where to insert. This will generally be at the end of the filter chain, right before the router. This is the default value for this `phase` field.

The `pluginConfig` field is used for configuring your Wasm plugin. Whatever you put into this field will be encoded in JSON and passed on to your filter, where you can access it in the configuration callback of the Proxy-Wasm SDKs. For example, you can retrieve the config with `onConfigure` in the [C++ SDK](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk/blob/fd0be8405db25de0264bdb78fae3a82668c03782/proxy_wasm_api.h#L329-L331), `on_configure` in the [Rust SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk/blob/v0.1.4/src/dispatcher.rs#L255) or the `OnPluginStart` call back in the [Go SDK](https://github.com/tetratelabs/proxy-wasm-go-sdk/blob/v0.15.0/proxywasm/types/context.go#L74).

The `url` field specifies where to pull the Wasm module. You’ll notice that the `url` in this example is a docker URI. Apart from loading Wasm modules via HTTP, HTTPS and the local file system (using file://), we are introducing the OCI image format as the preferred mechanism for distributing Wasm modules.

One last thing to note is currently the Wasm Plugin API only applies to inbound HTTP filter chains.
Support for network filters and outbound traffic will be added in the future.

## Wasm image specification

We believe that containers are the ideal way to store, publish and manage proxy extensions, so we worked with Solo.io to extend their existing Proxy-Wasm container format with a variant that aims to be compatible with all registries and the CLI toolchain. Depending on your processes, you can now build your proxy extension containers using your existing container CLI tooling such as Docker CLI or [buildah](https://buildah.io/).

To learn how to build OCI images, please refer to [these instructions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md).

## Image fetcher in Istio agent

Since Istio 1.9, Istio-agent has provided a reliable solution for loading Wasm binaries, fetched from remote HTTP sources configured in the `EnvoyFilters`, by leveraging the xDS proxy inside istio-agent and Envoy’s Extension Configuration Discovery Service (ECDS). The same mechanism applies for the new Wasm API implementation in Istio 1.12. You can use HTTP remote resources reliably without concern that Envoy might get stuck with a bad configuration when a remote fetch fails.

In addition, Istio 1.12 expands this capability to Wasm OCI images. This means the Istio-agent is now able to fetch Wasm images from any OCI registry including Docker Hub, Google Container Registry(GCR), Amazon Elastic Container Registry (Amazon ECR), etc. After fetching images, Istio-agent extracts and caches Wasm binaries from them, and then inserts them into the Envoy filter chains.

{{< image width="75%"
    link="./istio-agent-architecture.svg"
    alt="Remote Wasm module fetch flow"
    caption="Remote Wasm module fetch flow"
    >}}

## Improvements in Envoy Wasm runtime

The Wasm runtime powered by V8 in Envoy has been shipped since Istio 1.5 and there have been a lot of improvements since then.

### WASI supports

First, some of the WASI (WebAssembly System Interface) system calls are now supported. For example, the `clock_time_get` system call can be made from Wasm programs so you can use `std::time::SystemTime::now()` in Rust or `time.Now().UnixNano()` in Go in your Envoy Wasm extensions, just like any other native platform. Another example is `random_get` is now supported by Envoy, so the "crypto/rand" package is available in Go as a cryptographically secure random number generator. We are also currently looking into file system support as we have seen requests for reading and writing local files from Wasm programs running in Envoy.

### Debuggability

Next is the improvement in debuggability. The Envoy runtime now emits the stack trace of your program when it causes runtime errors, for example, when null pointer exceptions occur in C++ or the panic function is called in Go or Rust. While Envoy error messages did not previously include anything about the cause, they now show the trace which you can use to debug your program:

{{< text plain >}}
Function: proxy_on_request_headers failed: Uncaught RuntimeError: unreachable
Proxy-Wasm plugin in-VM backtrace:
  0:  0xdbd - runtime._panic
  1:  0x103ab - main.anotherCalculation
  2:  0x10399 - main.someCalculation
  3:  0xea57 - main.myHeaderHandler
  4:  0xea15 - proxy_on_request_headers
{{< /text >}}

The above is an example stack trace from a Go SDK based Wasm extension. You might notice that the output does not include file names and line numbers in the trace. This is an important future work item and open issue related to the DWARF format for WebAssembly and the Exception Handling proposal for the WebAssembly specification.

### Strace support for Wasm programs

You can see `strace` equivalent logs emitted by Envoy. With Istio proxy’s component log level `wasm:trace`, you can observe all the system calls and Proxy-Wasm ABI calls that go across the boundary between Wasm virtual machines and Envoy. The following is an example of such an `strace` log stream:

{{< text plain >}}
[host->vm] proxy_on_context_create(2, 1)
[host<-vm] proxy_on_context_create return: void
[host->vm] proxy_on_request_headers(2, 8, 1)
[vm->host] wasi_snapshot_preview1.random_get(86928, 32)
[vm<-host] wasi_snapshot_preview1.random_get return: 0
[vm->host] env.proxy_log(2, 87776, 18)
{{< /text >}}

This is especially useful to debug a Wasm program's execution at runtime, for example, to verify it is not making any malicious system calls.

### Arbitrary Prometheus namespace for in-Wasm metrics

The last update is about metrics. Wasm extensions have been able to define their own custom metrics and expose them in Envoy, just like any other metric, but prior to Istio 1.12, all of these custom metrics were prefixed with the `envoy_` Prometheus namespace and users were not able to use their own namespaces. Now, you can choose whatever namespace you want, and your metrics will be exposed in Envoy as-is, without being prefixed by `envoy_`.

Note that in order to actually expose these custom metrics, you have to configure [`ProxyConfig.proxyStatsMatcher`](/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig-ProxyStatsMatcher) in `meshConfig` for global configuration or in `proxy.istio.io/config` for per proxy configuration. For detail, please refer to [`Envoy Statistics`](/docs/ops/configuration/telemetry/envoy-stats/).

## Future work and looking for feedback

Although we have announced the alpha availability of Wasm plugins, there is still a lot of work left to be done. One important work item is "Image pull secrets” support in the Wasm API which will allow you to easily consume OCI images in a private repository. Others include first-class support for L4 filters, signature verification of Wasm binaries, runtime improvements in Envoy, Proxy-Wasm SDK improvements, documentation, etc.

This is just the beginning of our plan to provide 1st-class Wasm support in Istio. We would love to hear your feedback so that we can improve the developer experience using Wasm plugins, in future releases of Istio!
