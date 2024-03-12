---
title: 认证策略
description: 向您展示如何通过使用 Istio 认证策略来设置双向 TLS 和基本的终端用户认证。
weight: 10
keywords: [security,authentication]
aliases:
    - /zh/docs/tasks/security/istio-auth.html
    - /zh/docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
---

本任务涵盖了您在启用、配置和使用 Istio 认证策略时可能需要做的主要工作。
更多基本概念介绍请查看[认证总览](/zh/docs/concepts/security/#authentication)。

## 开始之前 {#before-you-begin}

* 理解 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies)和[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)相关概念。
* 参照[安装步骤](/zh/docs/setup/getting-started)，使用 `default`
  配置模板在 Kubernetes 集群中安装 Istio。

{{< text bash >}}
$ istioctl install --set profile=default
{{< /text >}}

### 设置 {#setup}

本例中我们将在 `foo` 和 `bar` 命名空间下各自创建带有 Envoy 代理（Sidecar）的
`httpbin` 和 `sleep` 服务。我还将在 `legacy` 命名空间下创建不带
Envoy 代理（Sidecar）的 `httpbin` 和 `sleep` 服务。如果您希望使用相同的示例来完成这些任务，
请执行如下命令：

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n bar
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/sleep/sleep.yaml@ -n legacy
{{< /text >}}

现在您可以在 `foo`、`bar` 或 `legacy` 三个命名空间下的任意 `sleep` Pod
中使用 `curl` 向 `httpbin.foo`、`httpbin.bar` 或 `httpbin.legacy`
发送 HTTP 请求来验证部署结果。所有请求都应该成功并返回 HTTP 200。

例如，检查 `sleep.bar` 到 `httpbin.foo` 可达性的指令如下：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n bar -o jsonpath={.items..metadata.name})" -c sleep -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

您也可以使用一行指令检查所有可能的组合：

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl -s "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 200
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

使用以下指令确认系统中没有对等认证策略：

{{< text bash >}}
$ kubectl get peerauthentication --all-namespaces
No resources found
{{< /text >}}

最后同样重要的是，确认示例服务没有应用目标规则（destination rule）。
您可以检查现有目标规则中的 `host:` 值并确保它们不匹配。例如：

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
{{< /text >}}

{{< tip >}}
您可能会看到目标规则配置了除上面显示以外的其他 host，这依赖于 Istio 的版本。
然而，在 `foo`、`bar` 和 `legacy` 命名空间中不应有任何 host 相关的目标规则，
也不应配置匹配所有的通配符 `*`。
{{< /tip >}}

## 自动双向 TLS {#auto-mutual-TLS}

默认情况下，Istio 会跟踪迁移到 Istio 代理的服务器工作负载，并配置客户端代理将双向
TLS 流量自动发送到这些工作负载，并将明文流量发送到没有 Sidecar 的工作负载。

因此，具有代理的工作负载之间的所有流量即可启用双向 TLS，您无需做额外操作。
例如，您无需检查请求 `httpbin/header` 的响应。
当使用双向 TLS 时，代理会将 `X-Forwarded-Client-Cert` 标头注入到后端的上游请求。
这个标头的存在就是启用双向 TLS 的证据。例如：

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl -s http://httpbin.foo:8000/headers -s | grep X-Forwarded-Client-Cert | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
    "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"
{{< /text >}}

当服务器没有 Sidecar 时，`X-Forwarded-Client-Cert` 标头将不会存在，
这意味着请求是明文的。

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert
{{< /text >}}

## 全局以 STRICT 模式启用 Istio 双向 TLS {#globally-enabling-Istio-mutual-TLS-in-STRICT-mode}

当 Istio 自动将代理和工作负载之间的所有流量升级到双向 TLS 时，
工作负载仍然可以接收明文流量。为了阻止整个网格的服务以非双向 TLS 通信，
您需要将整个网格的对等认证策略设置为 `STRICT` 模式。
作用域为整个网格范围的对等认证策略不应设置 `selector`，
这种认证策略必须应用于**根命名空间**，例如：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< tip >}}
该示例假定命名空间 `istio-system` 是根命名空间。如果在安装过程中使用了不同的值，
请将 `istio-system` 替换为所使用的值。
{{< /tip >}}

这个对等认证策略将工作负载配置为仅接受使用 TLS 加密的请求。
由于未对 `selector` 字段指定值，因此该策略适用于网格中的所有工作负载。

再次运行测试指令：

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

您会发现除了从没有 Sidecar 的服务（`sleep.legacy`）到有 Sidecar
的服务（`httpbin.foo` 或 `httpbin.bar`）的请求外，其他请求依然是成功的。
这是符合预期的结果，因为现在严格要求使用双向 TLS，但没有 Sidecar 的工作负载无法满足这一要求。

### 清理第 1 部分 {#cleanup-part-1}

删除在会话中添加的全局认证策略：

{{< text bash >}}
$ kubectl delete peerauthentication -n istio-system default
{{< /text >}}

## 为每个命名空间或者工作负载启用双向 TLS {#enable-mutual-TLS-per-namespace-or-workload}

### 命名空间级别策略 {#namespace-wide-policy}

如果要为特定命名空间内的所有工作负载更改双向 TLS，请使用命名空间级别策略。
该策略的规范与整个网格级别的规范相同，但是您可以在 `metadata` 字段指定命名空间的名称。
例如，以下对等认证策略在 `foo` 命名空间上启用了严格的双向 TLS：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

由于这些策略只应用于命名空间 `foo` 中的服务，您会看到只有从没有 Sidecar
的客户端（`sleep.legacy`）到有 Sidecar 的客户端（`httpbin.foo`）的请求会失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### 为每个工作负载启用双向 TLS {#enable-mutual-TLS-per-workload}

要为特定工作负载设置对等认证策略，您必须配置 `selector`
字段并指定与所需工作负载匹配的标签。例如，以下对等认证策略和目标规则将为
`httpbin.bar` 服务启用严格的双向 TLS：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
{{< /text >}}

再次执行测试命令。跟预期一样，从 `sleep.legacy` 到 `httpbin.bar`
的请求因为同样的原因失败。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

{{< text plain >}}
...
sleep.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

要优化每个端口的双向 TLS 设置，您必须配置 `portLevelMtls` 字段。
例如，以下对等认证策略要求在除 `8080` 端口以外的所有端口上都使用双向 TLS：

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    8080:
      mode: DISABLE
EOF
{{< /text >}}

1. 对等认证策略中的端口值为容器的端口。目标规则的值是服务的端口。
1. 如果端口绑定到服务则只能使用 `portLevelMtls` 配置，其他配置将被 Istio 忽略。

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name})" -c sleep -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done
sleep.foo to httpbin.foo: 200
sleep.foo to httpbin.bar: 200
sleep.foo to httpbin.legacy: 200
sleep.bar to httpbin.foo: 200
sleep.bar to httpbin.bar: 200
sleep.bar to httpbin.legacy: 200
sleep.legacy to httpbin.foo: 000
command terminated with exit code 56
sleep.legacy to httpbin.bar: 200
sleep.legacy to httpbin.legacy: 200
{{< /text >}}

### 策略优先级 {#policy-precedence}

为了演示特定服务策略比命名空间范围的策略优先级高，您可以像下面一样为
`httpbin.foo` 添加一个禁用双向 TLS 的策略。
注意您已经为所有在命名空间 `foo` 中的服务创建了命名空间范围的策略来启用双向
TLS，发现从 `sleep.legacy` 到 `httpbin.foo` 的请求都会失败（如上所示）。

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: "overwrite-example"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: DISABLE
EOF
{{< /text >}}

重新执行来自 `sleep.legacy` 的请求，您应该又会看到请求成功并返回 200 代码，
证明了特定服务策略覆盖了命名空间范围的策略。

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=sleep -n legacy -o jsonpath={.items..metadata.name})" -c sleep -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清理第 2 部分 {#cleanup-part-2}

删除之前步骤中创建的策略：

{{< text bash >}}
$ kubectl delete peerauthentication default overwrite-example -n foo
$ kubectl delete peerauthentication httpbin -n bar
{{< /text >}}

## 终端用户认证 {#end-user-authentication}

为了体验这个特性，您需要一个有效的 JWT。该 JWT 必须和您用于该示例的 JWKS 终端对应。
在这个教程中，我们使用来自 Istio 代码基础库的
[JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) 和
[JWKS endpoint]({{< github_file >}}/security/tools/jwt/samples/jwks.json)。

同时为了方便访问，通过 Ingress 网关暴露 `httpbin.foo`
（详细细节请查看 [Ingress 任务](/zh/docs/tasks/traffic-management/ingress/)）。

{{< boilerplate gateway-api-support >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

配置网关：

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

按照[确定 Ingress IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)中的说明，
设置 `INGRESS_PORT` 和 `INGRESS_HOST` 环境变量。

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

创建网关：

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

设置 `INGRESS_PORT` 和 `INGRESS_HOST` 环境变量：

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

通过网关运行测试查询：

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

现在添加一个认证策略，该策略要求 Ingress 网关指定终端用户的 JWT。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

在所选的工作负载的命名空间中应用该策略，本例中是 Ingress 网关。

如果您在授权标头中提供了一个令牌，并且其位置是隐式默认的，Istio
将使用[公钥集]({{< github_file >}}/security/tools/jwt/samples/jwks.json)验证令牌，
并拒绝无效的令牌请求。但是，没有令牌的请求会被接受。
为了观察这种行为，请尝试重新发出没有令牌、有错误令牌以及含有效令牌的请求。

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ curl --header "Authorization: Bearer deadbeef" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

为了观察 JWT 验证的其它方面，使用脚本
[`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py)
生成新 token 带上不同的发行人、受众、有效期等等进行测试。可以从 Istio 库下载此脚本：

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
{{< /text >}}

您还需要 `key.pem` 文件：

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
如果您的系统尚未安装 `jwcrypto` 库，您需要从
[jwcrypto](https://pypi.org/project/jwcrypto) 下载并安装。
{{< /tip >}}

JWT 认证有 60 秒的时钟偏移（clock skew），这意味着 JWT
令牌会比其配置 `nbf` 早 60 秒成为有效的，其配置 `exp` 后 60 秒后仍然有效。

例如，下面的命令创建一个令牌，该令牌在 5 秒钟后过期。如您所见，
Istio 会一直通过认证直到 65 秒后才拒绝这些令牌：

{{< text bash >}}
$ TOKEN=$(python3 ./gen-jwt.py ./key.pem --expire 5)
$ for i in $(seq 1 10); do curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"; sleep 10; done
200
200
200
200
200
200
200
401
401
401
{{< /text >}}

您也可以给一个 `ingress gateway` 添加一个 JWT 策略（例如，服务
`istio-ingressgateway.istio-system.svc.cluster.local`）。
这个常用于为绑定到这个 gateway 的所有服务定义一个 JWT 策略而不是为单独的服务绑定策略。

### 提供有效令牌 {#require-a-valid-token}

拒绝没有有效的令牌的请求，需要增加名为 `DENY` 认证策略，
可参考以下例子中的 `notRequestPrincipals:["*"]` 配置。
仅当提供有效的JWT令牌时请求主体才可用，因此该规则将拒绝没有有效令牌的请求。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
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
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

重新发送没有令牌的请求。请求失败并返回错误码 `403`：

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

### 按路径提供有效令牌 {#require-valid-tokens-per-path}

为了按路径（路径指 host、path 或者 method）提供有效令牌，我们需要在其授权策略中指定这些路径，
如下列配置中的 `/headers` 只需要 JWT。待授权规则生效后，对 `$INGRESS_HOST:$INGRESS_PORT/headers`
的请求将失败，错误代码为 `403`。而到其他所有路径的请求（例如 `$INGRESS_HOST:$INGRESS_PORT/ip`）都会成功。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
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
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/ip" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### 清理第 3 部分 {#cleanup-part-3}

1. 删除认证策略：

    {{< text bash >}}
    $ kubectl -n istio-system delete requestauthentication jwt-example
    {{< /text >}}

1. 删除授权策略：

    {{< text bash >}}
    $ kubectl -n istio-system delete authorizationpolicy frontend-ingress
    {{< /text >}}

1. 删除生成令牌的脚本和密钥文件：

    {{< text bash >}}
    $ rm -f ./gen-jwt.py ./key.pem
    {{< /text >}}

1. 如果您不打算继续后续章节的任务，只需删除这些测试命名空间，就可以移除所有资源：

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}
