---
title: Egress gateways
description: Control and observe traffic leaving the mesh using a waypoint as an egress gateway.
weight: 45
keywords: [ambient,egress,gateway,serviceentry,waypoint]
owner: istio/wg-networking-maintainers
test: yes
---

An **egress gateway** is a dedicated proxy that all outbound traffic to external services must pass through. It provides a single, auditable exit point for traffic leaving the mesh, where you can apply authorization policies, enable observability, and originate TLS.

In {{< gloss "sidecar" >}}sidecar mode{{< /gloss >}}, configuring an egress gateway for a single host requires coordinating five separate objects: a `ServiceEntry`, a `Gateway`, two `HTTPRoute` resources (one to steer mesh traffic into the gateway, one to forward traffic from the gateway to the destination), and a `DestinationRule`. Each new external host repeats most of that work.

In {{< gloss "ambient" >}}ambient mode{{< /gloss >}}, a {{< gloss "waypoint" >}}waypoint proxy{{< /gloss >}} naturally acts as an egress gateway. Ztunnel automatically routes traffic to a service's waypoint before forwarding it to the destination. If you place a [`ServiceEntry`](/docs/reference/config/networking/service-entry/) in a namespace enrolled to use a waypoint, all mesh traffic to that external host passes through the waypoint automatically, with no extra routing rules required.

## Before you begin

- Install Istio with [ambient mode enabled](/docs/ambient/install/).
- Deploy a workload to use as a traffic source. The [curl]({{< github_tree >}}/samples/curl) sample works well:

    {{< text syntax=bash snip_id=deploy_curl >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

- Label the workload's namespace for ambient mode so ztunnel intercepts its traffic:

    {{< text syntax=bash snip_id=label_default_ambient >}}
    $ kubectl label namespace default istio.io/dataplane-mode=ambient
    {{< /text >}}

## Set up the egress namespace

Create a dedicated namespace for egress resources. Isolating external service definitions and their policies from application namespaces simplifies administration and reduces the blast radius of misconfigurations.

{{< text syntax=bash snip_id=create_egress_ns >}}
$ kubectl create namespace istio-egress
$ kubectl label namespace istio-egress istio.io/dataplane-mode=ambient
{{< /text >}}

## Deploy the egress waypoint

Deploy a waypoint proxy in the egress namespace and enroll the namespace to use it. The `--enroll-namespace` flag adds the `istio.io/use-waypoint` label to the namespace, so every service defined there, including those backed by `ServiceEntry`, will be routed through the waypoint.

{{< boilerplate gateway-api-install-crds >}}

{{< text syntax=bash snip_id=apply_egress_waypoint >}}
$ istioctl waypoint apply --for service --enroll-namespace --namespace istio-egress
✅ waypoint istio-egress/waypoint applied
✅ namespace istio-egress labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

Confirm the waypoint is ready:

{{< text syntax=bash snip_id=wait_egress_waypoint >}}
$ istioctl waypoint list -n istio-egress
NAME       REVISION  TRAFFIC TYPE  PROGRAMMED
waypoint   default   service       True
{{< /text >}}

## Define an external service

Create a `ServiceEntry` in the egress namespace to represent the external host. Because the namespace is enrolled to use the waypoint, ztunnel routes all mesh traffic to this host through the waypoint automatically. The `ServiceEntry` is visible cluster-wide by default (`exportTo: *`), so ztunnel on every node resolves `httpbin.org` to the `istio-egress` waypoint without any additional configuration.

{{< text syntax=bash snip_id=apply_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

## Verify traffic routes through the egress waypoint

Send a request from the curl pod to the external host and confirm it reaches the destination:

{{< text syntax=bash snip_id=verify_egress_traffic >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

To confirm traffic traversed the waypoint, check the waypoint's Envoy stats:

{{< text syntax=bash snip_id=check_waypoint_logs >}}
$ kubectl exec -n istio-egress deploy/waypoint -c istio-proxy -- pilot-agent request GET stats | grep upstream_rq_total
{{< /text >}}

A non-zero `upstream_rq_total` count (the number of requests the waypoint forwarded upstream) confirms the waypoint is acting as the egress gateway.

{{< warning >}}
Enrolling a namespace routes traffic through the waypoint but does not prevent direct paths if the waypoint is unavailable. If egress control is a security requirement, add an `AuthorizationPolicy` that allows only the waypoint's identity, enforced at L4 by ztunnel. See [Require traffic to traverse the waypoint](/docs/ambient/usage/waypoint/#require-waypoint).
{{< /warning >}}

## Enforce access policies

Because traffic passes through the waypoint, you can attach Layer 7 authorization policies directly to the `ServiceEntry`. The policy below allows any source to issue `GET` requests to `/get` only:

{{< text syntax=bash snip_id=apply_authz_policy >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  targetRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: httpbin-org
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
        paths: ["/get"]
EOF
{{< /text >}}

After applying the policy, verify that allowed requests succeed:

{{< text syntax=bash snip_id=verify_allowed_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin.org/get
200
{{< /text >}}

Confirm that a disallowed request is rejected:

{{< text syntax=bash snip_id=verify_denied_request >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" -X POST http://httpbin.org/post
403
{{< /text >}}

## Originate TLS at the egress gateway

Application pods can send plaintext HTTP to the egress gateway; the gateway upgrades to HTTPS before forwarding to the external host. This concentrates TLS credential management at the gateway and avoids distributing certificates to each application pod.

Update the `ServiceEntry` to map the plaintext port to the TLS port, and add a `DestinationRule` to originate the TLS connection:

{{< text syntax=bash snip_id=apply_tls_origination >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: httpbin-org
  namespace: istio-egress
spec:
  hosts:
  - httpbin.org
  ports:
  - number: 80
    name: http
    protocol: HTTP
    targetPort: 443
  resolution: DNS
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: httpbin-org-tls
  namespace: istio-egress
spec:
  host: httpbin.org
  trafficPolicy:
    tls:
      mode: SIMPLE
EOF
{{< /text >}}

Verify that the application still receives a response, now sent over HTTPS by the gateway:

{{< text syntax=bash snip_id=verify_tls_origination >}}
$ kubectl exec deploy/curl -- curl -s http://httpbin.org/get | head -5
{{< /text >}}

{{< tip >}}
ztunnel provides mTLS between the application pod and the egress waypoint automatically. The `DestinationRule` here controls only the outbound TLS from the waypoint to the external host.
{{< /tip >}}

## Add an external service without TLS origination

To expose additional external hosts through the same egress waypoint, create another `ServiceEntry` in the same namespace. No additional waypoint configuration is needed because the namespace is already enrolled:

{{< text syntax=bash snip_id=apply_second_serviceentry >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: example-com
  namespace: istio-egress
spec:
  hosts:
  - example.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
EOF
{{< /text >}}

Verify that traffic to the new host also routes through the waypoint:

{{< text syntax=bash snip_id=verify_second_serviceentry >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -w "%{http_code}" http://example.com
200
{{< /text >}}

Each `ServiceEntry` in the namespace is automatically routed through the waypoint and can carry its own `AuthorizationPolicy`.

## Cleanup

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete namespace istio-egress
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl label namespace default istio.io/dataplane-mode-
{{< /text >}}

## See also

- [Configure waypoint proxies](/docs/ambient/usage/waypoint/): general waypoint deployment and enrollment
- [Require traffic to traverse the waypoint](/docs/ambient/usage/waypoint/#require-waypoint): enforce that egress traffic cannot bypass the waypoint
- [ServiceEntry visibility](/docs/ambient/usage/serviceentry-visibility/): control which namespaces can discover each `ServiceEntry`
- [Use Layer 7 features](/docs/ambient/usage/l7-features/): full list of L7 policies and routes available at a waypoint
- [Egress gateways (sidecar mode)](/docs/tasks/traffic-management/egress/egress-gateway/): the equivalent sidecar-mode configuration for comparison
