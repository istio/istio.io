---
title: 使用 Envoy 启用速率限制
description: 此任务将展示如何配置Istio来动态地限制服务的流量。
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

此任务向您展示如何使用Envoy的本地速率限制来动态地将流量限制到Istio服务。
在本任务中，您将通过允许的入口网关为`productpage`服务应用全局速率限制在服务的所有实例中，每分钟1次请求。
此外，您将为每个项目应用一个本地费率限制每个`productpage`实例将允许每分钟10个请求。
通过这种方式，您将确保`productpage`Service通过入口网关每分钟最多处理一个请求，但是每个`productpage`实例可以处理
每分钟最多10个请求，允许任何网内通信。

## 开始之前{#before-you-begin}

1. 在Kubernetes集群中安装Istio
   [Installation Guide](/zh/docs/setup/getting-started/)。

1. 部署[Bookinfo](/zh/docs/examples/bookinfo/)示例应用程序。

## 限制速率{#rate-limits}

Envoy支持两种速率限制:全局和本地。全局速率使用全局gRPC速率限制服务为整个网格提供速率限制。
本地速率限制用于限制每个服务实例的请求速率。局部速率限制可以与全局速率限制一起使用，以减少负载全局速率限制服务。

在本任务中，您将配置Envoy以对服务的特定路径的流量进行速率限制同时使用全局和本地速率限制。

### 全局速率{#global-rate-limit}

Envoy可以用来为您的网格[设置全局速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting)。
Envoy中的全局速率限制使用gRPC API从速率限制服务请求配额。在下面使用Redis写的后端[参考实现](https://github.com/envoyproxy/ratelimit)的API。

1. 使用下面的configmap来[配置引用实现](https://github.com/envoyproxy/ratelimit#configuration)以1分钟一个请求的速度对路径`/productpage`的限制请求进行评估，其他所有请求以一分钟100个请求的速度评估。

    {{< text yaml >}}
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
    {{< /text >}}

1. 创建一个全局速率限制服务，它实现Envoy的[速率限制服务协议](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/ratelimit/v3/rls.proto)。作为参考，可以在[这里]({{< github_blob >}}/samples/ratelimit/rate-limit-service.yaml)找到一个演示配置，它是基于Envoy提供的[参考实现](https://github.com/envoyproxy/ratelimit)。

1. 对`ingressgateway`应用`EnvoyFilter`以使Envoy的全球速率限制过滤器启用全球速率限制

 第一个patch插入`envoy.filters.http.ratelimit`[全球Envoy过滤器](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit)的过滤器到`HTTP_FILTER`链`rate_limit_service`字段指定外部速率限制服务，在本例中为`rate_limit_cluster`。

    第二个patch定义了`rate_limit_cluster`，它提供了外部速率限制服务的端点位置。

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
                      cluster_name: rate_limit_cluster
                  transport_api_version: V3
        - applyTo: CLUSTER
          match:
            cluster:
              service: ratelimit.default.svc.cluster.local
          patch:
            operation: ADD
            # Adds the rate limit service cluster for rate limit service defined in step 1.
            value:
              name: rate_limit_cluster
              type: STRICT_DNS
              connect_timeout: 10s
              lb_policy: ROUND_ROBIN
              http2_protocol_options: {}
              load_assignment:
                cluster_name: rate_limit_cluster
                endpoints:
                - lb_endpoints:
                  - endpoint:
                      address:
                         socket_address:
                          address: ratelimit.default.svc.cluster.local
                          port_value: 8081
    EOF
    {{< /text >}}

1. 对定义限速路由配置的`ingressgateway`应用另一个`EnvoyFilter`。这增加了[速率限制动作](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit)对于来自名为`*.80`的虚拟主机的任何路由。

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

Envoy支持L4连接和HTTP请求的[本地速率限制](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit)。

这允许您在代理本身的实例级应用速率限制，而无需调用任何其他服务。

下面的`EnvoyFilter`为通过`productpage`服务的任何流量启用了本地速率限制。
`HTTP_FILTER`patch会插入`envoy.filters.http`。`Local_ratelimit`[本地Envoy过滤器](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit)
进入HTTP连接管理器过滤器链。本地速率限制过滤器的[令牌桶](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket)配置为允许10请求每分。该过滤器还配置为添加`x-local-rate-limit`。对被阻塞的请求的响应头。

{{< tip >}}
在[Envoy速率限制页面](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#statistics)中提到的统计数据默认是禁用的。您可以在部署期间使用以下注释启用它们:

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

上述配置对所有vhosts/routes都进行本地速率限制。或者，您可以将其限制为特定的路由。

下面的`EnvoyFilter`为`productpage`服务的80端口的任何流量启用了本地速率限制。与前面的配置不同，`HTTP_FILTER`patch中不包含`token_bucket`。
`token_bucket`被定义在第二个(`HTTP_ROUTE`)patch中，其中包含`envoy.filters.http.local_ratelimit`的`typed_per_filter_config`。

本地Envoy过滤器，用于路由到虚拟主机`inbound|http|9080`。

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

向Bookinfo示例发送通信流。在你的网站上访问`http://$GATEWAY_URL/productpage`浏览器或发出以下命令:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` is the value set in the [Bookinfo](/zh/docs/examples/bookinfo/) example.
{{< /tip >}}

您将看到第一个请求通过，但随后的每个请求在一分钟内将得到429响应。

### 验证本地速率{#verify-local-rate-limit}

虽然入口网关的全局速率限制将对`productpage`服务的请求限制在1请求每分，`productpage`实例的本地速率限制允许10请求每分。

为了确认这一点，从`ratings`pod发送内部`productpage`请求，使用下面的`curl`命令:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
<title>Simple Bookstore App</title>
{{< /text >}}

您应该看到每个`productpage`实例的请求次数不超过10请求每分。
