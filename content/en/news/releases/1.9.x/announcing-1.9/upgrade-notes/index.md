---
title: Istio 1.9 Upgrade Notes
description: Important changes to consider when upgrading to Istio 1.9.0.
weight: 20
release: 1.9
subtitle: Minor Release
linktitle: 1.9 Upgrade Notes
publishdate: 2021-02-09
---

When you upgrade from Istio 1.8 to Istio 1.9.x, you need to consider the changes on this page.
These notes detail the changes which purposefully break backwards compatibility with Istio 1.8.
The notes also mention changes which preserve backwards compatibility while introducing new behavior.
Changes are only included if the new behavior would be unexpected to a user of Istio 1.8.

## PeerAuthentication per-port-level configuration will now also apply to pass through filter chains

Previously the PeerAuthentication per-port-level configuration is ignored if the port number is not defined in a
service and the traffic will be handled by a pass through filter chain. Now the per-port-level setting will be
supported even if the port number is not defined in a service, a special pass through filter chain will be added
to respect the corresponding per-port-level mTLS specification.
Please check your PeerAuthentication to make sure you are not using the per-port-level configuration on pass through
filter chains, it was not a supported feature and you should update your PeerAuthentication accordingly if you are
currently relying on the unsupported behavior before the upgrade.
You don't need to do anything if you are not using per-port-level PeerAuthentication on pass through filter chains.

## Service Tags added to trace spans

Istio now configures Envoy to include tags identifying the canonical service for a workload in generated trace spans.

This will lead to a small increase in storage per span for tracing backends.

To disable these additional tags, modify the 'istiod' deployment to set an environment variable of `PILOT_ENABLE_ISTIO_TAGS=false`.

## `EnvoyFilter` XDS v2 removal

Envoy has removed support for the XDS v2 API. `EnvoyFilter`s depending on these APIs must be updated before upgrading.

For example:

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

Should be updated to:

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

Both `istioctl analyze` and the validating webhook (run during `kubectl apply`) will warn about deprecated usage:

{{< text bash >}}
$ kubectl apply -f envoyfilter.yaml
Warning: using deprecated filter name "envoy.http_connection_manager"; use "envoy.filters.network.http_connection_manager" instead
Warning: using deprecated filter name "envoy.router"; use "envoy.filters.http.router" instead
Warning: using deprecated type_url(s); type.googleapis.com/envoy.config.filter.http.lua.v2.Lua
envoyfilter.networking.istio.io/add-header configured
{{< /text >}}

If these filters are applied, the Envoy proxy will reject the configuration (`The v2 xDS major version is deprecated and disabled by default.`) and be unable to receive updated configurations.

In general, we recommend that `EnvoyFilter`s are applied to a specific version to ensure Envoy changes do not break them during upgrade. This can be done with a `match` clause:

{{< text yaml >}}
match:
  proxy:
    proxyVersion: ^1\.9.*
{{< /text >}}

However, since Istio 1.8 supports both v2 and v3 XDS versions, your `EnvoyFilter`s may also be updated before upgrading Istio.
