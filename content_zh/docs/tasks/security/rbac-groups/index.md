---
title: 基于组和列表类型声明的授权
description: 有关如何在 Istio 中配置基于组的授权和配置列表类型声明的授权的教程。
weight: 10
keywords: [security,authorization]
---

本教程将向您介绍在 Istio 中配置基于组的授权和列表类型声明的授权的示例。

## 开始之前

* 阅读[授权](/zh/docs/concepts/security/#授权)概念并阅读有关如何配置 [Istio 授权的指南](/zh/docs/tasks/security/authz-http)。

* 阅读 Istio 身份[验证策略](/zh/docs/concepts/security/#认证策略)和相关的[双向 TLS 身份验证](/zh/docs/concepts/security/#双向-tls-认证)概念。

* 创建一个安装了 Istio 并启用了双向 TLS 的 Kubernetes 集群。要满足此先决条件，您可以按照 Kubernetes [安装说明](/zh/docs/setup/kubernetes/install/kubernetes/#安装步骤)进行操作。

## 设置所需的命名空间和服务

本教程在一个名为 `rbac-groups-test-ns` 的新命名空间中运行，该命名空间有两个服务，`httpbin` 和 `sleep`，两者都运行在 Envoy sidecar 代理上。以下命令设置环境变量以存储命名空间的名称，创建命名空间，并启动这两个服务。
在运行以下命令之前，需要输入包含 Istio 安装文件的目录。

1.  将 `NS` 环境变量的值设置为 `rbac-listclaim-test-ns`：

    {{< text bash >}}
    $ export NS=rbac-groups-test-ns
    {{< /text >}}

1.  确保 `NS` 环境变量指向仅测试命名空间。运行以下命令以删除 `NS` 环境变量指向的命名空间中的所有资源。

    {{< text bash >}}
    $ kubectl delete namespace $NS
    {{< /text >}}

1.  为本教程创建名称空间：

    {{< text bash >}}
    $ kubectl create ns $NS
    {{< /text >}}

1.  创建 `httpbin` 和 `sleep` 服务和部署：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n $NS
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n $NS
    {{< /text >}}

1.  要验证 `httpbin` 和 `sleep` 服务是否正在运行并且 `sleep` 能够到达 `httpbin`，请运行以下 curl 命令：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    当命令成功时，它返回 HTTP 代码 200。

## 使用双向TLS配置JSON Web令牌（JWT）身份验证

您接下来应用的身份验证策略强制要求访问 `httpbin` 服务需要有效的 JWT。
策略中定义的 JSON Web 密钥集（ JWKS ）端点必须对 JWT 进行签名。
本教程使用 Istio 代码库中的[JWKS 端点]({{< github_file >}}/security/tools/jwt/samples/jwks.json)并使用[此示例 JWT]({{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt)。
示例 JWT 包含一个带有 `groups` 声明键和一个字符串列表的 JWT 声明，[`"group1"`，`"group2"`]作为声明值。
JWT 声明值可以是字符串或字符串列表;两种类型都受支持。

1.  应用身份验证策略以要求 `httpbin` 的双向 TLS 和 JWT 身份验证。

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

1.  部署 `DestinationRule`, 用于 `sleep` 与 `httpbin` 通信时的双向 TLS 认证。

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


1.  设置 `TOKEN` 环境变量以包含有效的示例 JWT。

    {{< text bash>}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s)
    {{< /text >}}

1.  连接到 `httpbin` 服务：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    附加有效的 JWT 时，它返回 HTTP 代码 200。

1.  在未连接 JWT 时验证与 `httpbin` 服务的连接是否失败：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n"
    {{< /text >}}

    当没有附加有效的 JWT 时，它返回 HTTP 代码 401。

## 配置基于组的授权

如果请求来自特定组，则本节创建一个策略以授权访问 `httpbin` 服务。
由于缓存和其他传播开销可能会有一些延迟，因此请等待新定义的 RBAC 策略生效。

1.  为命名空间启用 Istio RBAC：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ClusterRbacConfig
    metadata:
      name: default
    spec:
      mode: 'ON_WITH_INCLUSION'
      inclusion:
        namespaces: ["rbac-groups-test-ns"]
    EOF
    {{< /text >}}

1.  一旦 RBAC 策略生效，验证 Istio 是否拒绝了与 `httpbin` 服务的 curl 连接：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    一旦 RBAC 策略生效，该命令返回 HTTP 代码 403。

1.  要提供对 `httpbin` 服务的读访问权，请创建 `httpbin-viewer` 服务角色：

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n $NS -f -
    apiVersion: "rbac.istio.io/v1alpha1"
    kind: ServiceRole
    metadata:
      name: httpbin-viewer
      namespace: rbac-groups-test-ns
    spec:
      rules:
      - services: ["httpbin.rbac-groups-test-ns.svc.cluster.local"]
        methods: ["GET"]
    EOF
    {{< /text >}}

1.  要将 `httpbin-viewer` 角色分配给 `group1` 中的用户，请创建 `bind-httpbin-viewer` 服务角色绑定。

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

    或者，您可以在 `subject` 下指定 `group` 属性。指定组的两种方式都是等效的。目前，Istio 仅支持在 JWT 中为 `request.auth.claims` 属性和 `subject` 下的 `group` 属性进行匹配。

    要在 `subject` 下指定 `group` 属性，请使用以下命令：

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

1.  RBAC 策略生效后，验证与 `httpbin` 服务的连接是否成功：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    HTTP Header 包括一个有效的 JWT，其 `groups` 声明值为[`"group1"`，`"group2"`]，因为它包含 `group1`，所以返回 HTTP 代码 200。

## 配置列表类型声明的授权

Istio RBAC 支持配置列表类型声明的授权。
示例 JWT 包含一个带有 `scope` 声明键和一个字符串列表的 JWT 声明，[`"scope1"`，`"scope2"`]作为声明值。
您可以使用 `gen-jwt` [python 脚本]({{<github_file>}}/security/tools/jwt/samples/gen-jwt.py)生成带有其他列表类型声明的 JWT 以进行测试。
按照 `gen-jwt` 脚本中的说明使用 `gen-jwt.py` 文件。

1.  要将 `httpbin-viewer` 角色分配给具有 JWT 的请求，该请求包含值为 `scope1` 的列表类型 `scope` 声明，请创建名为 `bind-httpbin-viewer` 的服务角色绑定：

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
          request.auth.claims[scope]: "scope1"
      roleRef:
        kind: ServiceRole
        name: "httpbin-viewer"
    EOF
    {{< /text >}}

    等待新定义的 RBAC 策略生效。

1.  RBAC 策略生效后，验证与 `httpbin` 服务的连接是否成功：

    {{< text bash >}}
    $ kubectl exec $(kubectl get pod -l app=sleep -n $NS -o jsonpath={.items..metadata.name}) -c sleep -n $NS -- curl http://httpbin.$NS:8000/ip -s -o /dev/null -w "%{http_code}\n" --header "Authorization: Bearer $TOKEN"
    {{< /text >}}

    HTTP Header 包括一个有效的 JWT，`scope` 的声明值为[`"scope1"`，`"scope2"`]，因为它包含 `scope1`， 所以返回 HTTP 代码 200。

## 清理

完成本教程后，运行以下命令以删除在命名空间中创建的所有资源。

{{< text bash >}}
$ kubectl delete namespace $NS
{{< /text >}}
