---
title: 请求头和路由控制
description: 演示如何使用策略适配器修改请求头和路由。
weight: 20
keywords: [policies,routing]
---

此任务演示如何使用策略适配器来操作请求头和路由。

## 开始之前{#before-you-begin}

* 遵循[安装指南](/zh/docs/setup/)中的说明在 Kubernetes 集群上安装 Istio 。

    {{< warning >}}
    **必须** 在你的集群上启用策略检查。请按照[启用策略检查](/zh/docs/tasks/policy-enforcement/enabling-policy/)
    中的步骤操作，以确保启用了策略检查 。
    {{< /warning >}}

* 按照 [ingress 任务](/zh/docs/tasks/traffic-management/ingress/)中的设置说明，使用 Gateway 配置 ingress。

* 为 `httpbin` 服务定义一个包含两条路由规则的 [virtual service](/zh/docs/reference/config/networking/virtual-service/)，以接收来自路径 `/headers` 和 `/status` 的请求：

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - "*"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /headers
        - uri:
            prefix: /status
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

## Output-producing adapters

在此任务中，我们使用名为 `keyval` 的策略适配器。除输出策略检查结果之外，
此适配器还返回一个包含 `value` 字段的输出。适配器上配置有一个查找表，用于填充输出值，
或者在查找表中不存在输入实例键时返回 `NOT_FOUND` 错误状态。

1. 部署演示适配器：

    {{< text bash >}}
    $ kubectl run keyval --image=gcr.io/istio-testing/keyval:release-1.1 --namespace istio-system --port 9070 --expose
    {{< /text >}}

1. 通过模板和配置描述启用 `keyval` 适配器：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/policy/keyval-template.yaml@
    $ kubectl apply -f @samples/httpbin/policy/keyval.yaml@
    {{< /text >}}

1. 使用固定的查找表为演示适配器创建一个 Handler：

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: handler
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      adapter: keyval
      connection:
        address: keyval:9070
      params:
        table:
          jason: admin
    EOF
    {{< /text >}}

1. 使用 `user` 请求头作为查找键，为 Handler 创建一个 Instance：

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: instance
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      template: keyval
      params:
        key: request.headers["user"] | ""
    EOF
    {{< /text >}}

## 请求头操作{#request-header-operations}

1. 确保 _httpbin_ 服务可以通过 ingress gateway 正常访问：

    {{< text bash >}}
    $ curl http://$INGRESS_HOST:$INGRESS_PORT/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        ...
        "X-Envoy-Internal": "true"
      }
    }
    {{< /text >}}

    输出应该是 _httpbin_ 服务接收到的请求头。

1. 为演示适配器创建 Rule：

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      actions:
      - handler: keyval.istio-system
        instances: [ keyval ]
        name: x
      requestHeaderOperations:
      - name: user-group
        values: [ x.output.value ]
    EOF
    {{< /text >}}

1. 向入口网关发出新请求，将请求 `key` 设置为值 `jason`：

    {{< text bash >}}
    $ curl -Huser:jason http://$INGRESS_HOST:$INGRESS_PORT/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "User": "jason",
        "User-Agent": "curl/7.58.0",
        "User-Group": "admin",
        ...
        "X-Envoy-Internal": "true"
      }
    }
    {{< /text >}}

    请注意 `user-group` 标头，该标头派生自适配器的 Rlue 定义，Rlue 中表达式 `x.output.value` 的取值结果为适配器 `keyval` 返回值的 `value` 字段。

1. 如果匹配成功，则修改 Rule 规则，重写 URI 路径到其他 Virtual service 路由：

    {{< text bash yaml >}}
    $ kubectl apply -f - <<EOF
    apiVersion: config.istio.io/v1alpha2
    kind: rule
    metadata:
      name: keyval
      namespace: istio-system
    spec:
      match: source.labels["istio"] == "ingressgateway"
      actions:
      - handler: keyval.istio-system
        instances: [ keyval ]
      requestHeaderOperations:
      - name: :path
        values: [ '"/status/418"' ]
    EOF
    {{< /text >}}

1. 再次向 ingress gateway 发送请求：

    {{< text bash >}}
    $ curl -Huser:jason -I http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 418 Unknown
    server: istio-envoy
    ...
    {{< /text >}}

    请注意，在策略适配器的规则应用 _之后_，ingress gateway 更改了路由。修改后的请求可能使用不同的路由和目的地，并受流量管理配置的约束。

    同一代理内的策略引擎不会再次检查已修改的请求。因此，我们建议在网关中使用此功能，以便服务器端策略检查生效。

## 清理{#cleanup}

删除演示适配器的策略资源：

{{< text bash >}}
$ kubectl delete rule/keyval handler/keyval instance/keyval adapter/keyval template/keyval -n istio-system
$ kubectl delete service keyval -n istio-system
$ kubectl delete deployment keyval -n istio-system
{{< /text >}}

完成 [ingress 任务](/zh/docs/tasks/traffic-management/ingress/)中的清理说明。
