---
title: Enabling Rate Limits using Envoy
description: This task shows you how to configure Istio to dynamically limit the traffic to a service.
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

This task shows you how to use Envoy's native rate limiting to dynamically limit the traffic to an Istio
service. In this task, you will apply a global rate-limit for the `productpage` service through ingress gateway that allows
1 requests per minute across all instances of the service. Additionally, you will apply a local rate-limit for each
individual `productpage` instance that will allow 4 requests per minute. In this way, you will ensure that the `productpage`
service handles a maximum of 1 request per minute through the ingress gateway, but each `productpage` instance can handle
up to 4 requests per minute, allowing for any in-mesh traffic.

## Before you begin

1. Setup Istio in a Kubernetes cluster by following the instructions in the
   [Installation Guide](/docs/setup/getting-started/).

1. Deploy the [Bookinfo](/docs/examples/bookinfo/) sample application.

## Rate limits

Envoy supports two kinds of rate limiting: global and local. Global rate
limiting uses a global gRPC rate limiting service to provide rate limiting for the entire mesh.
Local rate limiting is used to limit the rate of requests per service instance.
Local rate limiting can be used in conjunction with global rate limiting to reduce load on
the global rate limiting service.

In this task you will configure Envoy to rate limit traffic to a specific path of a service
using both global and local rate limits.

## Global rate limit

Envoy can be used to [set up global rate limits](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting) for your mesh.
Global rate limiting in Envoy uses a gRPC API for requesting quota from a rate limiting service.
A [reference implementation](https://github.com/envoyproxy/ratelimit) of the API, written in Go with a Redis backend, is used below.

1. Use the following configmap to [configure the reference implementation](https://github.com/envoyproxy/ratelimit#configuration)
    to rate limit requests to the path `/productpage` at 1 req/min, a value `api` for the coming advanced example, and all other requests at 100 req/min.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ratelimit-config
    data:
      config.yaml: |
        domain: ratelimit
        descriptors:
          - key: PATH
            value: "/productpage"
            rate_limit:
              unit: minute
              requests_per_unit: 1
          - key: PATH
            value: "api"
            rate_limit:
              unit: minute
              requests_per_unit: 2
          - key: PATH
            rate_limit:
              unit: minute
              requests_per_unit: 100
    EOF
    {{< /text >}}

1. Create a global rate limit service which implements Envoy's
  [rate limit service protocol](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/ratelimit/v3/rls.proto).
  As a reference, a demo configuration can be found [here]({{< github_blob >}}/samples/ratelimit/rate-limit-service.yaml),
  which is based on a [reference implementation](https://github.com/envoyproxy/ratelimit) provided by Envoy.

    {{< text bash >}}
    $ kubectl apply -f @samples/ratelimit/rate-limit-service.yaml@
    {{< /text >}}

1. Apply an `EnvoyFilter` to the `ingressgateway` to enable global rate limiting using Envoy's global rate limit filter.

    The patch inserts the `envoy.filters.http.ratelimit`
    [global envoy filter](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit)
    into the `HTTP_FILTER` chain. The `rate_limit_service` field specifies the external rate limit service,
    `outbound|8081||ratelimit.default.svc.cluster.local` in this case.

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
                domain: ratelimit
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

1. Apply another `EnvoyFilter` to the `ingressgateway` that defines the route configuration on which to rate limit.
    This adds [rate limit actions](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit)
    for any route from a virtual host named `bookinfo.com:80`.

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

### Global rate limit advanced case

This example uses regex to match `/api/*` `uri` and defines a rate limit action inserted at the route level
using the VirtualService http name. The PATH value `api` inserted in the prior example comes into play.

1. Change VirtualService so the prefix `/api/v1/products` is moved to a route called `api`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1beta1
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      gateways:
      - bookinfo-gateway
      hosts:
      - '*'
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            prefix: /static
        - uri:
            exact: /login
        - uri:
            exact: /logout
        route:
        - destination:
            host: productpage
            port:
              number: 9080
      - match:
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            port:
              number: 9080
        name: api
    EOF
    {{< /text >}}

1. Apply an EnvoyFilter to add the rate limits action at the route level on any 1 to 99 product:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc-api
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: HTTP_ROUTE
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: "*:8080"
                route:
                  name: "api"
          patch:
            operation: MERGE
            value:
              route:
                rate_limits:
                - actions:
                  - header_value_match:
                      descriptor_key: "PATH"
                      descriptor_value: "api"
                      headers:
                        - name: ":path"
                          safe_regex_match:
                            google_re2: {}
                            regex: "/api/v1/products/[1-9]{1,2}"
    EOF
    {{< /text >}}

## Local rate limit

Envoy supports [local rate limiting](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit) of L4 connections and HTTP requests.
This allows you to apply rate limits at the instance level, in the proxy itself, without calling any other service.

The following `EnvoyFilter` enables local rate limiting for any traffic through the `productpage` service.
The `HTTP_FILTER` patch inserts the `envoy.filters.http.local_ratelimit`
[local envoy filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit)
into the HTTP connection manager filter chain. The local rate limit filter's
[token bucket](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket)
is configured to allow 4 requests/min. The filter is also configured to add an `x-local-rate-limit`
response header to requests that are blocked.

{{< tip >}}
The statistics mentioned on the [Envoy rating limiting page](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#statistics) are disabled by default. You can enable them with the following annotations during deployment:

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
                max_tokens: 4
                tokens_per_fill: 4
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

The above configuration applies local rate limiting to all vhosts/routes. Alternatively, you can restrict it to a specific route.

The following `EnvoyFilter` enables local rate limiting for any traffic to port 9080 of the `productpage` service.
Unlike the previous configuration, there is no `token_bucket` included in the `HTTP_FILTER` patch.
The `token_bucket` is instead defined in the second (`HTTP_ROUTE`) patch which includes a `typed_per_filter_config` for the
`envoy.filters.http.local_ratelimit` local envoy filter, for routes to virtual host `inbound|http|9080`.

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
                  max_tokens: 4
                  tokens_per_fill: 4
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

### Verify global rate limit

Send traffic to the Bookinfo sample. Visit `http://$GATEWAY_URL/productpage` in your web browser or issue the following command:

{{< text bash >}}
$ for i in {1..2}; do curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{http_code}\n"; sleep 3; done
200
429
{{< /text >}}

{{< text bash >}}
$ for i in {1..3}; do curl -s "http://$GATEWAY_URL/api/v1/products/${i}" -o /dev/null -w "%{http_code}\n"; sleep 3; done
200
200
429
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` is the value set in the [Bookinfo](/docs/examples/bookinfo/) example.
{{< /tip >}}

For `/productpage`, you will see the first request go through but every following request within
a minute will get a 429 response. And for `/api/v1/products/*` you will need to hit twice,
with any number in between 1-99, until you get the 429 response within a minute.

### Verify local rate limit

Although the global rate limit at the ingress gateway limits requests to the `productpage` service at 1 req/min,
the local rate limit for `productpage` instances allows 4 req/min.
To confirm this, send internal `productpage` requests, from the `ratings` pod, using the following `curl` command:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- bash -c 'for i in {1..5}; do curl -s productpage:9080/productpage -o /dev/null -w "%{http_code}\n"; sleep 1; done'

200
200
200
200
429
{{< /text >}}

You should see no more than 4 req/min go through per `productpage` instance.

## Cleanup

{{< text bash >}}
$ kubectl delete envoyfilter filter-ratelimit -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc-api -nistio-system
$ kubectl delete envoyfilter filter-local-ratelimit-svc -nistio-system
$ kubectl delete cm ratelimit-config
$ kubectl delete -f @samples/ratelimit/rate-limit-service.yaml@
{{< /text >}}
