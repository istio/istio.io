---
title: 复制 JWT 声明到 HTTP 头
description: 展示用户如何能将 JWT 声明复制到 HTTP 头。
weight: 30
keywords: [security,authentication,JWT,claim]
aliases:
    - /zh/docs/tasks/security/istio-auth.html
    - /zh/docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

本任务向您展示通过 Istio 请求身份验证策略成功完成 JWT 身份验证之后如何将
JWT 声明复制到 HTTP 头。

{{< warning >}}
仅支持 string、boolean 和 integer 类型的声明。此时不支持 array 类型的声明。
{{< /warning >}}

## 开始之前 {#before-you-begin}

开始此任务之前，请做好以下准备：

* 熟悉 [Istio 终端用户身份验证](/zh/docs/tasks/security/authentication/authn-policy/#end-user-authentication)支持。

* 使用 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 在已启用 Sidecar 注入的命名空间 `foo` 中部署 `httpbin` 和 `sleep`
  工作负载。使用以下命令部署命名空间和工作负载示例：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n foo
    {{< /text >}}

* 使用以下命令验证 `sleep` 是否成功与 `httpbin` 通信：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< warning >}}
    如果您未看到预期的输出，几秒后重试。缓冲和传播可能会造成延迟。
    {{< /warning >}}

## 允许具有有效 JWT 和列表类型声明的请求 {#allow-requests-with-valid-jwt-and-list-type-claims}

1. 以下命令为 `foo` 命名空间中的 `httpbin` 工作负载创建 `jwt-example` 请求身份验证策略。
   此策略接受 `testing@secure.istio.io` 签发的 JWT，并将声明 `foo` 的值复制到一个 HTTP 头
   `X-Jwt-Claim-Foo`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1beta1
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
        outputClaimToHeaders:
        - header: "x-jwt-claim-foo"
          claim: "foo"
    EOF
    {{< /text >}}

1. 确认带有无效 JWT 的请求被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
    401
    {{< /text >}}

1. 获取 `testing@secure.istio.io` 签发的且有一个声明的键是 `foo` 的 JWT。

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. 确认允许带有有效 JWT 的请求：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. 确认请求包含有效的 HTTP 头且这个头具有 JWT 声明值：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | grep "X-Jwt-Claim-Foo" | sed -e 's/^[ \t]*//'
    "X-Jwt-Claim-Foo": "bar"
    {{< /text >}}

## 清理 {#clean-up}

1. 移除命名空间 `foo`：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}
