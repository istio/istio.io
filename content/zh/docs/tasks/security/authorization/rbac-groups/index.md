---
title: 基于组和列表声明的授权
description: 有关如何在 Istio 中配置基于组的授权和列表类型声明的授权的教程。
weight: 10
keywords: [security,authorization]
aliases:
    - /zh/docs/tasks/security/rbac-groups/
---

本教程将向您介绍在 Istio 中配置基于组的授权和列表类型声明的授权的示例。

## 开始之前{#before-you-begin}

* 阅读[授权](/zh/docs/concepts/security/#authorization)概念并阅读有关如何[配置 Istio 授权](/zh/docs/concepts/security/#authorization)的指南。

* 阅读 Istio [认证策略](/zh/docs/concepts/security/#authentication-policies)和相关的[双向 TLS 认证](/zh/docs/concepts/security/#mutual-TLS-authentication)概念。

* 创建一个安装了 Istio 并启用了双向 TLS 的 Kubernetes 集群。要满足此先决条件，您可以按照 Kubernetes [安装说明](/zh/docs/setup/install/istioctl/)进行操作。

## 设置所需的命名空间和服务{#setup-the-required-namespace-and-services}

本教程在一个名为 `rbac-groups-test-ns` 的新命名空间中运行，该命名空间有两个服务，`httpbin` 和 `sleep`，两者都各自附带一个 Envoy sidecar 代理。使用以下命令来设置环境变量以存储命名空间的名称，创建命名空间，并启动这两个服务。
在运行以下命令之前，您需要输入包含 Istio 安装文件的目录。

1. 将 `NS` 环境变量的值设置为 `rbac-listclaim-test-ns`：

    {{< text bash >}}
    $ export NS=authz-groups-test-ns
    {{< /text >}}

1. 确保 `NS` 环境变量指向一个完全用于测试的命名空间。运行以下命令删除 `NS` 环境变量指向的命名空间中的所有资源。

    {{< text bash >}}
    $ kubectl delete namespace $NS
    {{< /text >}}

1. 为本教程创建命名空间：

    {{< text bash >}}
    $ kubectl create ns $NS
    {{< /text >}}

1. 创建 `httpbin` 和 `sleep` 服务和部署：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
    {{< /text >}}

1. 要验证 `httpbin` 和 `sleep` 服务是否正在运行并且 `sleep` 能够访问 `httpbin`，请运行以下 curl 命令：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    当命令成功时，它返回 HTTP 状态码为 200。

## 使用双向 TLS 配置 JSON Web 令牌（JWT）认证{#configure-json-web-token-JWT-authentication-with-mutual-TLS}

您接下来应用的认证策略会强制要求访问 `httpbin` 服务需要具备有效的 JWT。
策略中定义的 JSON Web 密钥集（JWKS ）端点必须对 JWT 进行签名。
本教程使用 Istio 代码库中的 [JWKS 端点]({{<github_file>}}/security/tools/jwt/samples/jwks.json)并使用[此示例 JWT]({{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt)。
示例 JWT 包含一个标识为 `groups` 的声明键和一个 [`"group1"`，`"group2"`] 字符串列表的声明值。
JWT 声明值可以是字符串或字符串列表；两种类型都支持。

1. 应用认证策略同时需要双向 TLS 和 `httpbin` 服务的 JWT 认证。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "require-mtls-jwt"
    spec:
      targets:
      - name: httpbin
      peers:
      - mtls: {}
      origins:
      - jwt:
          issuer: "testing@secure.istio.io"
          jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
      principalBinding: USE_ORIGIN
    EOF
    {{< /text >}}

1. 在 `sleep` 中应用 `DestinationRule` 策略以使用双向 TLS 与 `httpbin` 通信。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: use-mtls-on-sleep
    spec:
      host: httpbin.$NS.svc.cluster.local
      trafficPolicy:
        tls:
          mode: ISTIO_MUTUAL
    EOF
    {{< /text >}}

1. 设置 `TOKEN` 环境变量以包含有效的示例 JWT。

    {{< text bash >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s)
    {{< /text >}}

1. 连接到 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    当附加的 JWT 有效时，它返回 HTTP 状态码为 200。

1. 当没有附加 JWT 时，验证与 `httpbin` 服务的连接是否失败：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    当没有附加有效的 JWT 时，它返回 HTTP 状态码为 401。

## 配置基于组的授权{#configure-groups-based-authorization}

本节创建一个策略授权来自特定组的请求访问 `httpbin` 服务。
由于缓存和其他传播开销可能会有一些延迟，因此请等待新定义的 RBAC 策略生效。

1. 为命名空间启用 Istio RBAC：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: deny-all
    spec:
      {}
    EOF
    {{< /text >}}

1. 一旦 RBAC 策略生效，验证 Istio 是否拒绝了与 `httpbin` 服务的 curl 连接：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    一旦 RBAC 策略生效，该命令返回 HTTP 状态码为 403。

1. 要提供对 `httpbin` 服务的读访问权，请创建 `httpbin-viewer` 服务角色：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "httpbin-viewer"
    spec:
      selector:
        matchLabels:
          app: httpbin
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.auth.claims[groups]
          values: ["group1"]
    EOF
    {{< /text >}}

1. 要将 `httpbin-viewer` 角色分配给 `group1` 中的用户，请创建 `bind-httpbin-viewer` 服务角色绑定。

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      subjects:
      - properties:
          request.auth.claims[groups]: "group1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    或者，您可以在 `subject` 下指定 `group` 属性。指定组的两种方式都是等效的。目前，Istio 仅支持与在 JWT 中的 `request.auth.claims` 属性和 `subject` 下的 `group` 属性进行字符串列表匹配。

    指定 `subject` 下的 `group` 属性，请使用以下命令：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRoleBinding
    metadata:
      name: bind-httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      subjects:
      - group: "group1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    等待新定义的 RBAC 策略生效。

1. RBAC 策略生效后，验证与 `httpbin` 服务的连接是否成功：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    HTTP Header 包含一个有效的 JWT，其 `groups` 声明值为 [`"group1"`，`"group2"`]，因为它包含 `group1`，所以返回 HTTP 状态码为 200。

## 配置列表类型声明的授权{#configure-the-authorization-of-list-typed-claims}

Istio RBAC 支持配置列表类型声明的授权。
示例中的 JWT 包含一个带有标识为 `scope` 的声明键和一个 [`"scope1"`，`"scope2"`] 字符串列表作为其声明值。
您可以使用 `gen-jwt` [python 脚本]({{<github_file>}}/security/tools/jwt/samples/gen-jwt.py)生成带有其他列表类型声明的 JWT 进行测试。
按照 `gen-jwt` 脚本中的说明使用 `gen-jwt.py` 文件。

1. 要将 `httpbin-viewer` 角色分配给一个附加 JWT 其中包含值为 `scope1` 的列表类型 `scope` 声明的请求，请创建名为 `bind-httpbin-viewer` 的服务角色进行绑定：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "security.istio.io/v1beta1"
    kind: "AuthorizationPolicy"
    metadata:
      name: "httpbin-viewer"
    spec:
      selector:
        matchLabels:
          app: httpbin
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.auth.claims[scope]
          values: ["scope1"]
    EOF
    {{< /text >}}

    等待新定义的 RBAC 策略生效。

1. RBAC 策略生效后，验证与 `httpbin` 服务的连接是否成功：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    HTTP Header 包含一个有效的 JWT，`scope` 的声明值为 [`"scope1"`，`"scope2"`]，因为它包含 `scope1`，所以返回 HTTP 状态码为 200。

## 清理{#cleanup}

完成本教程后，运行以下命令删除在命名空间中创建的所有资源。

{{< text bash >}}
$ kubectl delete namespace $NS
{{< /text >}}
