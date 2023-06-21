---
title: 更好的外部授权方式集成
subtitle: 使用 AuthorizationPolicy 将外部授权系统（例如 OPA、oauth2-proxy 等）与 Istio 进行集成
description: AuthorizationPolicy 现在支持以 CUSTOM 自定义方式委托外部系统进行授权操作。
publishdate: 2021-02-09
attribution: Yangmin Zhu (Google)
keywords: [authorization,access control,opa,oauth2]
---

## Background
## 背景 {#background}

Istio's authorization policy provides access control for services in the mesh. It is fast, powerful and a widely used feature. We have made continuous improvements to make policy more flexible since its first release in Istio 1.4, including the [`DENY` action](/docs/tasks/security/authorization/authz-deny/), [exclusion semantics](/docs/tasks/security/authorization/authz-deny/), [`X-Forwarded-For` header support](/docs/tasks/security/authorization/authz-ingress/), [nested JWT claim support](/docs/tasks/security/authorization/authz-jwt/) and more. These features improve the flexibility of the authorization policy, but there are still many use cases that cannot be supported with this model, for example:
Istio 的授权策略为网格中的服务提供访问控制。 它速度快、功能强大且使用广泛。 自 Istio 1.4 首次发布以来，我们不断改进策略以使其更加灵活，包括 [`DENY` 操作](/docs/tasks/security/authorization/authz-deny/)、[排除语义](/docs/ tasks/security/authorization/authz-deny/), [`X-Forwarded-For` 标头支持](/docs/tasks/security/authorization/authz-ingress/), [嵌套 JWT 声明支持](/docs/tasks /security/authorization/authz-jwt/) 等等。 这些特性提高了授权策略的灵活性，但仍有许多用例无法用该模型支持，例如：

- You have your own in-house authorization system that cannot be easily migrated to, or cannot be easily replaced by, the authorization policy.
- 您拥有自己的内部授权系统，该系统无法轻松迁移到授权策略或无法轻易替换为授权策略。

- You want to integrate with a 3rd-party solution (e.g. [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/envoy-introduction/) or [`oauth2` proxy](https://github.com/oauth2-proxy/oauth2-proxy)) which may require use of the [low-level Envoy configuration APIs](/docs/reference/config/networking/envoy-filter/) in Istio, or may not be possible at all.
- 您想与第 3 方解决方案集成（例如 [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/envoy-introduction/) 或 [`oauth2` proxy](https:// github.com/oauth2-proxy/oauth2-proxy)) 可能需要使用 Istio 中的[低级 Envoy 配置 API](/docs/reference/config/networking/envoy-filter/)，或者可能无法使用 根本。

- Authorization policy lacks necessary semantics for your use case.
- 授权策略缺少您的用例所需的语义。

## Solution
## 解决方案 {#solution}

In Istio 1.9, we have implemented extensibility into authorization policy by introducing a [`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action), which allows you to delegate the access control decision to an external authorization service.
在 Istio 1.9 中，我们通过引入 [`CUSTOM` 操作](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 实现了授权策略的可扩展性，它允许您将访问控制决策委托给 外部授权服务。

The `CUSTOM` action allows you to integrate Istio with an external authorization system that implements its own custom authorization logic. The following diagram shows the high level architecture of this integration:
`CUSTOM` 操作允许您将 Istio 与外部授权系统集成，该系统实现了自己的自定义授权逻辑。 下图显示了此集成的高级架构：

{{< image width="100%"
    link="./external_authz.svg"
    caption="外部授权架构"
    >}}

At configuration time, the mesh admin configures an authorization policy with a `CUSTOM` action to enable the external authorization on a proxy (either gateway or sidecar). The admin should verify the external auth service is up and running.
在配置时，网格管理员使用 CUSTOM 操作配置授权策略，以在代理（网关或 sidecar）上启用外部授权。 管理员应验证外部身份验证服务已启动并正在运行。

At runtime,
在运行时：

1. A request is intercepted by the proxy, and the proxy will send check requests to the external auth service, as configured by the user in the authorization policy.
1. 请求被代理拦截，代理将根据用户在授权策略中的配置向外部授权服务发送检查请求。

1. The external auth service will make the decision whether to allow it or not.
1. 外部授权服务将决定是否允许。

1. If allowed, the request will continue and will be enforced by any local authorization defined by `ALLOW`/`DENY` action.
1. 如果允许，请求将继续，并将由“ALLOW”/“DENY”操作定义的任何本地授权强制执行。

1. If denied, the request will be rejected immediately.
1. 如果被拒绝，请求将立即被拒绝。

Let's look at an example authorization policy with the `CUSTOM` action:
让我们看一下带有“CUSTOM”操作的示例授权策略：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istio-system
spec:
  # The selector applies to the ingress gateway in the istio-system namespace.
  # 选择器适用于 istio-system 命名空间中的入口网关。
  selector:
    matchLabels:
      app: istio-ingressgateway
  # The action "CUSTOM" delegates the access control to an external authorizer, this is different from the ALLOW/DENY action that enforces the access control right inside the proxy.
  # 操作“CUSTOM”将访问控制委托给外部授权者，这不同于在代理内部强制执行访问控制的 ALLOW/DENY 操作。
  action: CUSTOM
  # The provider specifies the name of the external authorizer defined in the meshconfig, which tells where and how to talk to the external auth service. We will cover this more later.
  # provider 指定在 meshconfig 中定义的外部授权者的名称，它告诉在哪里以及如何与外部 auth 服务对话。 稍后我们将对此进行更多介绍。
  provider:
    name: "my-ext-authz-service"
  # The rule specifies that the access control is triggered only if the request path has the prefix "/admin/". This allows you to easily enable or disable the external authorization based on the requests, avoiding the external check request if it is not needed.
  # 该规则指定只有当请求路径有前缀“/admin/”时才会触发访问控制。 这使您可以轻松地根据请求启用或禁用外部授权，避免在不需要时进行外部检查请求。
  rules:
  - to:
    - operation:
        paths: ["/admin/*"]
{{< /text >}}

It refers to a provider called `my-ext-authz-service` which is defined in the mesh config:

{{< text yaml >}}
extensionProviders:
# The name "my-ext-authz-service" is referred to by the authorization policy in its provider field.
# 名称“my-ext-authz-service”由其提供者字段中的授权策略引用。
- name: "my-ext-authz-service"
  # The "envoyExtAuthzGrpc" field specifies the type of the external authorization service is implemented by the Envoy ext-authz filter gRPC API. The other supported type is the Envoy ext-authz filter HTTP API. See more in https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter.
  # “envoyExtAuthzGrpc”字段指定外部授权服务的类型由 Envoy ext-authz filter gRPC API 实现。 另一种受支持的类型是 Envoy ext-authz 过滤器 HTTP API。 在 https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter 中查看更多信息。
  envoyExtAuthzGrpc:
    # The service and port specifies the address of the external auth service, "ext-authz.istio-system.svc.cluster.local" means the service is deployed in the mesh. It can also be defined out of the mesh or even inside the pod as a separate container.
    # 服务和端口指定外部认证服务的地址，“ext-authz.istio-system.svc.cluster.local”表示该服务部署在网格中。 它也可以在网格外定义，甚至在 pod 内定义为单独的容器。
    service: "ext-authz.istio-system.svc.cluster.local"
    port: 9000
{{< /text >}}

The authorization policy of [`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) enables the external authorization in runtime, it could be configured to trigger the external authorization conditionally based on the request using the same rule that you have already been using with other actions.
[`CUSTOM` action](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action) 的授权策略在运行时启用外部授权，可以配置为根据请求有条件地触发外部授权 使用您已经用于其他操作的相同规则。

The external authorization service is currently defined in the [`meshconfig` API](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) and referred to by its name. It could be deployed in the mesh with or without proxy. If with the proxy, you could further use `PeerAuthentication` to enable mTLS between the proxy and your external authorization service.
外部授权服务当前在 [`meshconfig` API](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) 中定义并通过其名称引用。 它可以部署在有或没有代理的网格中。 如果使用代理，您可以进一步使用“PeerAuthentication”在代理和外部授权服务之间启用 mTLS。

The `CUSTOM` action is currently in the **experimental stage**; the API might change in a non-backward compatible way based on user feedback. The authorization policy rules currently don't support authentication fields (e.g. source principal or JWT claim) when used with the `CUSTOM` action. Only one provider is allowed for a given workload, but you can still use different providers on different workloads.
`CUSTOM` 动作目前处于**实验阶段**； API 可能会根据用户反馈以非向后兼容的方式更改。 与 CUSTOM 操作一起使用时，授权策略规则目前不支持身份验证字段（例如源主体或 JWT 声明）。 给定的工作负载只允许一个提供程序，但您仍然可以在不同的工作负载上使用不同的提供程序。

For more information, please see the [Better External Authorization design doc](https://docs.google.com/document/d/1V4mCQCw7mlGp0zSQQXYoBdbKMDnkPOjeyUb85U07iSI/edit#).
有关详细信息，请参阅[更好的外部授权设计文档](https://docs.google.com/document/d/1V4mCQCw7mlGp0zSQQXYoBdbKMDnkPOjeyUb85U07iSI/edit#)。

## Example with OPA
## OPA 示例

In this section, we will demonstrate using the `CUSTOM` action with the Open Policy Agent as the external authorizer on the ingress gateway. We will conditionally enable the external authorization on all paths except `/ip`.
在本节中，我们将演示如何使用 `CUSTOM` 操作和 Open Policy Agent 作为入口网关上的外部授权方。 我们将有条件地在除 `/ip` 之外的所有路径上启用外部授权。

You can also refer to the [external authorization task](/docs/tasks/security/authorization/authz-custom/) for a more basic introduction that uses a sample `ext-authz` server.
您还可以参考 [外部授权任务](/docs/tasks/security/authorization/authz-custom/) 以获得使用示例 `ext-authz` 服务器的更基本的介绍。

### Create the example OPA policy
### 创建示例 OPA 策略

Run the following command create an OPA policy that allows the request if the prefix of the path is matched with the claim "path" (base64 encoded) in the JWT token:
运行以下命令创建一个 OPA 策略，如果路径的前缀与 JWT 令牌中的声明“路径”（base64 编码）匹配，则允许该请求：

{{< text bash >}}
$ cat > policy.rego <<EOF
package envoy.authz

import input.attributes.request.http as http_request

default allow = false

token = {"valid": valid, "payload": payload} {
    [_, encoded] := split(http_request.headers.authorization, " ")
    [valid, _, payload] := io.jwt.decode_verify(encoded, {"secret": "secret"})
}

allow {
    is_token_valid
    action_allowed
}

is_token_valid {
  token.valid
  now := time.now_ns() / 1000000000
  token.payload.nbf <= now
  now < token.payload.exp
}

action_allowed {
  startswith(http_request.path, base64url.decode(token.payload.path))
}
EOF
$ kubectl create secret generic opa-policy --from-file policy.rego
{{< /text >}}

### Deploy httpbin and OPA
### 部署 httpbin 和 OPA

Enable the sidecar injection:
启用边车注入：

{{< text bash >}}
$ kubectl label ns default istio-injection=enabled
{{< /text >}}

Run the following command to deploy the example application httpbin and OPA. The OPA could be deployed either as a separate container in the httpbin pod or completely in a separate pod:
运行以下命令部署示例应用程序 httpbin 和 OPA。 OPA 可以作为单独的容器部署在 httpbin pod 中，也可以完全部署在单独的 pod 中：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}
{{< tab name="在同一 pod 中部署 OPA" category-value="opa-same" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: httpbin-with-opa
  labels:
    app: httpbin-with-opa
    service: httpbin-with-opa
spec:
  ports:
  - name: http
    port: 8000
    targetPort: 80
  selector:
    app: httpbin-with-opa
---
# Define the service entry for the local OPA service on port 9191.
# 在9191端口定义本地OPA服务的服务入口。
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: local-opa-grpc
spec:
  hosts:
  - "local-opa-grpc.local"
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191
    protocol: GRPC
  resolution: STATIC
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: httpbin-with-opa
  labels:
    app: httpbin-with-opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin-with-opa
  template:
    metadata:
      labels:
        app: httpbin-with-opa
    spec:
      containers:
        - image: docker.io/kennethreitz/httpbin
          imagePullPolicy: IfNotPresent
          name: httpbin
          ports:
          - containerPort: 80
        - name: opa
          image: openpolicyagent/opa:latest-envoy
          securityContext:
            runAsUser: 1111
          volumeMounts:
          - readOnly: true
            mountPath: /policy
            name: opa-policy
          args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.envoy.authz.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
          livenessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: proxy-config
          configMap:
            name: proxy-config
        - name: opa-policy
          secret:
            secretName: opa-policy
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}
{{< tab name="在单独的 pod 中部署 OPA" category-value="opa-standalone" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: opa
  labels:
    app: opa
spec:
  ports:
  - name: grpc
    port: 9191
    targetPort: 9191
  selector:
    app: opa
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: opa
  labels:
    app: opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      containers:
        - name: opa
          image: openpolicyagent/opa:latest-envoy
          securityContext:
            runAsUser: 1111
          volumeMounts:
          - readOnly: true
            mountPath: /policy
            name: opa-policy
          args:
          - "run"
          - "--server"
          - "--addr=localhost:8181"
          - "--diagnostic-addr=0.0.0.0:8282"
          - "--set=plugins.envoy_ext_authz_grpc.addr=:9191"
          - "--set=plugins.envoy_ext_authz_grpc.query=data.envoy.authz.allow"
          - "--set=decision_logs.console=true"
          - "--ignore=.*"
          - "/policy/policy.rego"
          ports:
          - containerPort: 9191
          livenessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /health?plugins
              scheme: HTTP
              port: 8282
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: proxy-config
          configMap:
            name: proxy-config
        - name: opa-policy
          secret:
            secretName: opa-policy
EOF
{{< /text >}}

Deploy the httpbin as well:
同时部署 httpbin：

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Define external authorizer
### 定义外部授权者

Run the following command to edit the `meshconfig`:
运行以下命令来编辑 `meshconfig`：

{{< text bash >}}
$ kubectl edit configmap istio -n istio-system
{{< /text >}}

Add the following `extensionProviders` to the `meshconfig`:
将以下 `extensionProviders` 添加到 `meshconfig`：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}
{{< tab name="在同一 pod 中部署 OPA" category-value="opa-same" >}}

{{< text yaml >}}
apiVersion: v1
data:
  mesh: |-
    # Add the following contents:
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "local-opa-grpc.local"
        port: "9191"
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}
{{< tab name="在单独的 pod 中部署 OPA" category-value="opa-standalone" >}}

{{< text yaml >}}
apiVersion: v1
data:
  mesh: |-
    # Add the following contents:
    extensionProviders:
    - name: "opa.default"
      envoyExtAuthzGrpc:
        service: "opa.default.svc.cluster.local"
        port: "9191"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Create an AuthorizationPolicy with a CUSTOM action
### 使用 CUSTOM 操作创建 AuthorizationPolicy

Run the following command to create the authorization policy that enables the external authorization on all paths except `/ip`:
运行以下命令创建授权策略，在除/ip之外的所有路径上启用外部授权：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="Deploy OPA in the same pod" category-value="opa-same" >}}
{{< tab name="在同一 pod 中部署 OPA" category-value="opa-same" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-opa
spec:
  selector:
    matchLabels:
      app: httpbin-with-opa
  action: CUSTOM
  provider:
    name: "opa.local"
  rules:
  - to:
    - operation:
        notPaths: ["/ip"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Deploy OPA in a separate pod" category-value="opa-standalone" >}}
{{< tab name="在单独的 pod 中部署 OPA" category-value="opa-standalone" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: httpbin-opa
spec:
  selector:
    matchLabels:
      app: httpbin
  action: CUSTOM
  provider:
    name: "opa.default"
  rules:
  - to:
    - operation:
        notPaths: ["/ip"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Test the OPA policy
### 测试 OPA 策略

1. Create a client pod to send the request:
1.创建一个客户端pod来发送请求：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. Use a test JWT token signed by the OPA:
1. 使用由 OPA 签名的测试 JWT 令牌：

    {{< text bash >}}
    $ export TOKEN_PATH_HEADERS="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiTDJobFlXUmxjbk09IiwibmJmIjoxNTAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.9yl8LcZdq-5UpNLm0Hn0nnoBHXXAnK4e8RSl9vn6l98"
    {{< /text >}}

    The test JWT token has the following claims:
    测试 JWT 令牌具有以下声明：

    {{< text json >}}
    {
      "path": "L2hlYWRlcnM=",
      "nbf": 1500000000,
      "exp": 1900000000
    }
    {{< /text >}}

    The `path` claim has value `L2hlYWRlcnM=` which is the base64 encode of `/headers`.
    `path` 声明的值为 `L2hlYWRlcnM=`，它是 `/headers` 的 base64 编码。

1. Send a request to path `/headers` without a token. This should be rejected with 403 because there is no JWT token:
1. 不带令牌向路径“/headers”发送请求。 这应该被 403 拒绝，因为没有 JWT 令牌：

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Send a request to path `/get` with a valid token. This should be rejected with 403 because the path `/get` is not matched with the token `/headers`:
1. 使用有效令牌向路径“/get”发送请求。 这应该被 403 拒绝，因为路径 `/get` 与标记 `/headers` 不匹配：

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/get -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Send a request to path `/headers` with valid token. This should be allowed with 200 because the path is matched with the token:
1. 使用有效令牌向路径“/headers”发送请求。 这应该允许 200 因为路径与令牌匹配：

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Send request to path `/ip` without token. This should be allowed with 200 because the path `/ip` is excluded from authorization:
1. 不带令牌向路径“/ip”发送请求。 这应该被 200 允许，因为路径 `/ip` 被排除在授权之外：

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Check the proxy and OPA logs to confirm the result.
1. 检查代理和 OPA 日志以确认结果。

## Summary
＃＃ 概括

In Istio 1.9, the `CUSTOM` action in the authorization policy allows you to easily integrate Istio with any external authorization system with the following benefits:
在 Istio 1.9 中，授权策略中的 CUSTOM 操作允许您轻松地将 Istio 与任何外部授权系统集成，具有以下好处：

- First-class support in the authorization policy API
- 授权策略 API 中的一流支持

- Ease of usage: define the external authorizer simply with a URL and enable with the authorization policy, no more hassle with the `EnvoyFilter` API
- 易于使用：只需使用 URL 定义外部授权者并启用授权策略，不再需要使用 `EnvoyFilter` API 的麻烦

- Conditional triggering,  allowing improved performance
- 条件触发，提高性能

- Support for various deployment type of the external authorizer:
- 支持外部授权方的各种部署类型：
  - A normal service and pod with or without proxy
  - 有或没有代理的正常服务和 pod

  - Inside the workload pod as a separate container
  - 在工作负载 pod 内作为一个单独的容器

  - Outside the mesh
  - 网外

We're working to promote this feature to a more stable stage in following versions and welcome your feedback at [discuss.istio.io](https://discuss.istio.io/c/security/).
我们正在努力在后续版本中将此功能提升到更稳定的阶段，并欢迎您在 [discuss.istio.io](https://discuss.istio.io/c/security/) 上提供反馈。

## Acknowledgements
## 致谢

Thanks to `Craig Box`, `Christian Posta` and `Limin Wang` for reviewing drafts of this blog.
感谢 `Craig Box`、`Christian Posta` 和 `Limin Wang` 审阅本博客的草稿。
