---
title: Extend waypoints with Lua scripts
description: Describes how to extend ambient mode waypoint proxies using inline Lua scripts.
weight: 56
keywords: [extensibility,Lua,TrafficExtension,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to extend waypoint proxies using inline [Lua](https://www.lua.org/) scripts
via the [`TrafficExtension`](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API.
In ambient mode, `TrafficExtension` resources must be attached to a waypoint proxy using `targetRefs`.

## Before you begin

1. Set up Istio by following the [ambient mode Getting Started guide](/docs/ambient/getting-started).
1. Deploy the [Bookinfo sample application](/docs/ambient/getting-started/deploy-sample-app).
1. [Add the default namespace to the ambient mesh](/docs/ambient/getting-started/secure-and-visualize).
1. Deploy the [curl]({{< github_tree >}}/samples/curl) sample app as a test source:

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## At a gateway

Get the gateway name:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

Create a `TrafficExtension` targeting the `bookinfo-gateway` with a Lua parity filter. The filter
reads an `x-number` request header and adds an `x-parity` response header indicating whether the
value is `odd` or `even`. The value is stored in dynamic metadata during request processing so it
is available when writing the response header:

{{< text syntax=bash snip_id=apply_lua_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verify the traffic via the gateway

{{< text syntax=bash snip_id=test_gateway_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 4" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage" | grep x-parity
x-parity: even
{{< /text >}}

## At a waypoint, for all services in a namespace

### Deploy a waypoint proxy

Follow the [waypoint deployment instructions](/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy)
to deploy a waypoint proxy in the bookinfo namespace:

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

Verify traffic reaches the service:

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

Get the waypoint gateway name:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

Create a `TrafficExtension` targeting the waypoint:

{{< text syntax=bash snip_id=apply_lua_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verify the traffic via the waypoint proxy

{{< text syntax=bash snip_id=test_waypoint_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 7" http://productpage:9080/productpage | grep x-parity
x-parity: odd
{{< /text >}}

## At a waypoint, for a specific service

Remove the namespace-wide filter and replace it with one that targets only the `reviews` service:

{{< text syntax=bash snip_id=remove_waypoint_parity >}}
$ kubectl delete trafficextension parity-at-waypoint
{{< /text >}}

Create a `TrafficExtension` targeting the `reviews` service directly so that the filter applies
only to traffic destined for that service:

{{< text syntax=bash snip_id=apply_lua_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-for-reviews
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  match:
  - mode: SERVER
  phase: STATS
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
EOF
{{< /text >}}

### Verify the traffic targeting the service

{{< text syntax=bash snip_id=test_waypoint_service_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 3" http://reviews:9080/reviews/1 | grep x-parity
x-parity: odd
{{< /text >}}

## Cleanup

1. Remove `TrafficExtension` resources:

    {{< text syntax=bash snip_id=remove_traffic_extensions >}}
    $ kubectl delete trafficextension parity-at-gateway parity-for-reviews
    {{< /text >}}

1. Follow [the ambient mode uninstall guide](/docs/ambient/getting-started/#uninstall) to remove
   Istio and sample test applications.
