---
title: Telemetry V2 with Wasm runtime (Experimental)
description: How to enable Telemetry V2 with Wasm runtime (experimental).
weight: 60
---

Since Istio 1.5, by default Telemetry V2 is enabled as compiled in Istio proxy filters. The same filters are also compiled to WebAssembly (Wasm) modules and shipped with Istio proxy. To enable Telemetry V2 with Wasm runtime, install Istio with the `preview` profile:

{{< text bash >}}
$ istioctl manifest apply --set profile=preview
{{< /text >}}

Alternatively, set the following two values to enable Wasm based Telemetry v2 with the `default` profile:

{{< text bash >}}
$ istioctl manifest apply --set values.telemetry.v2.metadataExchange.wasmEnabled=true --set values.telemetry.v2.prometheus.wasmEnabled=true
{{< /text >}}

{{< warning >}}
There are several known limitations with Wasm based Telemetry V2:

* Proxy CPU usage will spike during Wasm module loading time (i.e. when the aforementioned configuration is applied). Increasing proxy CPU resource limit will help to speed up loading.
* Proxy baseline resource usage increases. Based on preliminary performance testing result, comparing to default Telemetry V2 installation, running Telemetry V2 with Wasm runtime will cost 30%~50% more CPU and double the memory usage.

The performance will be continuously improved in the following releases.
{{</ warning>}}