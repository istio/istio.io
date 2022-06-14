---
title: Pull Policy for WebAssembly Modules
description: Describes how to determine whether newly pulling Wasm modules or using the cached one.
weight: 10
aliases:
  - /help/ops/extensibility/wasm-pull-policy
  - /docs/ops/extensibility/wasm-pull-policy
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
status: Alpha
---

[WasmPlugin API](/docs/reference/config/proxy_extensions/wasm-plugin) provides the way of [distributing Wasm module](/docs/tasks/extensibility/wasm-module-distribution) to proxies.
Since each proxy should pull Wasm modules from remote registry or HTTP server, understanding of the pull policy would be important in terms of usability as well as performance.

## Image pull policy and exceptions

Inspired from `ImagePullPolicy` of Kubernetes, [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin) also has the notion of `IfNotPresent` and `Always`, which means "use the cached module" and "always pull the module regardless of the cache", respectively.

Users explicitly configure the behavior for Wasm module retrieval with the `ImagePullPolicy` field. However, user-provided behavior can be overridden by Istio in the following scenarios:

1. If the user sets `sha256` in [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin), regardless of `ImagePullPolicy`, `IfNotPresent` policy is used.
1. If the `url` field points to an OCI image and it has a digest suffix (e.g., `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`), `IfNotPresent` policy is used.

When `ImagePullPolicy` is not specified for a resource, Istio defaults to `IfNotPresent` behavior. However, if the provided `url` field specifies an OCI image that has a tag value of `latest`, Istio will use `Always` behavior.

## Life of cached modules

Each proxy, which is a sidecar proxy or gateway, caches Wasm modules. Therefore, lifetime of the cached Wasm module is bounded by the lifetime of the corresponding pod.
In addition, there is expiration mechanism for keeping small footprint of memory: if a cached Wasm module is not used for the certain amount of the time, the Wasm module is purged.

The expiration can be configured via the environment variables `WASM_MODULE_EXPIRY` and `WASM_PURGE_INTERVAL` of [pilot-proxy](/docs/reference/commands/pilot-agent/#envvars), which are the duration of expiration and the interval for checking the expiration.

## Meaning of Always

In Kubernetes, `ImagePullPolicy: Always` means that an image is pulled directly from its source each time a pod is created.
Every time of a new pod is spanned, Kubernetes pulls the image anew.

In case of `WasmPlugin`, `ImagePullPolicy: Always` means that Istio will pull an image directly from its source each time the corresponding `WasmPlugin` Kubernetes resource is created or changed.
Please note that a change not only in `spec` but also `metadata` triggers pulling of Wasm module when `Always` policy is used. This can mean that an image is pulled from source several times over the lifetime of a pod and over the lifetime of an individual proxy.