---
title: 使用 Kyverno 基于策略的鉴权
description: 利用基于 CEL 的策略，使用 Kyverno 的 Authz 服务器委托七层鉴权决策逻辑。
publishdate: 2024-11-25
attribution: "Charles-Edouard Brétéché (Nirmata); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,kyverno,policy,platform,authorization]
---

Istio 支持与许多不同项目的集成。Istio 博客最近发表了一篇关于[使用 OpenPolicyAgent 实现 L7 策略功能](../l7-policy-with-opa)的文章。
Kyverno 是一个类似的项目，今天我们将深入探讨如何将 Istio 和 Kyverno Authz 服务器结合使用，
以在您的平台中实施七层策略。

我们将通过一个简单的示例向您展示如何开始。您将看到这种组合如何成为一种可靠的选择，
可以快速透明地向企业中任何地方的应用程序团队提供策略，同时还提供安全团队进行审计和合规所需的数据。

## 尝试一下 {#try-it-out}

与 Istio 集成时，Kyverno Authz 服务器可用于为微服务实施细粒度的访问控制策略。

本指南介绍如何为简单的微服务应用程序实施访问控制策略。

### 先决条件 {#prerequisites}

- 安装了 Istio 的 Kubernetes 集群。
- 安装了 `istioctl` 命令行工具。

安装 Istio 并配置你的[网格选项](/zh/docs/reference/config/istio.mesh.v1alpha1/)以启用 Kyverno：

{{< text bash >}}
$ istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: '%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%'
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
EOF
{{< /text >}}

请注意，在配置中，我们定义了一个指向 Kyverno Authz 服务器安装的 `extensionProviders` 部分：

{{< text yaml >}}
[...]
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
[...]
{{< /text >}}

#### 部署 Kyverno Authz 服务器 {#deploy-the-kyverno-authz-server}

Kyverno Authz 服务器是一个能够处理 Envoy 外部授权请求的 GRPC 服务器。

它可以使用 Kyverno `AuthorizationPolicy` 资源进行配置，可以存储在集群内或通过外部提供。

{{< text bash >}}
$ kubectl create ns kyverno
$ kubectl label namespace kyverno istio-injection=enabled
$ helm install kyverno-authz-server --namespace kyverno --wait --repo https://kyverno.github.io/kyverno-envoy-plugin kyverno-authz-server
{{< /text >}}

#### 部署示例应用程序 {#deploy-the-sample-application}

httpbin 是一个著名的应用程序，可用于测试 HTTP 请求，并有助于快速展示如何使用请求和响应属性。

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

#### 部署一个 Istio AuthorizationPolicy {#deploy-an-istio-authorizationpolicy}

`AuthorizationPolicy` 定义了将受 Kyverno Authz 服务器保护的服务。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-kyverno-authz
  namespace: istio-system # 这将在所有网格上强制执行该策略，istio-system 是网格根命名空间
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: kyverno-authz-server
  rules: [{}] # 空规则，它将应用于带有 ext-authz: enabled 标签的选择器
EOF
{{< /text >}}

请注意，在此资源中，我们定义了您在 Istio 配置中设置的 Kyverno Authz 服务器 `extensionProvider`：

{{< text yaml >}}
[...]
  provider:
    name: kyverno-authz-server
[...]
{{< /text >}}

#### 标记应用程序以执行策略 {#label-the-app-to-enforce-the-policy}

让我们标记应用程序以执行该策略。Istio `AuthorizationPolicy` 需要该标签才能应用于示例应用程序 Pod。

{{< text bash >}}
$ kubectl patch deploy httpbin -n my-app --type=merge -p='{
  "spec": {
    "template": {
      "metadata": {
        "labels": {
          "ext-authz": "enabled"
        }
      }
    }
  }
}'
{{< /text >}}

#### 部署一个 Kyverno AuthorizationPolicy {#deploy-a-kyverno-authorizationpolicy}

Kyverno `AuthorizationPolicy` 定义了 Kyverno Authz
服务器根据给定的 Envoy [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest)
做出决策所使用的规则。

它使用 [CEL 语言](https://github.com/google/cel-spec)来分析传入的 `CheckRequest`，
并预期生成一个 [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse)作为返回。

传入的请求在 `object` 字段下可用，并且策略可以定义可供所有 `authorizations` 使用的 `variables`。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

请注意，您可以手动构建 `CheckResponse` 或使用
[CEL 辅助函数](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/)（如 `envoy.Allowed()` 和 `envoy.Denied(403)`）来简化创建响应消息：

{{< text yaml >}}
[...]
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
[...]
{{< /text >}}

## 工作原理 {#how-it-works}

当应用 `AuthorizationPolicy` 时，Istio 控制平面（istiod）将所需的配置发送到策略中选定服务的 Sidecar 代理（Envoy）。
然后，Envoy 会将请求发送到 Kyverno Authz 服务器以检查该请求是否被允许。

{{< image width="75%" link="./overview.svg" alt="Istio 和 Kyverno Authz 服务器" >}}

Envoy 代理通过配置链中的过滤器来工作。其中一个过滤器是 `ext_authz`，
它使用特定消息实现外部授权服务。任何实现正确 protobuf 的服务器都可以连接到
Envoy 代理并提供授权决策；Kyverno Authz 服务器就是其中之一。

{{< image link="./filters-chain.svg" alt="筛选器" >}}

查看 [Envoy 的授权服务文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto)，
可以看到该消息具有以下属性：

- Ok 响应

    {{< text json >}}
    {
      "status": {...},
      "ok_response": {
        "headers": [],
        "headers_to_remove": [],
        "response_headers_to_add": [],
        "query_parameters_to_set": [],
        "query_parameters_to_remove": []
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

- Denied 响应

    {{< text json >}}
    {
      "status": {...},
      "denied_response": {
        "status": {...},
        "headers": [],
        "body": "..."
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

这意味着根据来自 Authz 服务器的响应，Envoy 可以添加或删除标头、查询参数，甚至更改响应体。

我们也可以这样做，如 [Kyverno Authz 服务器文档](https://kyverno.github.io/kyverno-envoy-plugin)中所述。

## 测试 {#testing}

让我们测试简单的用法（鉴权），然后创建一个更高级的策略来展示如何使用
Kyverno Authz 服务器来修改请求和响应。

部署一个应用程序来对 httpbin 示例应用程序运行 curl 命令：

{{< text bash >}}
$ kubectl apply -n my-app -f {{< github_file >}}/samples/curl/curl.yaml
{{< /text >}}

应用策略：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

简单的场景是，如果请求包含标头 `x-force-authorized`，
且值为 `enabled` 或 `true`，则允许请求。如果标头不存在或具有不同的值，则请求将被拒绝。

在这种情况下，我们将允许和拒绝响应处理组合在一个表达式中。
但是也可以使用多个表达式，第一个返回非空响应的表达式将由 Kyverno Authz 服务器使用，
当规则不想做出决定并委托给下一个规则时，这很有用：

{{< text yaml >}}
[...]
  authorizations:
  # 当标头值匹配时允许请求
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : null
  # 否则拒绝请求
  - expression: >
      envoy.Denied(403).Response()
[...]
{{< /text >}}

### 简单规则 {#simple-rule}

以下请求将返回 `403`：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

以下请求将返回 `200`：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

### 高级操作 {#advanced-manipulations}

现在更高级的用例，应用第二条策略：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.headers[?"x-force-authorized"].orValue("") in ["enabled", "true"]
  - name: force_unauthenticated
    expression: object.attributes.request.http.headers[?"x-force-unauthenticated"].orValue("") in ["enabled", "true"]
  - name: metadata
    expression: '{"my-new-metadata": "my-new-value"}'
  authorizations:
    # 如果 force_unauthenticated -> 401
  - expression: >
      variables.force_unauthenticated
        ? envoy
            .Denied(401)
            .WithBody("Authentication Failed")
            .Response()
        : null
    # 如果 force_authorized -> 200
  - expression: >
      variables.force_authorized
        ? envoy
            .Allowed()
            .WithHeader("x-validated-by", "my-security-checkpoint")
            .WithoutHeader("x-force-authorized")
            .WithResponseHeader("x-add-custom-response-header", "added")
            .Response()
            .WithMetadata(variables.metadata)
        : null
    # 否则 -> 403
  - expression: >
      envoy
        .Denied(403)
        .WithBody("Unauthorized Request")
        .Response()
EOF
{{< /text >}}

在该政策中，您可以看到：

- 如果请求具有 `x-force-unauthenticated: true` 标头（或 `x-force-unauthenticated: enabled`），
  我们将返回 `401` 并带有 "Authentication Failed" 响应体
- 否则，如果请求具有 `x-force-authorized: true` 标头（或 `x-force-authorized: enabled`），
  我们将返回 `200` 并操作请求标头、响应标头并注入动态元数据
- 在所有其他情况下，我们将返回带有 "Unauthorized Request" 响应体的 `403`

相应的 CheckResponse 将从 Kyverno Authz 服务器返回到 Envoy 代理。
Envoy 将使用这些值来相应地修改请求和响应。

#### 更改返回体 {#change-returned-body}

让我们测试一下新功能：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

现在我们可以改变响应体。

使用 `403` 时主体将更改为 "Unauthorized Request"，运行前面的命令，您应该收到：

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### 更改返回体和状态码 {#change-returned-body-and-status-code}

运行带有标头 `x-force-unauthenticated: true` 的请求：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: true"
{{< /text >}}

这次您应该收到 "Authentication Failed" 响应体和错误 `401`：

{{< text plain >}}
Authentication Failed
http_code=401
{{< /text >}}

#### 向请求添加标头 {#adding-headers-to-request}

运行有效请求：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

您应该收到带有新标头 `x-validated-by: my-security-checkpoint`
且标头 `x-force-authorized` 被删除的回显体：

{{< text plain >}}
[...]
    "X-Validated-By": [
      "my-security-checkpoint"
    ]
[...]
http_code=200
{{< /text >}}

#### 向响应添加标头 {#adding-headers-to-response}

运行相同的请求但仅显示标头：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

你会发现在 Authz 检查期间添加的响应标头 `x-add-custom-response-header:added`：

{{< text plain >}}
HTTP/1.1 200 OK
[...]
x-add-custom-response-header: added
[...]
http_code=200
{{< /text >}}

### 过滤器之间共享数据 {#sharing-data-between-filters}

最后，您可以使用 `dynamic_metadata` 将数据传递给以下 Envoy 过滤器。

当您想要将数据传递给链中的另一个 `ext_authz` 过滤器或想要将其打印在应用程序日志中时，这很有用。

{{< image link="./dynamic-metadata.svg" alt="元数据" >}}

为此，请检查您之前设置的访问日志格式：

{{< text plain >}}
[...]
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` 是访问元数据对象的保留关键字。其余部分是要访问的过滤器的名称。

在我们的例子中，名称 `envoy.filters.http.ext_authz` 由 Istio 自动创建。
您可以通过转储 Envoy 配置来验证这一点：

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

您将看到过滤器的配置。

让我们测试一下动态元数据。在高级规则中，我们正在创建一个新的元数据条目：
`{"my-new-metadata": "my-new-value"}`。

运行请求并检查应用程序的日志：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

{{< text bash >}}
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

您将在输出中看到 Kyverno 策略配置的新属性：

{{< text plain >}}
[...]
[KYVERNO DEMO] my-new-dynamic-metadata: '{"my-new-metadata":"my-new-value","ext_authz_duration":5}'
[...]
{{< /text >}}

## 结论 {#conclusion}

在本指南中，我们展示了如何集成 Istio 和 Kyverno Authz 服务器来为简单的微服务应用程序实施策略。
我们还展示了如何使用策略来修改请求和响应属性。

这是构建可供所有应用程序团队使用的平台范围策略系统的基础示例。
