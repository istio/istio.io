---
title: 升级说明
description: 升级到 Istio 1.7 时需要考虑的重要变化。
weight: 20
---

当你从 Istio 1.6.x 升级到 Istio 1.7.x 时，你需要考虑当前文档的变化说明。这些说明详细介绍了有意破坏与 Istio 1.6.x 的向后兼容性的更改。说明中还提到了在引入新行为的同时保留向后兼容性的变化。只有当新的行为对 Istio 1.6.x 的用户来说是意外的时候，才会包括更改。

## Require Kubernetes 1.16+

Kubernetes 1.16+ is now required for installation.

## Installation

- `istioctl manifest apply` is removed, please use `istioctl install` instead.
- Installation of telemetry addons by istioctl is deprecated, please use these [addons integration instructions](/docs/ops/integrations/).

## Gateways run as non-root

Gateways will now run without root permissions by default. As a result, they will no longer be able to bind to ports below 1024.
By default, we will bind to valid ports. However, if you are explicitly declaring ports on the gateway, you may need to modify your installation. For example, if you previously had the following configuration:

{{< text yaml >}}
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
            - port: 15021
              targetPort: 15021
              name: status-port
            - port: 80
              name: http2
            - port: 443
              name: https
{{< /text >}}

It should be changed to specify a valid `targetPort` that can be bound to:

{{< text yaml >}}
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        service:
          ports:
            - port: 15021
              targetPort: 15021
              name: status-port
            - port: 80
              name: http2
              targetPort: 8080
            - port: 443
              name: https
              targetPort: 8443
{{< /text >}}

Note: the `targetPort` only modifies which port the gateway binds to. Clients will still connect to the port defined by `port` (generally 80 and 443), so this change should be transparent.

If you need to run as root, this option can be enabled with `--set values.gateways.istio-ingressgateway.runAsRoot=true`.

## `EnvoyFilter` syntax change

`EnvoyFilter`s using the legacy `config` syntax will need to be migrated to the new `typed_config`. This is due to [underlying changes](https://github.com/istio/istio/issues/19885) in Envoy's API.

As `EnvoyFilter` is a [break glass API](/docs/reference/config/networking/envoy-filter/) without backwards compatibility guarantees, we recommend users explicitly bind `EnvoyFilter`s to specific versions and appropriately test them prior to upgrading.

For example, a configuration for Istio 1.6, using the legacy `config` syntax:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: lua-1.6
spec:
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: ANY
        listener:
          filterChain:
            filter:
              name: envoy.http_connection_manager
        proxy:
          proxyVersion: ^1\.6.*
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.lua
          config:
            inlineCode: |
              function envoy_on_request(handle)
                request_handle:headers():add("foo", "bar")
              end
{{< /text >}}

When upgrading to Istio 1.7, a new filter should be added:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: lua-1.7
spec:
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: ANY
        listener:
          filterChain:
            filter:
              name: envoy.http_connection_manager
        proxy:
          proxyVersion: ^1\.7.*
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.lua
          typed_config:
            '@type': type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
            inlineCode: |
              function envoy_on_request(handle)
                request_handle:headers():add("foo", "bar")
              end
{{< /text >}}
