---
title: Wasm-based Telemetry
description: How to enable telemetry generation with the Wasm runtime.
weight: 60
owner: istio/wg-policies-and-telemetry-maintainers
test: no
aliases:
    - /docs/reference/config/telemetry/telemetry_v2_with_wasm/
status: Experimental
---

{{< boilerplate experimental >}}

By default, telemetry generation is enabled as compiled-in Istio proxy filters. The same filters are also compiled to WebAssembly (Wasm) modules and shipped with Istio proxy. To enable telemetry generation with the Wasm runtime, install Istio with the `preview` profile:

{{< text bash >}}
$ istioctl install --set profile=preview
{{< /text >}}

Alternatively, set the following two values to enable Wasm-based Telemetry with the `default` profile:

{{< text bash >}}
$ istioctl install --set values.telemetry.v2.metadataExchange.wasmEnabled=true --set values.telemetry.v2.prometheus.wasmEnabled=true
{{< /text >}}

{{< warning >}}
There are several known limitations with Wasm-based telemetry generation:

* Proxy CPU usage will spike during Wasm module loading time (i.e. when the aforementioned configuration is applied). Increasing proxy CPU resource limit will help to speed up loading.
* Proxy baseline resource usage increases. Based on preliminary performance testing result, comparing to the default installation, running Wasm-based telemetry will cost 30%~50% more CPU and double the memory usage.

The performance will be continuously improved in the following releases.
{{</ warning>}}
