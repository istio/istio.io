---
title: IneffectiveSelector
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

This message occurs when a workload selector in policies
like `AuthorizationPolicy`, `RequestAuthentication`, `Telemetry`, or
`WasmPlugin` does not effectively target any pods within the Kubernetes Gateway.

## Example

You will receive similar messages like:

{{< text plain >}}
Warning [IST0166] (AuthorizationPolicy default/ap-ineffective testdata/k8sgateway-selector.yaml:47) Ineffective selector on
Kubernetes Gateway bookinfo-gateway. Use the TargetRef field instead.
{{< /text >}}

when your policy's selector matches a Kubernetes Gateway.

For example, when you have a Kubernetes Gateway pod like:

{{< text yaml >}}
apiVersion: v1
kind: Pod
metadata:
  annotations:
    istio.io/rev: default
  labels:
    gateway.networking.k8s.io/gateway-name: bookinfo-gateway
  name: bookinfo-gateway-istio-6ff4cf9645-xbqmc
  namespace: default
spec:
  containers:
  - image: proxyv2:1.21.0
    name: istio-proxy
{{< /text >}}

And there is an `AuthorizationPolicy` with a `selector` like:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  namespace: default
  name: ap-ineffective
spec:
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: bookinfo-gateway
  action: DENY
  rules:
  - from:
    - source:
      namespaces: ["dev"]
    to:
    - operation:
      methods: ["POST"]
{{< /text >}}

If you have both `targetRef` and `selector` in the policy, this message will not occur. For example:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: telemetry-example
  namespace: default
spec:
  tracing:
  - randomSamplingPercentage: 10.00
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: bookinfo-gateway
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: bookinfo-gateway
{{< /text >}}

## How to resolve

Make sure you are using the `selector` field for sidecars or Istio Gateway pods, and use the `targetRef` field for
Kubernetes Gateway pods. Otherwise, the policy will not be applied.

Here is an example:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: telemetry-example
  namespace: default
spec:
  tracing:
  - randomSamplingPercentage: 10.00
  targetRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: bookinfo-gateway
{{< /text >}}
