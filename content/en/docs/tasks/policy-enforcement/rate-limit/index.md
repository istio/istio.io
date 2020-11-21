---
title: Enabling Rate Limits using Envoy
description: This task shows you how to use Istio to dynamically limit the traffic to a service.
weight: 10
keywords: [policies,quotas]
aliases:
    - /docs/tasks/rate-limit.html
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

    You need to set a default route to one of the versions. Otherwise, when you send requests to the `reviews` service, Istio routes requests to all available versions randomly, and sometimes the output contains star ratings and sometimes it doesn't.

1. Set the default version for all services to v1.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

## Rate limits

In this task, you configure Istio to rate limit traffic to `productpage` whenever request is routed to a specific path.
Ratelimit using Envoy can be achieved using either Global Rate Limiting or Local Rate Limiting.


### Global Rate Limit

Envoy can be used to setup global rate limit for your mesh. More info on it can be found [here](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting)

1.  For Global Rate Limit, you need a global gRPC rate limiting service. You can either use Envoy's [reference implementation](https://github.com/envoyproxy/ratelimit) written in Go which uses a Redis backend or implement a service that implements the Envoy's defined RPC/IDL protocol.
    In the definition of the service you also define the rate limits and the descriptor on which you want
    to rate limit on. For example, below is the configmap defining rate limit on PATH header.

    {{<text yaml >}}
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ratelimit-config
    data:
      config.yaml: |
        domain: echo-ratelimit
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

1.  Apply EnvoyFilter Patch in Istio that enables global rate limit. The below patch applies rate limiting
    on any traffic through  Istio Ingressgateway and  matches  it on the  Path header of the request.

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
              name: envoy.ratelimit
              typed_config:
                "@type": type.googleapis.com/envoy.config.filter.http.rate_limit.v2.RateLimit
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
    ---
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

Envoy supports using Local Rate Limit on connection and HTTP level. This helps applying rate limit at the instance level
itself.

You can enable local rate limit by applying Envoy Filter patch as follows. Following enables 100 requests through an
 istio ingressgateway instance in 60 seconds. 

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
                    max_tokens: 100
                    tokens_per_fill: 100
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

You can also enable local rate limiting for a specific route and it can be achieved as follows:

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
                      fill_interval: 600s
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
