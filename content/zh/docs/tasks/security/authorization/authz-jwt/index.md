---
title: JWT 令牌
description: 演示如何为 JWT 令牌设置访问控制。
weight: 30
keywords: [security,authorization,jwt,claim]
aliases:
    - /zh/docs/tasks/security/rbac-groups/
    - /zh/docs/tasks/security/authorization/rbac-groups/
owner: istio/wg-security-maintainers
test: yes
---

本教程向您展示如何通过设置 Istio 授权策略来实现基于 JSON Web Token（JWT）的强制访问控制。
Istio 授权策略同时支持字符串类型和列表类型的 JWT 声明。

## 开始之前 {#before-you-begin}

在开始这个任务之前，请先完成以下操作：

* 完成 [Istio 最终用户身份验证任务](/zh/docs/tasks/security/authentication/authn-policy/#end-user-authentication)。

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 参照 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 部署两个工作负载（workload）：`httpbin` 和 `sleep`。将它们部署在同一个命名空间中，
* 例如 `foo`。每个工作负载都在前面运行一个 Envoy 代理。您可以使用以下命令来部署它们：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* 使用下面的命令验证 `sleep` 能够正常访问 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您没有看到预期的输出，过几秒再试。缓存和策略传播可能造成延迟。
{{< /warning >}}

## 允许包含有效 JWT 和 列表类型声明的请求 {#allow-requests-with-jwt-and-claims}

1. 以下命令为 `foo` 命名空间下的 `httpbin` 工作负载创建一个名为 `jwt-example`
   的身份验证策略。这个策略使得 `httpbin` 工作负载接收 Issuer 为 `testing@secure.istio.io`
   的 JWT 令牌：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: "jwt-example"
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    EOF
    {{< /text >}}

1. 验证使用无效 JWT 的请求被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
    401
    {{< /text >}}

1. 验证没有 JWT 令牌的请求被允许，因为以上策略不包含授权策略：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. 以下命令为 `foo` 命名空间下的 `httpbin` 工作负载创建一个名为 `require-jwt`
   的授权策略。这个策略要求所有发往 `httpbin` 服务的请求都要包含一个将 `requestPrincipal`
   设置为 `testing@secure.istio.io/testing@secure.istio.io` 的有效 JWT。Istio 使用
   `/` 连接 JWT 令牌的 `iss` 和 `sub` 以组成 `requestPrincipal` 字段。

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
    EOF
    {{< /text >}}

1. 获取 `iss` 和 `sub` 都为 `testing@secure.istio.io` 的 JWT。这会让 Istio 生成的
   `requestPrincipal` 属性值为 `testing@secure.istio.io/testing@secure.istio.io`：

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. 验证使用有效 JWT 的请求被允许：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. 验证没有 JWT 的请求被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. 以下命令更新 `require-jwt` 授权策略，使其同时要求 JWT 包含一个名为 `groups` 值为 `group1` 的声明：

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
        when:
        - key: request.auth.claims[groups]
          values: ["group1"]
    EOF
    {{< /text >}}

    {{< warning >}}
    除非声明本身包含引号，否则请勿在 `request.auth.claims` 字段包含引号。
    {{< /warning >}}

1. 获取 `groups` 声明列表为 `group1` 和 `group2` 的 JWT：

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode -
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

1. 验证包含 JWT 且 JWT 中包含名为 `groups` 值为 `group1` 声明的请求被允许：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN_GROUP" -w "%{http_code}\n"
    200
    {{< /text >}}

1. 验证包含 JWT，但 JWT 不包含 `groups` 声明的请求被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    403
    {{< /text >}}

## 清理 {#cleanup}

删除 `foo` 命名空间：

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
