---
title: "您的平台可以制定策略吗？利用平台 L7 策略功能为团队加速"
description: 策略是您的核心竞争力吗？可能不是，但您需要正确对其进行配置。使用 Istio 和 OPA 进行一次性配置，即可让团队重新专注于最重要的事情。
publishdate: 2024-10-14
attribution: "Antonio Berben (Solo.io), Charlie Egan (Styra); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,opa,policy,platform,authorization]
---

共享计算平台为租户团队提供资源和共享功能，这样他们就无需自己从头开始构建一切。
虽然有时很难平衡租户的所有需求，但平台团队必须问自己一个问题：
我们可以为租户提供的价值最高的功能是什么？

通常，工作直接交给应用程序团队去实施，但有些功能最好只被实施一次，
然后作为服务提供给所有团队。大多数平台团队都可以实现的一项功能是为七层应用程序鉴权策略提供标准、
响应迅速的系统。策略即代码使团队能够将鉴权决策从应用程序层提升到一个轻量级且性能良好的解耦系统中。
这听起来可能是一个挑战，但只要有合适的工具，就不一定是挑战。

我们将深入研究如何使用 Istio 和开放策略代理：Open Policy Agent（OPA）在您的平台中实施七层策略。
我们将通过一个简单的示例向您展示如何开始。您将看到这种组合如何成为一种可靠的选择，
可以快速透明地向企业中任何地方的应用程序团队提供策略，同时还为安全团队提供进行审计和合规所需的数据。

## 尝试一下 {#try-it-out}

与 Istio 集成后，OPA 可用于为微服务实施细粒度的访问控制策略。
本指南介绍如何为简单的微服务应用程序实施访问控制策略。

### 先决条件 {#prerequisites}

- 安装了 Istio 的 Kubernetes 集群。
- 安装了 `istioctl` 命令行工具。

安装 Istio 并配置你的[网格选项](/zh/docs/reference/config/istio.mesh.v1alpha1/)以启用 OPA：

{{< text bash >}}
$ istioctl install -y -f - <<'EOF'
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "opa.opa.svc.cluster.local"
        port: "9191"
EOF
{{< /text >}}

请注意，在配置中，我们定义了一个指向 OPA 独立安装的 `extensionProviders` 部分。

部署示例应用程序。httpbin 是一个著名的应用程序，
可用于测试 HTTP 请求，并有助于快速展示如何使用请求和响应属性。

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled

$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

部署 OPA。因为它需要一个包含要使用的默认 Rego 规则的 `configMap`，
所以部署将会失败。此 `configMap` 将稍后在我们的示例中部署。

{{< text bash >}}
$ kubectl create ns opa
$ kubectl label namespace opa istio-injection=enabled

$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: opa
  name: opa
  namespace: opa
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
      - image: openpolicyagent/opa:0.61.0-envoy
        name: opa
        args:
          - "run"
          - "--server"
          - "--disable-telemetry"
          - "--config-file=/config/config.yaml"
          - "--log-level=debug" # 取消注释此行以启用调试日志
          - "--diagnostic-addr=0.0.0.0:8282"
          - "/policy/policy.rego" # Default policy
        volumeMounts:
          - mountPath: "/config"
            name: opa-config
          - mountPath: "/policy"
            name: opa-policy
      volumes:
        - name: opa-config
          configMap:
            name: opa-config
        - name: opa-policy
          configMap:
            name: opa-policy
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-config
  namespace: opa
data:
  config.yaml: |
    # 您可以在官方文档中找到 OPA 配置
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191"
        path: mypackage/mysubpackage/myrule # gRPC 插件的默认路径
    # 您可以在此处添加自己的服务和捆绑配置
---
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: opa
  labels:
    app: opa
spec:
  ports:
    - port: 9191
      protocol: TCP
      name: grpc
  selector:
    app: opa
---
EOF
{{< /text >}}

部署 `AuthorizationPolicy` 来定义哪些服务将受到 OPA 的保护。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-opa-authz
  namespace: istio-system # 这将在所有属于 istio-system 的网格配置命名空间中强制执行该策略
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: "opa.local"
  rules: [{}] # 空规则，它将应用于带有 ext-authz: enabled 标签的选择器
EOF
{{< /text >}}

让我们标记应用程序来执行该策略：

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

请注意，在此资源中，我们定义了您在 Istio 配置中设置的 OPA `extensionProvider`：

{{< text yaml >}}
[...]
  provider:
    name: "opa.local"
[...]
{{< /text >}}

## 工作原理 {#how-it-works}

当应用 `AuthorizationPolicy` 时，Istio 控制平面（istiod）将所需的配置发送给策略中选定服务的 Sidecar 代理（Envoy）。
然后，Envoy 会将请求发送到 OPA 服务器以检查该请求是否被允许。

{{< image width="75%"
    link="./opa1.png"
    alt="Istio 和 OPA"
    >}}

Envoy 代理通过配置链中的过滤器来工作。其中一个过滤器是 `ext_authz`，
它使用特定消息实现外部授权服务。任何实现正确 protobuf 的服务器都可以连接到
Envoy 代理并提供鉴权决策；OPA 就是其中之一。

{{< image width="75%"
    link="./opa2.png"
    alt="过滤器"
    >}}

以前，当你安装 OPA 服务器时，你使用的是 Envoy 版本的服务器。
此镜像允许配置实现 `ext_authz` protobuf 服务的 gRPC 插件。

{{< text yaml >}}
[...]
      containers:
      - image: openpolicyagent/opa:0.61.0-envoy # 这是带有 Envoy 插件的 OPA 镜像版本
        name: opa
[...]
{{< /text >}}

在配置中，您已启用 Envoy 插件并将监听端口：

{{< text yaml >}}
[...]
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191" # 这是 Envoy 插件将监听的端口
        path: mypackage/mysubpackage/myrule # gRPC 插件的默认路径
    # 您可以在此处添加自己的服务和捆绑配置
[...]
{{< /text >}}

查看 [Envoy 的鉴权服务文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto)，
可以看到该消息具有以下属性：

{{< text json >}}
OkHttpResponse
{
  "status": {...},
  "denied_response": {...},
  "ok_response": {
      "headers": [],
      "headers_to_remove": [],
      "dynamic_metadata": {...},
      "response_headers_to_add": [],
      "query_parameters_to_set": [],
      "query_parameters_to_remove": []
    },
  "dynamic_metadata": {...}
}
{{< /text >}}

这意味着，根据来自 authz 服务器的响应，Envoy 可以添加或删除标头、查询参数，甚至更改响应状态。
OPA 也可以做到这一点，如 [OPA 文档](https://www.openpolicyagent.org/docs/latest/envoy-primer/#example-policy-with-additional-controls)中所述。

## 测试 {#testing}

让我们测试简单的用法（鉴权），然后创建一个更高级的规则来展示如何使用 OPA 来修改请求和响应。

部署一个应用程序来对 httpbin 示例应用程序运行 curl 命令：

{{< text bash >}}
$ kubectl -n my-app run --image=curlimages/curl curl -- /bin/sleep 100d
{{< /text >}}

应用第一个 Rego 规则并重新启动 OPA Deployment：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    default myrule := false

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "enabled"
    }

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "true"
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

简单的场景是，如果请求包含标头 `x-force-authorized`，且值为 `enabled` 或 `true`，
则允许请求。如果标头不存在或具有不同的值，则请求将被拒绝。

有多种方法可以创建 Rego 规则。在本例中，我们创建了两个不同的规则。
按顺序执行，第一个满足所有条件的规则将被使用。

### 简单规则 {#simple-rule}

以下请求将返回 `403`：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

以下请求将返回 `200` 和响应体：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: enabled"
{{< /text >}}

### 高级操作 {#advanced-manipulations}

现在是更高级的规则。应用第二条 Rego 规则并重新启动 OPA 部署：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    request_headers := input.attributes.request.http.headers

    force_unauthenticated if request_headers["x-force-unauthenticated"] == "enabled"

    default allow := false

    allow if {
      not force_unauthenticated
      request_headers["x-force-authorized"] == "true"
    }

    default status_code := 403

    status_code := 200 if allow

    status_code := 401 if force_unauthenticated

    default body := "Unauthorized Request"

    body := "Authentication Failed" if force_unauthenticated

    myrule := {
      "body": body,
      "http_status": status_code,
      "allowed": allow,
      "headers": {"x-validated-by": "my-security-checkpoint"},
      "response_headers_to_add": {"x-add-custom-response-header": "added"},
      "request_headers_to_remove": ["x-force-authorized"],
      "dynamic_metadata": {"my-new-metadata": "my-new-value"},
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

在该规则中，您可以看到：

{{< text plain >}}
myrule["allowed"] := allow # 请注意，返回对象时 `allowed` 是强制性的，例如这里的 `myrule`
myrule["headers"] := headers
myrule["response_headers_to_add"] := response_headers_to_add
myrule["request_headers_to_remove"] := request_headers_to_remove
myrule["body"] := body
myrule["http_status"] := status_code
{{< /text >}}

这些是 OPA 服务器将返回给 Envoy 代理的值。Envoy 将使用这些值来修改请求和响应。

请注意，返回 JSON 对象时需要 `allowed`，而不仅仅是 true/false。
这可以在[OPA 文档](https://www.openpolicyagent.org/docs/latest/envoy-primer/#output-document)中找到。

#### 更改返回体 {#change-returned-body}

让我们测试一下新功能：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

现在我们可以更改响应体。伴随 `403`，Rego 规则中的主体将更改为 `Unauthorized Request`。
使用上一个命令，您应该收到：

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### 更改返回体和状态代码 {#change-returned-body-and-status-code}

运行带有标头 `x-force-authorized: enabled` 的请求，您应该收到主体 `Authentication Failed` 和错误 `403`：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: enabled"
{{< /text >}}

#### 向请求添加标头 {#adding-headers-to-request}

运行有效请求，您应该收到带有新标头 `x-validated-by: my-security-checkpoint` 和已删除标头 `x-force-authorized` 的回显主体：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### 向响应添加标头 {#adding-headers-to-response}

运行相同的请求但仅显示标头，您将发现在 Authz 检查期间添加的响应标头 `x-add-custom-response-header:added`：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### 在过滤器之间共享数据 {#sharing-data-between-filters}

最后，您可以使用 `dynamic_metadata` 将数据传递给以下 Envoy 过滤器。
当您想将数据传递给链中的另一个 `ext_authz` 过滤器或想要将其打印在应用程序日志中时，这很有用。

{{< image width="75%"
    link="./opa3.png"
    alt="元数据"
    >}}

为此，请检查您之前设置的访问日志格式：

{{< text plain >}}
[...]
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` 是用于访问元数据对象的保留关键字。
其余部分是您要访问的过滤器的名称。在您的例子中，
名称 `envoy.filters.http.ext_authz` 是由 Istio 自动创建的。您可以通过转储 Envoy 配置来验证这一点：

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

您将看到过滤器的配置。

让我们测试一下动态元数据。在高级规则中，
您正在创建一个新的元数据条目：`{"my-new-metadata": "my-new-value"}`。

运行请求并检查应用程序的日志：

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

您将在输出中看到由 OPA Rego 规则配置的新属性：

{{< text plain >}}
[...]
 my-new-dynamic-metadata: "{"my-new-metadata":"my-new-value","decision_id":"8a6d5359-142c-4431-96cd-d683801e889f","ext_authz_duration":7}"
[...]
{{< /text >}}

## 结论 {#conclusion}

在本指南中，我们展示了如何集成 Istio 和 OPA 来为简单的微服务应用程序实施策略。
我们还展示了如何使用 Rego 修改请求和响应属性。
这是构建可供所有应用程序团队使用的平台范围策略系统的基础示例。
