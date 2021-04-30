---
title: 升级说明
description: 升级到 Istio 1.7 时需要考虑的重要变化。
weight: 20
---

当您从 Istio 1.6.x 升级到 Istio 1.7.x 时，您需要考虑当前文档的变化说明。这些说明详细介绍了有意破坏与 Istio 1.6.x 的向后兼容性的更改。说明中还提到了在引入新行为的同时保留向后兼容性的变化。只有当新的行为对 Istio 1.6.x 的用户来说是意外的时候，才会包括更改。

## 要求 Kubernetes 1.16+ 版本{#require-Kubernetes-1.16+}

现在需要安装 Kubernetes 1.16+ 版本。

## 安装{#installation}

- `istioctl manifest apply` 已被删除，请使用 `istioctl install` 代替。
- 通过 Istioctl 安装遥测插件已被弃用，请使用[插件集成说明](/zh/docs/ops/integrations/)中的插件。

## 以非 Root 身份运行的网关{#gateways-run-as-non-root}

现在，网关默认情况下是在没有 Root 权限下的情况下运行。因此，它们将不再能够绑定到 1024 以下的端口。默认情况下，我们将绑定到有效的端口。然而，如果您在网关上明确声明端口，您可能需要修改您的安装。例如，如果您以前有以下配置：

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

应该修改为指定的有效的 `targetPort`，可以被绑定到。

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

注意：`targetPort` 只修改了网关绑定的端口。客户端仍然会连接到由 `port` 定义的端口（一般是 80 和 443），所以这个变化应该是透明的。

如果您需要以 Root 身份运行，则可以使用 `--set values.gateways.istio-ingressgateway.runAsRoot=true` 启用此选项。

## `EnvoyFilter` 语法更改{#`EnvoyFilter`-syntax-change}

使用传统的 `config` 语法的 `EnvoyFilter` 将需要迁移到新的 `typed_config`。这是由于 Envoy 的 API 中的[基本变化](https://github.com/istio/istio/issues/19885)。

由于 `EnvoyFilter` 是一个没有向后兼容性保证的 [Break Glass API](/zh/docs/reference/config/networking/envoy-filter/)，我们建议用户明确地将 `EnvoyFilter` 绑定到特定的版本，并在升级前对其进行适当测试。

例如，Istio 1.6 的配置，使用传统的 `config` 语法：

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

当升级到 Istio 1.7 时，应该添加一个新的过滤器：

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
