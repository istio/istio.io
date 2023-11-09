---
title: 更好的外部授权方式集成
subtitle: 使用 AuthorizationPolicy 将外部授权系统（例如 OPA、oauth2-proxy 等）与 Istio 进行集成
description: AuthorizationPolicy 现在支持以 CUSTOM 自定义方式委托外部系统进行授权操作。
publishdate: 2021-02-09
attribution: Yangmin Zhu (Google); Translated by Wilson Wu (DaoCloud)
keywords: [authorization,access control,opa,oauth2]
---

## 背景  {#background}

Istio 的授权策略为网格中的服务提供访问控制。它速度快、功能强大且使用广泛。
自 Istio 1.4 首次发布以来，我们不断改进策略以使其更加灵活，
包括 [`DENY` 操作](/zh/docs/tasks/security/authorization/authz-deny/)、
[排除语义](/zh/docs/tasks/security/authorization/authz-deny/)、
[`X-Forwarded-For` 头信息支持](/zh/docs/tasks/security/authorization/authz-ingress/)、
[嵌套 JWT 声明支持](/zh/docs/tasks/security/authorization/authz-jwt/)等等。
这些特性提高了授权策略的灵活性，但仍有许多场景无法通过该模型支持，例如：

- 您拥有自己的内部授权系统，该系统无法轻松地被迁移或替换到授权策略中。

- 您想与使用 Istio 中的[底层 Envoy 配置 API](/zh/docs/reference/config/networking/envoy-filter/)
  （例如 [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/envoy-introduction/)
  或 [`oauth2` 代理](https://github.com/oauth2-proxy/oauth2-proxy)）
  或者根本无法正常工作的第三方解决方案进行集成。

- 授权策略缺少在您场景中所需的语义内容。

## 解决方案  {#solution}

在 Istio 1.9 中，我们通过引入
[`CUSTOM` 操作](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action)实现了授权策略的可扩展性，
它允许您将访问控制决策委托给外部授权服务。

`CUSTOM` 操作允许您将 Istio 与外部授权系统集成，
该系统实现了自己的自定义授权逻辑。下图展示了此集成方式的顶层架构：

{{< image width="100%"
    link="./external_authz.svg"
    caption="外部授权架构"
    >}}

在进行配置时，网格管理员使用 `CUSTOM` 操作对授权策略进行配置，
用于在代理（网关或 Sidecar）上启用外部授权。
管理员应确认外部身份验证服务已启动且正在运行。

在运行时中：

1. 请求被代理拦截，代理将根据用户在授权策略中的配置向外部授权服务发送检查请求。

1. 外部授权服务将决定是否允许请求通过。

1. 如果允许，请求将被继续执行，并将由 `ALLOW`/`DENY` 操作定义的任意本地授权强制执行。

1. 如果被拒绝，请求将立即被终止。

让我们看一下带有 `CUSTOM` 操作的示例授权策略：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ext-authz
  namespace: istio-system
spec:
  # selector 适用于 istio-system 命名空间中的入口网关。
  selector:
    matchLabels:
      app: istio-ingressgateway
  # “CUSTOM” 操作将访问控制委托给外部授权者，
  # 这与在代理内部强制执行访问控制权的 ALLOW/DENY 操作不同。
  action: CUSTOM
  # provider 指定在 meshconfig 中定义的外部授权者的名称，
  # 从这个名称可以告知在哪里以及如何与外部身份验证服务通信。我们稍后会详细介绍这一点。
  provider:
    name: "my-ext-authz-service"
  # 这条规则指定只有请求路径有前缀 “/admin/” 时才触发访问控制。
  # 这允许您轻松地根据请求启用或禁用外部授权，避免在不需要时进行外部检查请求。
  rules:
  - to:
    - operation:
        paths: ["/admin/*"]
{{< /text >}}

此示例引用了一个在网格配置中定义的、名为 `my-ext-authz-service` 的提供程序：

{{< text yaml >}}
extensionProviders:
# name 是 “my-ext-authz-service”，被其提供程序字段中的授权策略引用。
- name: "my-ext-authz-service"
  # “envoyExtAuthzGrpc” 字段指定 Envoy ext-authz 过滤器 gRPC API 实现的外部授权服务的类型。
  # 另一种支持的类型是 Envoy ext-authz 过滤器 HTTP API。
  # See more in https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter.
  # 更多信息请参见 https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter。
  envoyExtAuthzGrpc:
    # service 和 port 指定外部 auth 服务的地址，
    # “ext-authz.istio-system.svc.cluster.local” 表示该服务部署在网格中。
    # 它也可以在网格之外定义，甚至可以在 Pod 内部定义为单独的容器。
    service: "ext-authz.istio-system.svc.cluster.local"
    port: 9000
{{< /text >}}

授权策略中的 [`CUSTOM` 操作](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action)表示在运行时中启用外部授权，
可以配置为根据请求有条件地触发外部授权，
并且使用您已经用于其他操作的相同规则进行外部授权。

外部授权服务当前在 [`meshconfig` API](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider)
中定义并通过其名称进行引用。它可以部署在任何使用或不使用代理的网格环境中。
如果使用代理，您可以进一步使用 `PeerAuthentication`
配置在代理和外部授权服务之间开启 mTLS。

`CUSTOM` 操作目前仍然处于**实验阶段**；API
可能会基于用户反馈针对后续版本进行不兼容的修改。当授权策略规则与 `CUSTOM`
操作一起使用时，其目前不支持身份验证字段（例如源主体或 JWT 声明）。
在单独的工作负载中只允许使用一个提供程序，但您仍然可以在不同的工作负载上使用不同的提供程序。

有关详细信息，请参阅 [Better External Authorization 设计文档](https://docs.google.com/document/d/1V4mCQCw7mlGp0zSQQXYoBdbKMDnkPOjeyUb85U07iSI/edit#)。

## OPA 示例  {#example-with-opa}

在本节中，我们将演示如何使用 `CUSTOM` 操作以及
Open Policy Agent 作为入口网关上的外部授权程序。我们将有条件地在除
`/ip` 之外的所有路径上启用外部授权。

您还可以参考[外部授权任务](/zh/docs/tasks/security/authorization/authz-custom/)来获得使用
`ext-authz` 服务器示例的更基础介绍。

### 创建 OPA 策略示例  {#create-the-example-opa-policy}

运行以下命令创建一个 OPA 策略，如果路径的前缀与 JWT
令牌中的声明“path”（base64 编码）匹配，则允许该请求：

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

### 部署 httpbin 和 OPA  {#deploy-httpbin-and-opa}

启用 Sidecar 注入：

{{< text bash >}}
$ kubectl label ns default istio-injection=enabled
{{< /text >}}

运行以下命令部署 httpbin 示例应用程序和 OPA。
OPA 可以作为单独的容器部署在 httpbin Pod 中，也可以完全独立部署在单独的 Pod 中：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="在同一 Pod 中部署 OPA" category-value="opa-same" >}}

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
# 在 9191 端口为本地 OPA 服务定义服务条目。
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

{{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

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

同样部署 httpbin：

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 定义外部授权程序  {#define-external-authorizer}

运行以下命令来编辑 `meshconfig`：

{{< text bash >}}
$ kubectl edit configmap istio -n istio-system
{{< /text >}}

将以下 `extensionProviders` 添加到 `meshconfig` 中：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="在同一 Pod 中部署 OPA" category-value="opa-same" >}}

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

{{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

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

### 使用 CUSTOM 操作创建 AuthorizationPolicy {#create-an-authorizationpolicy-with-a-custom-action}

运行以下命令创建授权策略，在除 `/ip` 之外的所有路径上启用外部授权：

{{< tabset category-name="opa-deploy" >}}

{{< tab name="在同一 Pod 中部署 OPA" category-value="opa-same" >}}

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

{{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

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

### 测试 OPA 策略  {##test-the-opa-policy}

1. 创建一个客户端 Pod 来发送请求：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    $ export SLEEP_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

1. 使用由 OPA 签发的测试 JWT 令牌：

    {{< text bash >}}
    $ export TOKEN_PATH_HEADERS="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJwYXRoIjoiTDJobFlXUmxjbk09IiwibmJmIjoxNTAwMDAwMDAwLCJleHAiOjE5MDAwMDAwMDB9.9yl8LcZdq-5UpNLm0Hn0nnoBHXXAnK4e8RSl9vn6l98"
    {{< /text >}}

    测试 JWT 令牌具有以下声明：

    {{< text json >}}
    {
      "path": "L2hlYWRlcnM=",
      "nbf": 1500000000,
      "exp": 1900000000
    }
    {{< /text >}}

    `path` 声明的值为 `L2hlYWRlcnM=`，它是 `/headers` 的 base64 编码格式。

1. 在不携带令牌时向路径 `/headers` 发送请求。
   因为没有 JWT 令牌，请求会以 403 状态方式被拒绝：

    {{< tabset category-name="opa-deploy" >}}

    {{< tab name="在同一个 Pod 中部署 OPA" category-value="opa-same" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin:8000/headers -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 携带有效令牌向路径 `/get` 发送请求。因为路径为 `/get`
   与令牌中 `/headers` 路径不匹配，请求也会以 403 状态方式被拒绝：

    {{< tabset category-name="opa-deploy" >}}

    {{< tab name="在同一个 Pod 中部署 OPA" category-value="opa-same" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/get -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin:8000/get -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 携带有效令牌向路径 `/headers` 发送请求。
   由于路径与令牌匹配，请求会以 200 状态被允许：

    {{< tabset category-name="opa-deploy" >}}

    {{< tab name="在同一个 Pod 中部署 OPA" category-value="opa-same" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/headers -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin:8000/headers -H "Authorization: Bearer $TOKEN_PATH_HEADERS" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 不携带令牌向路径 `/ip` 发送请求。由于路径 `/ip`
   被排除在授权之外，请求也会以 200 状态被允许：

    {{< tabset category-name="opa-deploy" >}}

    {{< tab name="在同一个 Pod 中部署 OPA" category-value="opa-same" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin-with-opa:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< /tab >}}

    {{< tab name="在单独的 Pod 中部署 OPA" category-value="opa-standalone" >}}

    {{< text bash >}}
    $ kubectl exec ${SLEEP_POD} -c sleep  -- curl http://httpbin:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< /tab >}}

    {{< /tabset >}}

1. 检查代理和 OPA 日志以确认结果。

## 总结  {#summary}

在 Istio 1.9 中，授权策略中的 `CUSTOM` 操作允许您轻松地将
Istio 与任何外部授权系统集成，并具备以下优势：

- 该模式是授权策略 API 中的推荐支持方式

- 易于使用：只需使用 URL 定义外部授权程序并启用授权策略，
  不再需要使用繁琐的 `EnvoyFilter` API

- 根据条件触发，可以提高性能

- 支持外部授权方的各种部署类型：

    - 开启或不开启代理的 Pod 或普通服务

    - 在工作负载 Pod 内作为一个单独的容器方式

    - 位于网格外部

我们正努力在后续版本中将此功能提升到更稳定的阶段，
并欢迎您在 [discuss.istio.io](https://discuss.istio.io/c/security/) 上提供反馈。

## 致谢  {#acknowledgements}

感谢 `Craig Box`、`Christian Posta` 和 `Limin Wang` 对本博客的初稿进行审核。
