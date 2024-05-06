---
title: IneffectiveSelector
layout: analysis-message
owner: istio/wg-user-experience-maintainers
test: n/a
---

当 `AuthorizationPolicy`、`RequestAuthentication`、`Telemetry` 或 `WasmPlugin`
这类策略中的工作负载选择器没有有效指向任何 Kubernetes Gateway Pod 目标时，会出现此消息。

## 示例 {#example}

当您的策略选择器匹配到某个 Kubernetes Gateway 时，您将收到类似的消息：

{{< text plain >}}
Warning [IST0166] (AuthorizationPolicy default/ap-ineffective testdata/k8sgateway-selector.yaml:47) Ineffective selector on
Kubernetes Gateway bookinfo-gateway. Use the TargetRef field instead.
{{< /text >}}

例如，当您有一个这样的 Kubernetes Gateway Pod：

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

且有如下的 `AuthorizationPolicy` 带有 `selector`：

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

如果您在策略中同时设置了 `targetRef` 和 `selector`，将不会出现此消息。例如：

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

## 如何修复 {#how-to-resolve}

确保为 Sidecar 或 Istio Gateway Pod 使用 `selector` 字段，
并为 Kubernetes Gateway Pod 使用 `targetRef` 字段。
否则，此策略将不会生效。

以下是一个例子：

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
