---
title: 基于 JWT 声明的路由
description: 演示如何使用基于 JWT 声明路由请求的 Istio 身份验证策略。
weight: 10
keywords: [security,authentication,jwt,route]
owner: istio/wg-security-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

本任务向您展示如何实现基于 Istio 入口网关上的 JWT 声明路由请求，
来使用请求身份认证和虚拟服务。

注意：该特性只支持 Istio 入口网关，并且需要使用请求身份验证和虚拟服务来根据
JWT 声明进行正确的验证和路由。

## 开始之前 {#before-you-begin}

* 理解 Istio [身份认证策略](/zh/docs/concepts/security/#authentication-policies)和[虚拟服务](/zh/docs/concepts/traffic-management/#virtual-services)相关概念。

* 使用 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 在 `foo` 命名空间中，部署一个 `httpbin` 工作负载，
  并通过 Istio 入口网关使用以下命令暴露它：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
    {{< /text >}}

*  按照
   [确定入口的 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports)
   使用说明来定义 `INGRESS_HOST` 和 `INGRESS_PORT` 环境变量。

* 使用下面的命令验证 `httpbin` 工作负载和入口网关是否按照预期正常工作：

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您没有看到预期的输出，请在几秒钟后重试。因为缓存和传输的开销会导致延迟。
{{< /warning >}}

## 基于 JWT 声明配置入站路由 {#configuring-ingress-routing-based-on-JWT-claims}

Istio 入口网关支持基于经过身份验证的 JWT 的路由，
这对于基于最终用户身份的路由非常有用，并且比使用未经身份验证的 HTTP
属性（例如：路径或消息头）更安全。

1. 为了基于 JWT 声明进行路由，首先创建请求身份验证以启用 JWT 验证：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: ingress-jwt
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

    这个请求身份验证将在 Istio 网关上启用 JWT 校验，以便验证过的
    JWT 声明稍后可以在虚拟服务中用于路由功能。

    这个请求身份验证只应用于入口网关，因为基于路由的 JWT 声明仅在入口网关上得到支持。

    注意：请求身份验证将只检查请求中是否存在 JWT。要使 JWT 成为必要条件，
    如果请求中不包含 JWT 的时候就拒绝请求，
    请应用[任务](/zh/docs/tasks/security/authentication/authn-policy#require-a-valid-token)中指定的授权策略。

1. 根据经过验证的 JWT 声明将虚拟服务更新到路由：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
      namespace: foo
    spec:
      hosts:
      - "*"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /headers
          headers:
            "@request.auth.claims.groups":
              exact: group1
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

    虚拟服务使用保留的消息头 `"@request.auth.claims.groups"` 来匹配 JWT 声明中的 `groups`。
    前缀的 `@` 表示它与来自 JWT 验证的元数据匹配，而不是与 HTTP 消息头匹配。
    JWT 支持字符串类型的声明、字符串列表和嵌套声明。使用 `.` 作为嵌套声明名称的分隔符。
    例如，`"@request.auth.claims.name.givenName"` 匹配嵌套声明 `name` 和 `givenName`。
    当前不支持使用 `.` 字符作为声明名称。

## 基于 JWT 声明验证入口路由 {#validating-ingress-routing-based-on-JWT-claims}

1. 验证入口网关返回没有 JWT 的 HTTP 404 代码：

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

    您还可以创建授权策略，以便在缺少 JWT 时使用 HTTP 403 代码显式拒绝请求。

1. 验证入口网关返回带有无效 JWT 的 HTTP 401 代码：

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer some.invalid.token"
    HTTP/1.1 401 Unauthorized
    ...
    {{< /text >}}

    401 是由请求身份验证返回的，因为 JWT 声明验证失败。

1. 使用包含 `groups: group1` 声明的有效 JWT 令牌验证入口网关路由请求：

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_GROUP"
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

1. 验证入口网关，返回了带有有效 JWT 的 HTTP 404 代码，但不包含 `groups: group1` 声明：

    {{< text syntax="bash" >}}
    $ TOKEN_NO_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN_NO_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_NO_GROUP"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## 清除 {#cleanup}

* 移除名称为 `foo` 的命名空间：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* 移除身份认证：

    {{< text bash >}}
    $ kubectl delete requestauthentication ingress-jwt -n istio-system
    {{< /text >}}
