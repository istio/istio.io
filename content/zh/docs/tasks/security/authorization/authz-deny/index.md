---
title: 明确拒绝
description: 如何设置访问控制以明确地拒绝流量。
weight: 40
keywords: [security,access-control,rbac,authorization,deny]
owner: istio/wg-security-maintainers
test: yes
---

此任务介绍如何设置 `DENY` 动作中的 Istio 授权策略，以明确拒绝 Istio 网格中的流量。
这与 `ALLOW` 动作不同，因为 `DENY` 动作具有更高的优先级，不会被任何 `ALLOW` 动作绕过。

## 开始之前  {#before-you-begin}

在您开始之前，请执行以下操作：

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 根据 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 部署工作负载：

    该任务使用 `httpbin` 和 `sleep` 这两个工作负载，部署在一个命名空间 `foo` 中。
    这两个工作负载之前都运行了一个 Envoy 代理。使用以下命令部署示例命名空间和工作负载：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* 使用以下命令校验 `sleep` 任务与 `httpbin` 的对话。

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您在执行此任务时，没有看见到预期的输出，请您在几秒后重试。
缓存和传播成本可能会导致一些延迟。
{{< /warning >}}

## 明确拒绝请求  {#explicitly-deny-a-request}

1. 以下命令为 `foo` 命名空间中的 `httpbin` 工作负载创建 `deny-method-get` 授权策略。
   该授权将 `action` 设置为 `DENY`，以拒绝满足 `rules` 部分设置的条件的请求。
   该类型策略被称为“拒绝策略”。在这种情况下，如果请求方式是 `GET`，策略会拒绝请求。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. 检查 `GET` 请求是否被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. 检查是否允许 `POST` 请求：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/post" -X POST -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. 更新 `deny-method-get` 授权策略，只有当 HTTP 头中 `x-token`
   值不是 `admin` 时才会拒绝 `GET` 请求。以下的策略示例将 `notValues`
   字段的值设置为 `["admin"]`，以拒绝 HTTP 头中 `x-token` 值为非 `admin` 的请求：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.headers[x-token]
          notValues: ["admin"]
    EOF
    {{< /text >}}

1. 检查是否允许 HTTP 头 `x-token: admin` 的 `GET` 请求：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. 检查 HTTP 头 `x-token: guest` 的 GET 请求是否被拒绝：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: guest" -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. 以下命令创建 `allow-path-ip` 授权策略，允许以 `/ip` 路径向 `httpbin`
   工作负载发出请求。此授权策略设置 `action` 字段为 `ALLOW`，此类型的策略被称为“允许策略”。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-path-ip
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - to:
        - operation:
            paths: ["/ip"]
    EOF
    {{< /text >}}

1. 检查 `/ip` 中 HTTP 头中 `x-token: guest` 的 `GET` 请求会否被 `deny-method-get`
   策略拒绝。“拒绝策略”优先级高于“允许策略”：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: guest" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. 检查 `/ip` 路径中 HTTP 头 `x-token: admin` 的 `GET` 请求是否被 `allow-path-ip` 策略允许：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. 检查 `/get` 路径的 HTTP 头 `x-token: admin` 的 `GET` 请求是否被拒绝，
   因为它们与 `allow-path-ip` 策略不匹配：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

## 清理  {#clean-up}

从配置中删除命名空间 foo：

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
