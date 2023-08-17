---
title: Pull Policy for WebAssembly Modules
description: Describes how Istio determines whether to pull Wasm modules or use cached versions.
weight: 10
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
status: Alpha
---

{{< boilerplate alpha >}}

The [WasmPlugin API](/docs/reference/config/proxy_extensions/wasm-plugin) provides a method for [distributing Wasm modules](/docs/tasks/extensibility/wasm-module-distribution) to proxies.
Since each proxy will pull Wasm modules from a remote registry or an HTTP server, understanding how Istio chooses to pull modules is important in terms of usability as well as performance.

## Image pull policy and exceptions

Analogous to `ImagePullPolicy` of Kubernetes, [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin) also has the notion of `IfNotPresent` and `Always`, which means "use the cached module" and "always pull the module regardless of the cache", respectively.

Users explicitly configure the behavior for Wasm module retrieval with the `ImagePullPolicy` field. However, user-provided behavior can be overridden by Istio in the following scenarios:

1. If the user sets `sha256` in [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin), regardless of `ImagePullPolicy`, `IfNotPresent` policy is used.
1. If the `url` field points to an OCI image and it has a digest suffix (e.g., `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`), `IfNotPresent` policy is used.

When `ImagePullPolicy` is not specified for a resource, Istio defaults to `IfNotPresent` behavior. However, if the provided `url` field specifies an OCI image that has a tag value of `latest`, Istio will use `Always` behavior.

## Lifecycle of cached modules

Each proxy, whether a sidecar proxy or a gateway, caches Wasm modules. The lifetime of the cached Wasm module is therefore bounded by the lifetime of the corresponding pod.
In addition, there is an expiration mechanism for keeping the proxy memory footprint to a minimum: if a cached Wasm module is not used for a certain amount of the time, the module is purged.

This expiration can be configured via the environment variables `WASM_MODULE_EXPIRY` and `WASM_PURGE_INTERVAL` of [pilot-proxy](/docs/reference/commands/pilot-agent/#envvars), which are the duration of expiration and the interval for checking the expiration respectively.

## The meaning of "Always"

In Kubernetes, `ImagePullPolicy: Always` means that an image is pulled directly from its source each time a pod is created.
Every time a new pod is started, Kubernetes pulls the image anew.

For a `WasmPlugin`, `ImagePullPolicy: Always` means that Istio will pull an image directly from its source each time the corresponding `WasmPlugin` Kubernetes resource is created or changed.
Please note that a change not only in `spec` but also `metadata` triggers the pulling of a Wasm module when the `Always` policy is used. This can mean that an image is pulled from source several times over the lifetime of a pod, and over the lifetime of an individual proxy.
