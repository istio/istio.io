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

By using `ImagePullPolicy` field, the user can configure the policy explicitly except following cases:

1. If the user sets `sha256` in [WasmPlugin](/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin), regardless of `ImagePullPolicy`, `IfNotPresent` policy is used.
1. If `url` field is pointing an OCI image and it has a digest suffix (e.g., `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`), `IfNotPresent` policy is used.
1. Similar with Kubernetes, when `ImagePullPolicy` is not specified, `IfNotPresent` is assumed basically. But, in case that `url` field specifies an OCI image having `latest` tag, `Always` policy is used.

## Life of cached modules

Each proxy, which is a sidecar proxy or gateway, caches Wasm modules. Therefore, lifetime of the cached Wasm module is bounded by the lifetime of the corresponding pod.
In addition, there is expiration mechanism for keeping small footprint of memory: if a cached Wasm module is not used for the certain amount of the time, the Wasm module is purged.

The expiration can be configured via the environment variables `WASM_MODULE_EXPIRY` and `WASM_PURGE_INTERVAL` of [pilot-proxy](/docs/reference/commands/pilot-agent/#envvars), which are the duration of expiration and the interval for checking the expiration.

## Meaning of Always

In Kubernetes, meaning of `Always` is "every time for spawning new pod".
So, each time of spawning new pod, Kubernetes newly pulls the image.

In case of `WasmPlugin`, the meaning of `Always` is "every time for creating/changing the corresponding `WasmPlugin` resource".
Please note that a change not only in `spec` but also `metadata` triggers pulling of Wasm module when `Always` policy is used.