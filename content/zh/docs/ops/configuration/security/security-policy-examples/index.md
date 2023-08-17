---
title: 安全策略示例
description: 展示使用 Istio 安全策略的通用示例。
weight: 60
owner: istio/wg-security-maintainers
test: yes
---

## 背景 {#background}

本页展示了使用 Istio 安全策略的通用模式。
您可能发现这些模式在部署时很有用，还可以将其用作策略示例的快速参考。

此处展示的这些策略只是示例，在应用前需要进行修改才能适配您的实际环境。

另请参阅[身份验证](/zh/docs/tasks/security/authentication/authn-policy)和[鉴权](/zh/docs/tasks/security/authorization)任务，
了解如何使用安全策略的实践教程。

### 每个主机需要不同的 JWT 签名者 {#require-different-jwt-issuer-per-host}

JWT 校验通常用于 Ingress Gateway，您可能需要为不同的主机使用不同的 JWT 签名者。
除了[请求身份验证](/zh/docs/tasks/security/authentication/authn-policy/#end-user-authentication)策略，
您还可以为精细粒度的 JWT 校验使用鉴权策略。

如果您想要在 JWT 主体匹配的情况下访问给定的主机，请使用以下策略。
对其他主机的访问将始终被拒绝。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: jwt-per-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        # JWT 令牌的签名者必须有后缀 "@example.com"
        requestPrincipals: ["*@example.com"]
    to:
    - operation:
        hosts: ["example.com", "*.example.com"]
  - from:
    - source:
        # JWT 令牌的签名者必须有后缀 "@another.org"
        requestPrincipals: ["*@another.org"]
    to:
    - operation:
        hosts: [".another.org", "*.another.org"]
{{< /text >}}

### 命名空间隔离 {#namespace-isolation}

以下两个策略对命名空间 `foo` 启用了 `STRICT` mTLS，
允许来自相同命名空间的流量。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: foo-isolation
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
{{< /text >}}

### 将 Ingress 排除在外的命名空间隔离 {#namespace-isolation-with-ingress-exception}

以下两个策略对命名空间 `foo` 启用了 Strict mTLS，允许来自相同命名空间和
Ingress Gateway 的流量。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}

### 要求在鉴权层使用 mTLS（深度防御）{#require-mlts-in-authorization-layer}

您已将 `PeerAuthentication` 配置为 `STRICT`，但想要确保流量真实地受到 mTLS 的保护，
同时在鉴权层进行额外的检查，即深度防御。

如果主体为空，以下策略将拒绝此请求。如果使用纯文本，主体将为空。
换言之，如果主体非空，此策略将允许这些请求。
`"*"` 意味着非空匹配，与 `notPrincipals` 一起使用时意味着匹配空主体。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["*"]
{{< /text >}}

### 使用 `DENY` 策略时要求强制的鉴权检查 {#require-mandatory-authorization-check-with-deny-policy}

如果想要强制鉴权检查必须被满足且不能被另一个更宽松的 `ALLOW` 策略绕过，
您可以使用 `DENY` 策略。这种做法很有效，因为 `DENY` 策略优先于 `ALLOW`
策略，并且可以在 `ALLOW` 策略之前就拒绝请求。

除了[请求身份验证](/zh/docs/tasks/security/authentication/authn-policy/#end-user-authentication)策略之外，
还可以使用以下策略强制执行 JWT 校验。如果请求主体为空，此策略将拒绝请求。
如果 JWT 校验失败，请求主体将为空。换言之，如果请求主体非空，此策略将允许这些请求。
`"*"` 意味着非空匹配，与 `notRequestPrincipals` 一起使用时意味着匹配空请求主体。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
{{< /text >}}

类似地，使用以下策略需要强制地命名空间隔离，也允许来自 Ingress Gateway
的请求。如果命名空间不是 `foo` 且主体不是
`cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`，
此策略将拒绝请求。换言之，只有命名空间是 `foo` 或主体是
`cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`，
此策略才允许请求。

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        notPrincipals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}
