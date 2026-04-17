---
title: Extend waypoints with WebAssembly plugins
description: Describes how to make remote WebAssembly modules available for ambient mode.
weight: 55
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio provides the ability to extend waypoint proxies using [WebAssembly (Wasm)](/docs/concepts/extensibility/trafficextension/#webassembly-filters)
modules via the [`TrafficExtension`](/docs/reference/config/proxy_extensions/v1alpha1/traffic_extension/) API.
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

With the Kubernetes Gateway API, Istio provides a centralized entry point for managing traffic into
the service mesh. We will configure a `TrafficExtension` at the gateway level, ensuring that all
traffic passing through the gateway is subject to the extended authentication rules.

### Configure a WebAssembly plugin for a gateway

In this example, you will add an HTTP [Basic auth module](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth)
to your mesh. You will configure Istio to pull the Basic auth module from a remote image registry
and load it. It will be configured to run on calls to `/productpage`. These steps are similar to
those in [Executing WebAssembly Modules](/docs/tasks/extensibility/wasm-modules/), with the
difference being the use of the `targetRefs` field instead of label selectors.

Get the gateway name:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

Create a `TrafficExtension` targeting the `bookinfo-gateway`:

{{< text syntax=bash snip_id=apply_wasmplugin_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods:
            - "GET"
            - "POST"
          credentials:
            - "ok:test"
            - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

An HTTP filter will be injected at the gateway as an authentication filter.
The Istio agent will interpret the `TrafficExtension` configuration, download remote Wasm modules
from the OCI image registry to a local file, and inject the HTTP filter at the gateway by
referencing that file.

### Verify the traffic via the gateway

1. Test `/productpage` without credentials:

    {{< text syntax=bash snip_id=test_gateway_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

1. Test `/productpage` with the credentials configured in the `TrafficExtension` resource:

    {{< text syntax=bash snip_id=test_gateway_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## At a waypoint, for all services in a namespace

Waypoint proxies play a crucial role in Istio's ambient mode, facilitating secure and efficient
communication within the service mesh. Below, we will explore how to apply Wasm configuration to
the waypoint, enhancing the proxy functionality dynamically.

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

### Configure a WebAssembly plugin for a waypoint

Get the waypoint gateway name:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

Create a `TrafficExtension` targeting the waypoint:

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods:
            - "GET"
            - "POST"
          credentials:
            - "ok:test"
            - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### View the configured plugin

{{< text syntax=bash snip_id=get_trafficextension >}}
$ kubectl get trafficextension
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### Verify the traffic via the waypoint proxy

1. Test internal `/productpage` without credentials:

    {{< text syntax=bash snip_id=test_waypoint_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

1. Test internal `/productpage` with credentials:

    {{< text syntax=bash snip_id=test_waypoint_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## At a waypoint, for a specific service

Create a `TrafficExtension` targeting the `reviews` service so that the extension applies only to
the `reviews` service. In this configuration, the authentication token and the prefix are tailored
specifically for the reviews service, ensuring that only requests directed towards it are subjected
to this authentication mechanism.

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/reviews"
          request_methods:
            - "GET"
            - "POST"
          credentials:
            - "ok:test"
            - "MXQtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Verify the traffic targeting the service

1. Test the internal `/productpage` with the credentials configured at the generic `waypoint` proxy:

    {{< text syntax=bash snip_id=test_waypoint_service_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

1. Test the internal `/reviews` with credentials configured for the `reviews` service:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

1. Test internal `/reviews` without credentials:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

## Cleanup

1. Remove `TrafficExtension` resources:

    {{< text syntax=bash snip_id=remove_wasmplugin >}}
    $ kubectl delete trafficextension basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

1. Follow [the ambient mode uninstall guide](/docs/ambient/getting-started/#uninstall) to remove
   Istio and sample test applications.
