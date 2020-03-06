---
title: Telemetry V2 with Wasm runtime (Experimental)
description: How to enable Telemetry V2 with Wasm runtime (experimental).
weight: 60
---

In Istio 1.5, by default Telemetry V2 is enabled as compiled in Istio proxy filters. The same filters are also compiled to WebAssembly (Wasm) modules and shipped with Istio proxy. To enable Telemetry V2 with Wasm runtime, apply the following configuration, which is a drop-in replacement for the default Telemetry V2 installation:

{{< text bash >}}
$ kubectl apply -f https://raw.githubusercontent.com/istio/proxy/release-1.5/extensions/stats/testdata/telemetry-v2-wasm.yaml
{{< /text >}}

{{< warning >}}
There are several known limitations with Wasm based Telemetry V2:

* Proxy CPU usage will spike during Wasm module loading time (i.e. when the aforementioned configuration is applied). Increasing proxy CPU resource limit will help to speed up loading.
* Proxy baseline resource usage increases. Based on preliminary performance testing result, comparing to default Telemetry V2 installation, running Telemetry V2 with Wasm runtime will cost 30%~50% more CPU and double the memory usage.

The performance will be continuously improved in the following releases. In the next release, Telemetry V2 with Wasm will be shipped as a preview feature with better enablement in `istioctl`.
{{</ warning>}}
