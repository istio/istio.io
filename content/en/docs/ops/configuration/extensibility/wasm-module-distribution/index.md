---
title: Distribute Remote WebAssembly Module
description: .
weight: 10
aliases:
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio provides the ability to [extend proxy functionality using WebAssembly (Wasm)](https://istio.io/latest/blog/2020/wasm-announce/).
One of the key advantages of proxy Wasm extensibility is that the extension can be loaded dynamically at runtime.
Before loading, the Wasm extension needs to be distributed to the proxy.
Istio provides a way to achieve this by downloading the Wasm module at Istio agent.

## Configure a HTTP Filter with Remote Wasm Module

Here we will walk through an example of adding a basic auth extension to our mesh. We will configure Istio to pull a [basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) from a remote URI and load it with configuration to protect the `/productpage` URL.

To configure a WebAssembly filter with a remote Wasm module, two `EnvoyFilter` resources will be installed: one injects the HTTP filter, and the other one provides configuration for the filter which uses the remote Wasm module.

With the first `EnvoyFilter`, an HTTP filter will be injected into gateway proxies. It is configured to request the extension configuration named as `istio.basic_auth` from `ads` (i.e. Aggregated Discovery Service), which is the same configuration source that Istiod uses to provide all other configuration resources. Along with the configuration source, the initial fetch timeout is also set, in order to prevent filters with slow or failed Wasm module remote fetch becomes effective.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
 name: basic-auth
 namespace: istio-system
spec:
 configPatches:
 - applyTo: HTTP_FILTER
   match:
     context: GATEWAY
     listener:
       filterChain:
         filter:
           name: envoy.http_connection_manager
   patch:
     operation: INSERT_BEFORE
     value:
       name: istio.basic_auth
       config_discovery:
         config_source:
           ads: {}
           initial_fetch_timeout: 0s # wait indefinitely to prevent bad Wasm fetch
         type_urls: [ "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm"]
{{< /text >}}

The second `EnvoyFilter` resource provides configuration for the filter, which is composed as an `EXTENSION_CONFIG` patch and will be distributed to the proxy as an Envoy [`Extension Configuration`](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS) resource.
Once this update reaches Istio agent, it will download the Wasm module file and store it at the local file system.
If the download fails, Istio-agent will reject the `Extension Configuration` update and prevent bad Wasm filter configuration from reaching Envoy.
Most of this `EnvoyFilter` configuration is boilerplate. The important parts are:

* Wasm `vm` configuration which points to a remote Wasm module.
* Wasm extension configuration, which is a Json string and consumed by the Wasm extension.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
 name: basic-auth-config
 namespace: istio-system
spec:
 configPatches:
 - applyTo: EXTENSION_CONFIG
   match:
     context: GATEWAY
   patch:
     operation: ADD
     value:
       name: istio.basic_auth
       typed_config:
         "@type": type.googleapis.com/udpa.type.v1.TypedStruct
         type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
         value:
           config:
             vm_config:
               vm_id: basic-auth
               runtime: envoy.wasm.runtime.v8
               code:
                 remote:
                   http_uri:
                     uri: https://github.com/istio-ecosystem/wasm-extensions/releases/download/1.9.0/basic-auth.wasm
                   # Optional: specifying checksum will let istio agent
                   # verify the checksum of download artifacts. Missing
                   # checksum will cause the Wasm module to be downloaded
                   # repeatedly
                   sha256: 6b0cecad751940eeedd68de5b9bcf940d0aac8bfc5f61c18d71985ee9460ee77
             # The configuration for the Wasm extension itself
             configuration:
               '@type': type.googleapis.com/google.protobuf.StringValue
               value: |
                 {
                   "basic_auth_rules": [
                     {
                       "prefix": "/productpage",
                       "request_methods":[ "GET", "POST" ],
                       "credentials":[ "ok:test", "YWRtaW4zOmFkbWluMw==" ]
                     }
                   ]
                 }
{{< /text >}}

Note that Istio agent will only intercept and download remote Wasm modules configured via ECDS resources.
To disable ECDS interception and Wasm downloading in Istio agent, you can set the `ISTIO_AGENT_ENABLE_WASM_REMOTE_LOAD_CONVERSION` environment variable to `false`. 
For example, to set it globally:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_AGENT_ENABLE_WASM_REMOTE_LOAD_CONVERSION: "false"
{{< /text >}}

There are several known limitations with this module distribute mechanism, which will be addressed in the following releases:

* Envoy extension configuration discovery service only supports HTTP filter configuration distribution. Networking filter configuration and others will be added in the future releases.
* Only http/https downloading is supported, OCI pulling and other highly demanded cloud blob services will be added in the future releases.

## Monitoring Wasm Module Distribution Failure

There are several stats which track the distribution status of the remote Wasm module.

The following stats are collected by Istio agent:

* `istio_agent_wasm_cache_lookup_count`: number of Wasm remote fetch cache lookup.
* `istio_agent_wasm_cache_entries`: number of Wasm config conversion count and results, including success, no remote load, marshal failure, remote fetch failure, miss remote fetch hint.
* `istio_agent_wasm_config_conversion_duration_bucket`: Total time in milliseconds istio-agent spends on converting remote load in Wasm config.
* `istio_agent_wasm_remote_fetch_count`: number of Wasm remote fetches and results, including success, download failure, and checksum mismatch.

If a Wasm filter configuration is rejected, either due to download failure or other reasons, istiod will also emit stats `pilot_total_xds_rejects` with type label `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Wasm Module Development

To learn more about Wasm module development, please refer to guides provided by [`istio-ecosystem/wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions),
which is maintained by Istio community and used to develop Istio first class Telemetry Wasm extension:

* [Write, test, deploy, and maintain a Wasm extension with C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
* [Write unit test for Wasm extension](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
* [Write integration test for Wasm extension](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)
