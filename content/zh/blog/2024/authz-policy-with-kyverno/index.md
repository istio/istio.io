---
title: 使用 Kyverno 基于策略的鉴权
description: Delegate Layer 7 authorization decision logic using Kyverno's Authz Server, leveraging policies based on CEL.使用 Kyverno 的 Authz Server 委托七层授权决策逻辑，利用基于 CEL 的策略。
publishdate: 2024-11-25
attribution: "Charles-Edouard Brétéché (Nirmata); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,kyverno,policy,platform,authorization]
---

Istio supports integration with many different projects.  The Istio blog recently featured a post on [L7 policy functionality with OpenPolicyAgent](../l7-policy-with-opa). Kyverno is a similar project, and today we will dive how Istio and the Kyverno Authz Server can be used together to enforce Layer 7 policies in your platform.
Istio 支持与许多不同项目的集成。Istio 博客最近发表了一篇关于 [使用 OpenPolicyAgent 实现 L7 策略功能](../l7-policy-with-opa) 的文章。Kyverno 是一个类似的项目，今天我们将深入探讨如何将 Istio 和 Kyverno Authz Server 结合使用，以在您的平台中实施第 7 层策略。

We will show you how to get started with a simple example. You will come to see how this combination is a solid option to deliver policy quickly and transparently to application team everywhere in the business, while also providing the data the security teams need for audit and compliance.
我们将通过一个简单的示例向您展示如何开始。您将看到这种组合如何成为一种可靠的选择，可以快速透明地向企业中任何地方的应用程序团队提供策略，同时还提供安全团队进行审计和合规所需的数据。

## 尝试一下 Try it out

When integrated with Istio, the Kyverno Authz Server can be used to enforce fine-grained access control policies for microservices.
与 Istio 集成时，Kyverno Authz Server 可用于为微服务实施细粒度的访问控制策略。

This guide shows how to enforce access control policies for a simple microservices application.
本指南介绍如何为简单的微服务应用程序实施访问控制策略。

### Prerequisites
### 先决条件

- A Kubernetes cluster with Istio installed.
- The `istioctl` command-line tool installed.
- 安装了 Istio 的 Kubernetes 集群。
- 安装了 `istioctl` 命令行工具。

Install Istio and configure your [mesh options](/docs/reference/config/istio.mesh.v1alpha1/) to enable Kyverno:
安装 Istio 并配置你的 [网格选项](/docs/reference/config/istio.mesh.v1alpha1/) 以启用 Kyverno：

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

Notice that in the configuration, we define an `extensionProviders` section that points to the Kyverno Authz Server installation:
请注意，在配置中，我们定义了一个指向 Kyverno Authz Server 安装的 `extensionProviders` 部分：

{{< text yaml >}}
[...]
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
[...]
{{< /text >}}

#### Deploy the Kyverno Authz Server
#### 部署 Kyverno Authz 服务器

The Kyverno Authz Server is a GRPC server capable of processing Envoy External Authorization requests.
Kyverno Authz Server 是一个能够处理 Envoy 外部授权请求的 GRPC 服务器。

It is configurable using Kyverno `AuthorizationPolicy` resources, either stored in-cluster or provided externally.
它可以使用 Kyverno `AuthorizationPolicy` 资源进行配置，可以存储在集群内或外部提供。

{{< text bash >}}
$ kubectl create ns kyverno
$ kubectl label namespace kyverno istio-injection=enabled
$ helm install kyverno-authz-server --namespace kyverno --wait --repo https://kyverno.github.io/kyverno-envoy-plugin kyverno-authz-server
{{< /text >}}

#### Deploy the sample application
#### 部署示例应用程序

httpbin is a well-known application that can be used to test HTTP requests and helps to show quickly how we can play with the request and response attributes.
httpbin 是一个著名的应用程序，可用于测试 HTTP 请求，并有助于快速展示如何使用请求和响应属性。

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

#### Deploy an Istio AuthorizationPolicy
#### 部署 Istio AuthorizationPolicy

An `AuthorizationPolicy` defines the services that will be protected by the Kyverno Authz Server.
“AuthorizationPolicy”定义了将受 Kyverno Authz 服务器保护的服务。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-kyverno-authz
  namespace: istio-system # This enforce the policy on all the mesh, istio-system being the mesh root namespace 这将在所有网格上强制执行该策略，istio-system 是网格根命名空间
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: kyverno-authz-server
  rules: [{}] # Empty rules, it will apply to selectors with ext-authz: enabled label 空规则，它将应用于带有 ext-authz: enabled 标签的选择器
EOF
{{< /text >}}

Notice that in this resource, we define the Kyverno Authz Server `extensionProvider` you set in the Istio configuration:
请注意，在此资源中，我们定义了您在 Istio 配置中设置的 Kyverno Authz Server `extensionProvider`：

{{< text yaml >}}
[...]
  provider:
    name: kyverno-authz-server
[...]
{{< /text >}}

#### Label the app to enforce the policy
#### 标记应用程序以执行策略

Let’s label the app to enforce the policy. The label is needed for the Istio `AuthorizationPolicy` to apply to the sample application pods.
让我们标记应用程序以执行该策略。Istio“AuthorizationPolicy”需要该标签才能应用于示例应用程序 pod。

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

#### Deploy a Kyverno AuthorizationPolicy
#### 部署 Kyverno 授权策略

A Kyverno `AuthorizationPolicy` defines the rules used by the Kyverno Authz Server to make a decision based on a given Envoy [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest).
Kyverno `AuthorizationPolicy` 定义了 Kyverno Authz 服务器根据给定的 Envoy [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest) 做出决策所使用的规则。

It uses the [CEL language](https://github.com/google/cel-spec) to analyze an incoming `CheckRequest` and is expected to produce a [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse) in return.
它使用 [CEL 语言](https://github.com/google/cel-spec)来分析传入的 `CheckRequest`，并预期生成一个 [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse)作为返回。

The incoming request is available under the `object` field, and the policy can define `variables` that will be made available to all `authorizations`.
传入的请求在“对象”字段下可用，并且策略可以定义可供所有“授权”使用的“变量”。

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

Notice that you can build the `CheckResponse` by hand or use [CEL helper functions](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/) like `envoy.Allowed()` and `envoy.Denied(403)` to simplify creating the response message:
请注意，您可以手动构建 `CheckResponse` 或使用 [CEL 辅助函数](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/)（如 `envoy.Allowed()` 和 `envoy.Denied(403)`）来简化创建响应消息：

{{< text yaml >}}
[...]
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
[...]
{{< /text >}}

## 工作原理 How it works

When applying the `AuthorizationPolicy`, the Istio control plane (istiod) sends the required configurations to the sidecar proxy (Envoy) of the selected services in the policy. Envoy will then send the request to the Kyverno Authz Server to check if the request is allowed or not.
当应用“AuthorizationPolicy”时，Istio 控制平面（istiod）将所需的配置发送到策略中选定服务的 sidecar 代理（Envoy）。然后，Envoy 会将请求发送到 Kyverno Authz 服务器以检查该请求是否被允许。

{{< image width="75%" link="./overview.svg" alt="Istio 和 Kyverno Authz 服务器" >}}

The Envoy proxy works by configuring filters in a chain. One of those filters is `ext_authz`, which implements an external authorization service with a specific message. Any server implementing the correct protobuf can connect to the Envoy proxy and provide the authorization decision; The Kyverno Authz Server is one of those servers.
Envoy 代理通过配置链中的过滤器来工作。其中一个过滤器是“ext_authz”，它使用特定消息实现外部授权服务。任何实现正确 protobuf 的服务器都可以连接到 Envoy 代理并提供授权决策；Kyverno Authz Server 就是其中之一。

{{< image link="./filters-chain.svg" alt="筛选器" >}}

Reviewing [Envoy's Authorization service documentation](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), you can see that the message has these attributes:
查看 [Envoy 的授权服务文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto)，可以看到该消息具有以下属性：

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

This means that based on the response from the authz server, Envoy can add or remove headers, query parameters, and even change the response body.
这意味着根据来自 authz 服务器的响应，Envoy 可以添加或删除标头、查询参数，甚至更改响应主体。

We can do this as well, as documented in the [Kyverno Authz Server documentation](https://kyverno.github.io/kyverno-envoy-plugin).
我们也可以这样做，如 [Kyverno Authz Server 文档](https://kyverno.github.io/kyverno-envoy-plugin) 中所述。

## 测试 Testing

Let's test the simple usage (authorization) and then let's create a more advanced policy to show how we can use the Kyverno Authz Server to modify the request and response.
让我们测试简单的用法（授权），然后创建一个更高级的策略来展示如何使用 Kyverno Authz Server 来修改请求和响应。

Deploy an app to run curl commands to the httpbin sample application:
部署一个应用程序来对 httpbin 示例应用程序运行 curl 命令：

{{< text bash >}}
$ kubectl apply -n my-app -f {{< github_file >}}/samples/curl/curl.yaml
{{< /text >}}

Apply the policy:
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

The simple scenario is to allow requests if they contain the header `x-force-authorized` with the value `enabled` or `true`. If the header is not present or has a different value, the request will be denied.
简单的场景是，如果请求包含标头“x-force-authorized”，且值为“enabled”或“true”，则允许请求。如果标头不存在或具有不同的值，则请求将被拒绝。

In this case, we combined allow and denied response handling in a single expression. However it is possible to use multiple expressions, the first one returning a non null response will be used by the Kyverno Authz Server, this is useful when a rule doesn't want to make a decision and delegate to the next rule:
在这种情况下，我们将允许和拒绝响应处理组合在一个表达式中。但是可以使用多个表达式，第一个返回非空响应的表达式将由 Kyverno Authz 服务器使用，当规则不想做出决定并委托给下一个规则时，这很有用：

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

### Simple rule
### 简单规则

The following request will return `403`:
以下请求将返回“403”：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

The following request will return `200`:
以下请求将返回“200”：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

### Advanced manipulations
### 高级操作

Now the more advanced use case, apply the second policy:
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

In that policy, you can see:
在该政策中，您可以看到：

- If the request has the `x-force-unauthenticated: true`  header  (or `x-force-unauthenticated: enabled`), we will return `401` with the "Authentication Failed" body
- 如果请求具有 `x-force-unauthenticated: true` 标头（或 `x-force-unauthenticated: enabled`），我们将返回 `401` 并带有“身份验证失败”主体
- Else, if the request has the `x-force-authorized: true`  header  (or `x-force-authorized: enabled`), we will return `200` and manipulate request headers, response headers and inject dynamic metadata
- 否则，如果请求具有 `x-force-authorized: true` 标头（或 `x-force-authorized: enabled`），我们将返回 `200` 并操作请求标头、响应标头并注入动态元数据
- In all other cases, we will return `403` with the "Unauthorized Request" body
- 在所有其他情况下，我们将返回带有“未授权请求”主体的“403”

The corresponding CheckResponse will be returned to the Envoy proxy from the Kyverno Authz Server. Envoy will use those values to modify the request and response accordingly.
相应的 CheckResponse 将从 Kyverno Authz 服务器返回到 Envoy 代理。Envoy 将使用这些值来相应地修改请求和响应。

#### Change returned body
#### 更改返回的主体

Let's test the new capabilities:
让我们测试一下新功能：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Now we can change the response body.
现在我们可以改变响应主体。

With `403` the body will be changed to "Unauthorized Request", running the previous command, you should receive:
使用 `403` 时主体将更改为“未授权的请求”，运行前面的命令，您应该收到：

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Change returned body and status code
#### 更改返回的主体和状态代码

Running the request with the header `x-force-unauthenticated: true`:
运行带有标头“x-force-unauthenticated：true”的请求：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: true"
{{< /text >}}

This time you should receive the body "Authentication Failed" and error `401`:
这次您应该收到主体“身份验证失败”和错误“401”：

{{< text plain >}}
Authentication Failed
http_code=401
{{< /text >}}

#### Adding headers to request
#### 向请求添加标头

Running a valid request:
运行有效请求：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

You should receive the echo body with the new header `x-validated-by: my-security-checkpoint` and the header `x-force-authorized` removed:
您应该收到带有新标头“x-validated-by：my-security-checkpoint”且标头“x-force-authorized”被删除的回显主体：

{{< text plain >}}
[...]
    "X-Validated-By": [
      "my-security-checkpoint"
    ]
[...]
http_code=200
{{< /text >}}

#### Adding headers to response
#### 向响应添加标头

Running the same request but showing only the header:
运行相同的请求但仅显示标题：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

You will find the response header added during the Authz check `x-add-custom-response-header: added`:
你会发现在 Authz 检查期间添加的响应标头 `x-add-custom-response-header:added`：

{{< text plain >}}
HTTP/1.1 200 OK
[...]
x-add-custom-response-header: added
[...]
http_code=200
{{< /text >}}

### Sharing data between filters
### 过滤器之间共享数据

Finally, you can pass data to the following Envoy filters using `dynamic_metadata`.
最后，您可以使用“dynamic_metadata”将数据传递给以下 Envoy 过滤器。

This is useful when you want to pass data to another `ext_authz` filter in the chain or you want to print it in the application logs.
当您想要将数据传递给链中的另一个“ext_authz”过滤器或想要将其打印在应用程序日志中时，这很有用。

{{< image link="./dynamic-metadata.svg" alt="元数据" >}}

To do so, review the access log format you set earlier:
为此，请检查您之前设置的访问日志格式：

{{< text plain >}}
[...]
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` is a reserved keyword to access the metadata object. The rest is the name of the filter that you want to access.
`DYNAMIC_METADATA` 是访问元数据对象的保留关键字。其余部分是要访问的过滤器的名称。

In our case, the name `envoy.filters.http.ext_authz` is created automatically by Istio. You can verify this by dumping the Envoy configuration:
在我们的例子中，名称“envoy.filters.http.ext_authz”由 Istio 自动创建。您可以通过转储 Envoy 配置来验证这一点：

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

You will see the configurations for the filter.
您将看到过滤器的配置。

Let's test the dynamic metadata. In the advance rule, we are creating a new metadata entry: `{"my-new-metadata": "my-new-value"}`.
让我们测试一下动态元数据。在高级规则中，我们正在创建一个新的元数据条目：“{"my-new-metadata": "my-new-value"}”。

Run the request and check the logs of the application:
运行请求并检查应用程序的日志：

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

{{< text bash >}}
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

You will see in the output the new attributes configured by the Kyverno policy:
您将在输出中看到 Kyverno 策略配置的新属性：

{{< text plain >}}
[...]
[KYVERNO DEMO] my-new-dynamic-metadata: '{"my-new-metadata":"my-new-value","ext_authz_duration":5}'
[...]
{{< /text >}}

## Conclusion
## 结论

In this guide, we have shown how to integrate Istio and the Kyverno Authz Server to enforce policies for a simple microservices application. We also showed how to use policies to modify the request and response attributes.
在本指南中，我们展示了如何集成 Istio 和 Kyverno Authz Server 来为简单的微服务应用程序实施策略。我们还展示了如何使用策略来修改请求和响应属性。

This is the foundational example for building a platform-wide policy system that can be used by all application teams.
这是构建可供所有应用程序团队使用的平台范围策略系统的基础示例。
