---
title: Enabling Rate Limits using Envoy
description: This task shows you how to use Istio to dynamically limit the traffic to a service.
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

This task shows you how to use Envoy's native rate limiting in Istio to dynamically limit the traffic to a
service.

## Before you begin

1. Setup Istio in a Kubernetes cluster by following the instructions in the
   [Installation Guide](/docs/setup/getting-started/).

1. Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

    The Bookinfo sample deploys 3 versions of the `reviews` service:

    * Version v1 doesn’t call the `ratings` service.
    * Version v2 calls the `ratings` service, and displays each rating as 1 to 5 black stars.
    * Version v3 calls the `ratings` service, and displays each rating as 1 to 5 red stars.


1. Set the default version for all services to v1 so that no ratings are returned (no stars are displayed).

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## Rate limits

In this task, you configure Istio to rate limit traffic to a specific path of the `productpage` service.
Envoy supports both Global Rate Limiting and Local Rate Limiting. Envoy's Global rate
 limting integrates directly with a global gRPC rate limiting service to provide rate limiting for the whole mesh.
 Local Rate Limiting is used to rate limit per instance level. Thus, Local rate limiting can be used in conjunction with
  global rate limiting to reduce load on the global rate limit service.

### Global Rate Limit

Envoy can be used to setup global rate limit for your mesh. More info on it can be found [here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting)

1.  Global rate limiting in Envoy uses a gRPC API for requesting quota from a rate limiting service. 
    A [reference implementation](https://github.com/envoyproxy/ratelimit) of that API, written in Go with a Redis 
    backend, is available. To provide a custom implementation, your service must provide the Envoy API.
    
    In the definition of the service you also define the rate limits and the descriptor on which you want
    to rate limit on. For example, below is the [configmap](https://github.com/envoyproxy/ratelimit#configuration) 
    defining rate limit on descriptor `PATH header` in the above reference implementation. It rate limits request to path 
    `/productpage` at 1 req/min and all other at 100 req/min.

    {{<text yaml >}}
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

1.  Apply EnvoyFilter Patch in Istio that enables global rate limit using Envoy's global rate limit filter. The below
    EnvoyFilter is applied to `ingressgateway`. The first patch is applied to `HTTP_FILTER` wherein it inserts 
    `envoy.filters.http.ratelimit` [global envoy filter](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit).
    The filter takes in the definition of external rate limit service in `rate_limit_service` field. Thus here,
    we point it to the `rate_limit_cluster`. In the second patch we define the `rate_limit_cluster`. This add the endpoint
    location of the external rate limit service.

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
                  name: "envoy.http_connection_manager"
                  subFilter:
                    name: "envoy.router"
          patch:
            operation: INSERT_BEFORE
            # Adds the Envoy Rate Limit Filter in HTTP filter chain.
            value:
              name: envoy.filters.http.ratelimit
              typed_config:
                "@type": type.googleapis.com/envoy.config.filter.http.rate_limit.v3.RateLimit
                # domain can be anything! Match it to the ratelimter service config
                domain: productpage-ratelimit
                failure_mode_deny: true
                rate_limit_service:
                  grpc_service:
                    envoy_grpc:
                      cluster_name: rate_limit_cluster
                    timeout: 10s
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
    
1.  We apply another EnvoyFilter to `ingressgateway` that defines the route configuration on which to rate limit on.
    This adds [rate limit actions](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit) for any route from virtual host named "*.80". 
    
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
                name: "*:80"
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

### Local Rate Limit

Envoy supports using [Local Rate Limit](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit) on connection and HTTP level. This helps applying rate limit at the instance level
itself. In this case of rate limiting, rate limiting happens at the proxy level itself and there is no call to any other
service or proxy.

The following EnvoyFilter enables local rate limiting for any traffic through istio ingressgateway. 
The patch is applied to `HTTP_FILTER` wherein it inserts `envoy.filters.http.local_ratelimit` [local envoy filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit) 
to HTTP Connection Manager filter chain. Envoy's local rate limit filter uses [token bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket) 
rate limit to decide if a request should be allowed or not. In the following example, token_bucket is configured to rate
limit 1 requests/min. Also, all the vhosts/routes share the same token bucket. 
It also adds response header `x-local-rate-limit` if request is rate limited.                                                                                                    


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
      istio: ingressgateway
  configPatches:
    - applyTo: HTTP_FILTER
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
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
                max_tokens: 1
                tokens_per_fill: 1
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


In the above example, local rate limiting was applied for all vhosts/routes. But we can also just restrict it for a
specific route. The following EnvoyFilter enables local rate limiting for any traffic through istio ingressgateway for
traffic through virtual host `"productpage.default.svc.cluster.local:80"`. 
The first patch is applied to `HTTP_FILTER` wherein it inserts `envoy.filters.http.local_ratelimit` [local envoy filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit) 
to HTTP Connection Manager filter chain. There is no `token_bucket` added in the config here as we are going to add it
later in the second patch to `HTTP_ROUTE`. The second patch adds `typed_per_filter_config` for `envoy.filters.http.local_ratelimit` 
local envoy filter for route whose virtual host is `"productpage.default.svc.cluster.local:80"`. `token_bucket` is
configured to rate limit 1 requests/min. It also adds response header `x-local-rate-limit` if request is rate limited.


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
      istio: ingressgateway
  configPatches:
    - applyTo: HTTP_FILTER
      listener:
        filterChain:
          filter:
            name: "envoy.http_connection_manager"
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
        context: SIDECAR_OUTBOUND
        routeConfiguration:
          vhost:
            name: "productpage.default.svc.cluster.local:80"
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
                  max_tokens: 1
                  tokens_per_fill: 1
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


## Verify the results

Send traffic to the mesh. For the Bookinfo sample, visit `http://$GATEWAY_URL/productpage` in your web
browser or issue the following command:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` is the value set in the [Bookinfo](/docs/examples/bookinfo/) example.
{{< /tip >}}

You will see the first request go through but after that every other request in a minute gets a 429 response.
