---
title: 使用 Envoy 启用速率限制
description: 此任务将展示如何配置 Istio 来动态地限制服务的流量。
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

此任务向您展示如何使用 Envoy 的本地速率限制来动态地将流量限制到 Istio 服务。
在本任务中，您将通过允许的入口网关为 `productpage` 服务应用全局速率限制在服务的所有实例中，每分钟 1 次请求。
此外，您将为每个项目应用一个本地速率限制每个 `productpage` 实例将允许每分钟 10 个请求。
通过这种方式，您将确保 `productpage` 服务通过入口网关每分钟最多处理一个请求，但是每个 `productpage` 实例可以处理每分钟最多 10 个请求，允许任何网格内通信。

## 开始之前{#before-you-begin}

1. 遵循[安装指南](/zh/docs/setup/getting-started/)中的指示说明在 Kubernetes 集群中安装 Istio。

1. 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序。

## 限制速率{#rate-limits}

Envoy 支持两种速率限制：全局和本地。全局速率使用全局 gRPC 速率限制服务为整个网格提供速率限制。
本地速率限制用于限制每个服务实例的请求速率。局部速率限制可以与全局速率限制一起使用，以减少负载全局速率限制服务。

在本任务中，您将配置 Envoy 以对服务的特定路径的流量进行速率限制同时使用全局和本地速率限制。

### 全局速率{#global-rate-limit}

Envoy 可以用来为您的网格[设置全局速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting)。
Envoy 中的全局速率限制使用 gRPC API 从速率限制服务请求配额。
下文使用的[参考实现](https://github.com/envoyproxy/ratelimit)后端，是用 Go 语言编写并使用 Redis 作为缓存。

1. 参考下面的 configmap [配置限流规则](https://github.com/envoyproxy/ratelimit#configuration)，对 `/productpage` 的限制速率为每分钟 1 次，其他所有请求的限制速率为每分钟 100 次。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ratelimit-config
    data:
      config.yaml: |
        domain: productpage-ratelimit
        descriptors:
          - key: PATH
            value: "/productpage"
            rate_limit:
              unit: minute
              requests_per_unit: 1
          - key: PATH
            rate_limit:
              unit: minute
              requests_per_unit: 100
    EOF
    {{< /text >}}

1. 创建一个全局速率限制服务，它实现 Envoy 的[速率限制服务协议](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/ratelimit/v3/rls.proto)。作为参考，可以在[这里]({{< github_blob >}}/samples/ratelimit/rate-limit-service.yaml)找到一个演示配置，它是基于 Envoy 提供的[参考实现](https://github.com/envoyproxy/ratelimit)。

1. 对 `ingressgateway` 应用 `EnvoyFilter`，以使用 Envoy 的全局速率限制过滤器来启用全局速率限制。

    此 patch 将 `envoy.filters.http.ratelimit` [Envoy 全局限流过滤器](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit)插入到 `HTTP_FILTER` 链中。`rate_limit_service` 字段指定外部速率限制服务，在本例中为 `outbound|8081||ratelimit.default.svc.cluster.local`。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit
      namespace: istio-system
    spec:
      workloadSelector:
        # select by label in the same namespace
        labels:
          istio: ingressgateway
      configPatches:
        # The Envoy config you want to modify
        - applyTo: HTTP_FILTER
          match:
            context: GATEWAY
            listener:
              filterChain:
                filter:
                  name: "envoy.filters.network.http_connection_manager"
                  subFilter:
                    name: "envoy.filters.http.router"
          patch:
            operation: INSERT_BEFORE
            # Adds the Envoy Rate Limit Filter in HTTP filter chain.
            value:
              name: envoy.filters.http.ratelimit
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
                # domain can be anything! Match it to the ratelimter service config
                domain: productpage-ratelimit
                failure_mode_deny: true
                timeout: 10s
                rate_limit_service:
                  grpc_service:
                    envoy_grpc:
                      cluster_name: outbound|8081||ratelimit.default.svc.cluster.local
                      authority: ratelimit.default.svc.cluster.local
                  transport_api_version: V3
    EOF
    {{< /text >}}

1. 对定义限速路由配置的 `ingressgateway` 应用另一个 `EnvoyFilter`。对于来自名为 `*.80` 的虚拟主机的任何路由，这增加了[速率限制动作](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit)。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: VIRTUAL_HOST
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: ""
                route:
                  action: ANY
          patch:
            operation: MERGE
            # Applies the rate limit rules.
            value:
              rate_limits:
                - actions: # any actions in here
                  - request_headers:
                      header_name: ":path"
                      descriptor_key: "PATH"
    EOF
    {{< /text >}}

### 本地速率限制{#local-rate-limit}

Envoy 支持 L4 连接和 HTTP 请求的[本地速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit)。

这允许您在代理本身的实例级应用速率限制，而无需调用任何其他服务。

下面的 `EnvoyFilter` 为通过 `productpage` 服务的任何流量启用了本地速率限制。
`HTTP_FILTER` patch 会插入 `envoy.filters.http.local_ratelimit` [本地 Envoy 过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit)
到 HTTP 连接管理器过滤器链中。本地速率限制过滤器的[令牌桶](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket)被配置为允许每分钟 10 个请求。该过滤器还配置为添加 `x-local-rate-limit` 响应头到被阻塞的请求。

{{< tip >}}
在 [Envoy 速率限制页面](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#statistics)中提到的统计数据默认是禁用的。您可以在部署期间使用以下注解启用它们：

{{< text yaml >}}
template:
  metadata:
    annotations:
      proxy.istio.io/config: |-
        proxyStatsMatcher:
          inclusionRegexps:
          - ".*http_local_rate_limit.*"

{{< /text >}}

{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
              token_bucket:
                max_tokens: 10
                tokens_per_fill: 10
                fill_interval: 60s
              filter_enabled:
                runtime_key: local_rate_limit_enabled
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              filter_enforced:
                runtime_key: local_rate_limit_enforced
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              response_headers_to_add:
                - append: false
                  header:
                    key: x-local-rate-limit
                    value: 'true'
EOF
{{< /text >}}

上述配置对所有 vhosts/routes 都进行本地速率限制。或者，您可以将其限制为特定的路由。

下面的 `EnvoyFilter` 为 `productpage` 服务的 80 端口的任何流量启用了本地速率限制。与前面的配置不同，`HTTP_FILTER` patch 中不包含 `token_bucket`。
`token_bucket` 被定义在第二个 (`HTTP_ROUTE`) patch 中，其中包含 `envoy.filters.http.local_ratelimit` 的 `typed_per_filter_config`。

本地 Envoy 过滤器，用于路由到虚拟主机 `inbound|http|9080`。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
    - applyTo: HTTP_ROUTE
      match:
        context: SIDECAR_INBOUND
        routeConfiguration:
          vhost:
            name: "inbound|http|9080"
            route:
              action: ANY
      patch:
        operation: MERGE
        value:
          typed_per_filter_config:
            envoy.filters.http.local_ratelimit:
              "@type": type.googleapis.com/udpa.type.v1.TypedStruct
              type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
              value:
                stat_prefix: http_local_rate_limiter
                token_bucket:
                  max_tokens: 10
                  tokens_per_fill: 10
                  fill_interval: 60s
                filter_enabled:
                  runtime_key: local_rate_limit_enabled
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                filter_enforced:
                  runtime_key: local_rate_limit_enforced
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                response_headers_to_add:
                  - append: false
                    header:
                      key: x-local-rate-limit
                      value: 'true'
EOF
{{< /text >}}

## 验证结果{#verify-the-results}

### 验证全局速率{#verify-global-rate-limit}

向 Bookinfo 示例发送通信流。在您的网站上访问 `http://$GATEWAY_URL/productpage` 浏览器或发出以下命令:

{{< text bash >}}
$ curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{http_code}\n"
429
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` 是在 [Bookinfo](/zh/docs/examples/bookinfo/) 示例中设置的值。
{{< /tip >}}

您将看到第一个请求通过，但随后的每个请求在一分钟内将得到 429 响应。

### 验证本地速率{#verify-local-rate-limit}

虽然入口网关的全局速率限制将对 `productpage` 服务的请求限制在每分钟 1 个请求，但 `productpage` 实例的本地速率限制允许每分钟 10 个请求。

为了确认这一点，使用下面的 `curl` 命令从 `ratings` Pod 发送内部 `productpage` 请求：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -s productpage:9080/productpage -o /dev/null -w "%{http_code}\n"
429
{{< /text >}}

您应该看到每个 `productpage` 实例的请求次数每分钟不超过 10 个。

## 清理{#cleanup}

{{< text bash >}}
$ kubectl delete envoyfilter filter-ratelimit -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc -nistio-system
$ kubectl delete envoyfilter filter-local-ratelimit-svc -nistio-system
$ kubectl delete cm ratelimit-config
$ kubectl delete -f @samples/ratelimit/rate-limit-service.yaml@
{{< /text >}}
