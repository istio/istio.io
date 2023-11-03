---
title: WebAssembly 模块的拉取策略
description: 描述 Istio 如何决定是拉取 Wasm 模块还是使用缓存的版本。
weight: 10
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
status: Alpha
---

{{< boilerplate alpha >}}

[WasmPlugin API](/zh/docs/reference/config/proxy_extensions/wasm-plugin)
提供了一种[将 Wasm 模块分发给](/zh/docs/tasks/extensibility/wasm-module-distribution)代理的方法。
由于每个代理将从远程镜像仓库或 HTTP 服务器中拉取 Wasm 模块，所以了解
Istio 如何选择拉取模块的机制在可用性和性能方面都很重要。

## 镜像拉取策略和异常 {#image-pull-policy-and-exceptions}

与 Kubernetes 的 `ImagePullPolicy` 类似，
[WasmPlugin](/zh/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin)
也有`IfNotPresent` 和 `Always` 的概念，这分别意味着“使用缓存模块”和“不管缓存而始终拉取模块”。

用户使用 `ImagePullPolicy` 字段显式配置 Wasm 模块检索的行为。
但是，在以下场景中 Istio 可以覆盖用户提供的行为：

1. 如果用户在 [WasmPlugin](/zh/docs/reference/config/proxy_extensions/wasm-plugin/#WasmPlugin)
   中设置 `sha256`，则不管 `ImagePullPolicy`，使用 `IfNotPresent` 策略。

1. 如果 `url` 字段指向一个 OCI 镜像且该字段有一个摘要后缀（例如
   `gcr.io/foo/bar@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`），
   则使用 `IfNotPresent` 策略。

如果没有为某资源指定 `ImagePullPolicy`，则 Istio  默认为 `IfNotPresent`
行为。但是如果提供的 `url` 字段指定一个标记值为 `latest` 的 OCI 镜像，则
Istio 将使用 `Always` 行为。

## 缓存模块的生命周期 {#lifecycle-of-cached-modules}

每个代理，无论是 Sidecar 代理还是网关，都会缓存 Wasm 模块。因此，缓存
Wasm 模块的生存期受相应 Pod 的生存期限制。此外，还有一种过期机制可以将代理内存占用量保持在最小：
如果在某个时间段内未使用缓存的 Wasm 模块，则会清除该模块。

这个过期行为可以通过 [pilot-proxy](/zh/docs/reference/commands/pilot-agent/#envvars)
的环境变量 `WASM_MODULE_EXPIRY` 和 `WASM_PURGE_INTERVAL` 进行配置，
具体包括过期的持续时间和检查过期的时间间隔。

## “始终”的含义 {#the-meaning-of-always}

在 Kubernetes 中，`ImagePullPolicy: Always` 意味着每次创建
Pod 时都会直接从其镜像源中拉取镜像。每次新的 Pod 启动时，Kubernetes
就会重新拉取新的镜像。

对于 `WasmPlugin`，`ImagePullPolicy: Always` 意味着每次创建或更改相应的
`WasmPlugin` Kubernetes 资源时，Istio 将直接从其镜像源中拉取镜像。请注意，当使用
`Always` 策略时，`spec` 和 `metadata` 中的变更都会触发 Wasm 模块的拉取。
这可能意味着在 Pod 的生命周期和单个代理的生命周期内，会多次从镜像源中拉取镜像。
