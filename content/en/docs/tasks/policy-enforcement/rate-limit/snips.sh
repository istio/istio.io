#!/bin/bash
# shellcheck disable=SC2034,SC2153,SC2155,SC2164

# Copyright Istio Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####################################################################################################
# WARNING: THIS IS AN AUTO-GENERATED FILE, DO NOT EDIT. PLEASE MODIFY THE ORIGINAL MARKDOWN FILE:
#          docs/tasks/policy-enforcement/rate-limit/index.md
####################################################################################################

snip_global_rate_limit_1() {
kubectl apply -f - <<EOF
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
}

snip_global_rate_limit_2() {
kubectl apply -f samples/ratelimit/rate-limit-service.yaml
}

snip_global_rate_limit_3() {
kubectl apply -f - <<EOF
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
}

snip_global_rate_limit_4() {
kubectl apply -f - <<EOF
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
}

snip_global_rate_limit_advanced_case_1() {
kubectl apply -f - <<EOF
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
}

snip_global_rate_limit_advanced_case_2() {
kubectl apply -f - <<EOF
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
}

! read -r -d '' snip_local_rate_limit_1 <<\ENDSNIP
template:
  metadata:
    annotations:
      proxy.istio.io/config: |-
        proxyStatsMatcher:
          inclusionRegexps:
          - ".*http_local_rate_limit.*"

ENDSNIP

snip_local_rate_limit_2() {
kubectl apply -f - <<EOF
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
}

snip_local_rate_limit_3() {
kubectl apply -f - <<EOF
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
}

snip_verify_global_rate_limit_1() {
for i in {1..2}; do curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{http_code}\n"; sleep 3; done
}

! read -r -d '' snip_verify_global_rate_limit_1_out <<\ENDSNIP
200
429
ENDSNIP

snip_verify_global_rate_limit_2() {
for i in {1..3}; do curl -s "http://$GATEWAY_URL/api/v1/products/${i}" -o /dev/null -w "%{http_code}\n"; sleep 3; done
}

! read -r -d '' snip_verify_global_rate_limit_2_out <<\ENDSNIP
200
200
429
ENDSNIP

snip_verify_local_rate_limit_1() {
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- bash -c 'for i in {1..5}; do curl -s productpage:9080/productpage -o /dev/null -w "%{http_code}\n"; sleep 1; done'
}

! read -r -d '' snip_verify_local_rate_limit_1_out <<\ENDSNIP

200
200
200
200
429
ENDSNIP

snip_cleanup_1() {
kubectl delete envoyfilter filter-ratelimit -nistio-system
kubectl delete envoyfilter filter-ratelimit-svc -nistio-system
kubectl delete envoyfilter filter-ratelimit-svc-api -nistio-system
kubectl delete envoyfilter filter-local-ratelimit-svc -nistio-system
kubectl delete cm ratelimit-config
kubectl delete -f samples/ratelimit/rate-limit-service.yaml
}
