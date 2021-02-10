---
title: Distributing WebAssembly Modules [Experimental]
description: Describes how to make remote WebAssembly modules available in the mesh (experimental).
weight: 10
aliases:
  - /help/ops/extensibility/distribute-remote-wasm-module
  - /docs/ops/extensibility/distribute-remote-wasm-module
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

{{< boilerplate experimental-feature-warning >}}

Istio provides the ability to [extend proxy functionality using WebAssembly (Wasm)](/blog/2020/wasm-announce/).
One of the key advantages of Wasm extensibility is that extensions can be loaded dynamically at runtime.
But first these extensions must be distributed to the proxy.
Starting in version 1.9, Istio makes this possible by allowing the Istio agent to dynamically download Wasm modules.

## Configure an HTTP Filter with a Remote Wasm Module

Here we will walk through an example of adding a basic auth extension to our mesh. We will configure Istio to pull a [basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) from a remote URI and load it with configuration to run the module on calls to the `/productpage` path.

To configure a WebAssembly filter with a remote Wasm module, two `EnvoyFilter` resources will be installed: one injects the HTTP filter, and the other provides configuration for the filter to use the remote Wasm module.

With the first `EnvoyFilter`, an HTTP filter will be injected into gateway proxies. It is configured to request the extension configuration named `istio.basic_auth` from `ads` (i.e. Aggregated Discovery Service), which is the same configuration source that Istiod uses to provide all other configuration resources. Within the configuration source, the initial fetch timeout is set to `0s`, which means that when the Envoy proxy processes a listener update with this filter, it will wait indefinitely for the first extension configuration update before accepting requests with this listener.

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

The second `EnvoyFilter` provides configuration for the filter, which is an `EXTENSION_CONFIG` patch and will be distributed to the proxy as an Envoy [Extension Configuration Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/extension) (ECDS) resource.
Once this update reaches the Istio agent, the agent will download the Wasm module and store it in the local file system.
If the download fails, the agent will reject the ECDS update to prevent invalid Wasm filter configuration from reaching the Envoy proxy.
Because of this protection, with the initial fetch timeout being set to 0, the listener update will not become effective and invalid Wasm filter will not disturb the traffic.
The important parts of this configuration are:

- Wasm `vm` configuration which points to a remote Wasm module.
- Wasm extension configuration, which is a JSON string that is consumed by the Wasm extension.

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
                     uri: https://github.com/istio-ecosystem/wasm-extensions/releases/download/{{< istio_version >}}.0/basic-auth.wasm
                   # Optional: specifying sha256 checksum will let istio agent verify the checksum of downloaded artifacts.
                   # It is **highly** recommended to provide the checksum, since missing checksum will cause the Wasm module to be downloaded repeatedly.
                   # To compute the sha256 checksum of a Wasm module, download the module and run `sha256sum` command with it.
                   # sha256: <WASM-MODULE-SHA>
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

The Istio agent will only intercept and download remote Wasm modules configured via ECDS resources.
This feature is enabled by default.
To disable ECDS interception and Wasm downloading in the Istio agent, set the `ISTIO_AGENT_ENABLE_WASM_REMOTE_LOAD_CONVERSION` environment variable to `false`.
For example, to set it globally:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    proxyMetadata:
      ISTIO_AGENT_ENABLE_WASM_REMOTE_LOAD_CONVERSION: "false"
{{< /text >}}

There are several known limitations with this module distribution mechanism, which will be addressed in future releases:

- Envoy's extension configuration discovery service only supports HTTP filters.
- Modules can only be downloaded through HTTP/HTTPS.

## Monitor Wasm Module Distribution

There are several stats which track the distribution status of remote Wasm modules.

The following stats are collected by Istio agent:

- `istio_agent_wasm_cache_lookup_count`: number of Wasm remote fetch cache lookups.
- `istio_agent_wasm_cache_entries`: number of Wasm config conversions and results, including success, no remote load, marshal failure, remote fetch failure, and miss remote fetch hint.
- `istio_agent_wasm_config_conversion_duration_bucket`: Total time in milliseconds istio-agent spends on config conversion for Wasm modules.
- `istio_agent_wasm_remote_fetch_count`: number of Wasm remote fetches and results, including success, download failure, and checksum mismatch.

If a Wasm filter configuration is rejected, either due to download failure or other reasons, istiod will also emit `pilot_total_xds_rejects` with the type label `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Develop a Wasm Extension

To learn more about Wasm module development, please refer to the guides provided in the [`istio-ecosystem/wasm-extensions` repository](https://github.com/istio-ecosystem/wasm-extensions),
which is maintained by the Istio community and used to develop Istio's Telemetry Wasm extension:

- [Write, test, deploy, and maintain a Wasm extension with C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Write unit tests for C++ Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Write integration tests for Wasm extensions](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)
