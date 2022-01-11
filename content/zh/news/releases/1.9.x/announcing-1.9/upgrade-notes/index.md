---
title: Istio 1.9 升级说明
description: 升级到 Istio 1.9.0 时需要考虑的重要更改。
weight: 20
release: 1.9
subtitle: 次要版本
linktitle: 1.9 升级说明
publishdate: 2021-02-09
---

当您从 Istio 1.8 升级到 Istio 1.9.x 时，您需要考虑此页面上的更改。
这些注释详细说明了故意破坏与 Istio 1.8 向后兼容性的更改。
注释还提到了在引入新行为的同时保持向后兼容性的更改。
仅当新行为对 Istio 1.8 的用户来说是意想不到的时，才会包含更改。

## 每个端口级的 PeerAuthentication 配置现在也适用于通过过滤器链{#peer-authentication-per-port-level-configuration-will-now-also-apply-to-pass-through-filter-chains}

以前，如果未在服务中定义端口号，则会忽略每个端口级别的 PeerAuthentication 配置，
并且流量将由直通过滤器链处理。
现在，即使端口号未在服务中定义，也将支持每个端口级的设置，
将添加一个特殊的直通过滤器链，以遵守相应的每个端口级的 mTLS 规范。
请检查您的 PeerAuthentication 以确保您没有在通过过滤器链时，
使用每个端口级别的配置，它不是受支持的功能，如果您在升级之前，
依赖于不受支持的行为，您应该相应地更新您的 PeerAuthentication。
如果您没有在通过过滤器链上使用每端口级别的 PeerAuthentication，则无需执行任何操作。

## 添加到跟踪跨度的 Service Tag{#service-tags-added-to-trace-spans}

Istio 现在将 Envoy 配置为在生成的跟踪跨度中，包含标识工作负载规范服务的标签。

这将导致用于跟踪后端的每个跨度的存储量略有增加。

要禁用这些附加标签，请修改 'istiod' 部署以将环境变量设置为 `PILOT_ENABLE_ISTIO_TAGS=false`。

## `EnvoyFilter` xDS v2 removal{#envoyfilter-xDS-v2-removal}

Envoy 已删除对 XDS v2 API 的支持。`EnvoyFilter` 依赖的这些 API 必须在升级之前更新。

例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: add-header
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        filterChain:
          filter:
            name: envoy.http_connection_manager
            subFilter:
              name: envoy.router
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.lua
        typed_config:
          "@type": type.googleapis.com/envoy.config.filter.http.lua.v2.Lua
          inlineCode: |
            function envoy_on_request(handle)
              handle:headers():add("foo", "bar")
            end
{{< /text >}}

应更新为：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: add-header
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_OUTBOUND
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
            subFilter:
              name: envoy.filters.http.router
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.lua
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
          inlineCode: |
            function envoy_on_request(handle)
              handle:headers():add("foo", "bar")
            end
{{< /text >}}

`istioctl analyze` 和验证 Webhook（在 `kubectl apply` 期间运行）都会对已废弃的使用发出警告：

{{< text bash >}}
$ kubectl apply -f envoyfilter.yaml
Warning: using deprecated filter name "envoy.http_connection_manager"; use "envoy.filters.network.http_connection_manager" instead
Warning: using deprecated filter name "envoy.router"; use "envoy.filters.http.router" instead
Warning: using deprecated type_url(s); type.googleapis.com/envoy.config.filter.http.lua.v2.Lua
envoyfilter.networking.istio.io/add-header configured
{{< /text >}}

如果应用了这些过滤器，Envoy 代理将拒绝配置（`The v2 xDS major version is deprecated and disabled by default.`），并且无法接收更新的配置。

一般来说，我们建议 `EnvoyFilter` 应用于特定的版本，以确保在升级过程中 `EnvoyFilter` 的变化不会破坏它们。这可以通过 `match` 子句来实现：

{{< text yaml >}}
match:
  proxy:
    proxyVersion: ^1\.9.*
{{< /text >}}

但是，由于 Istio 1.8 同时支持 v2 和 v3 XDS 版本，因此您的 `EnvoyFilter` 也可能会在升级 Istio 之前进行更新。
