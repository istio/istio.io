---
title: Executing Lua Scripts
description: Describes how to extend proxy functionality using inline Lua scripts.
weight: 15
keywords: [extensibility,Lua,TrafficExtension]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to extend proxy functionality using inline [Lua](https://www.lua.org/) scripts
via the [`TrafficExtension`](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API.
Lua filters are a lightweight alternative to [WebAssembly](/docs/tasks/extensibility/wasm-modules/)
for simple request and response transformations — the script is embedded directly in the resource and
executed within the Envoy proxy, with no module distribution required.

## Before you begin

Deploy the [Bookinfo](/docs/examples/bookinfo/#deploying-the-application) sample application.

## Configure a Lua script

A Lua script must define one or both of the following functions:

- `envoy_on_request(request_handle)`: called for each inbound request
- `envoy_on_response(response_handle)`: called for each outbound response

The handles provide access to headers, body, metadata, and logging. See the
[Envoy Lua filter documentation](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter)
for the complete API.

In this example, you will add a Lua filter to the ingress gateway that reads an `x-number` request
header and responds with an `x-parity` header indicating whether the value is `odd` or `even`. The
value is read during request processing and stored in dynamic metadata so it is available when
writing the response header:

{{< text syntax=bash snip_id=apply_parity >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
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

## Verify the Lua script

[Determine the ingress IP and port](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

Send a request with an `x-number` header and check that `x-parity` is set in the response:

{{< text syntax=bash snip_id=verify_parity_even >}}
$ curl -s -o /dev/null -D - -H "x-number: 42" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: even
{{< /text >}}

{{< text syntax=bash snip_id=verify_parity_odd >}}
$ curl -s -o /dev/null -D - -H "x-number: 7" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: odd
{{< /text >}}

## Ordering and scoping

When multiple `TrafficExtension` resources target the same workload, execution order is controlled
by `phase` and `priority`.

- **`phase`** sets the broad position in the filter chain: `AUTHN`, `AUTHZ`, or `STATS`.
  Extensions without a phase are inserted near the end of the chain, before the router.
- **`priority`** breaks ties within the same phase. Higher values run first.

The `match` field restricts a `TrafficExtension` to specific traffic by mode and port:

{{< text yaml >}}
spec:
  match:
  - mode: SERVER
    ports:
    - number: 8080
{{< /text >}}

Valid modes are `CLIENT` (outbound), `SERVER` (inbound), and `CLIENT_AND_SERVER` (both, the default).

## Clean up

{{< text syntax=bash snip_id=clean_up >}}
$ kubectl delete trafficextension -n istio-system parity
{{< /text >}}
