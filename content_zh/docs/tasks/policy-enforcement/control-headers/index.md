---
title: 控制 header 和路由
description: 显示如何使用策略适配器修改请求 header 和路由。
weight: 20
keywords: [policies,routing]
---

此任务演示如何使用策略适配器来操作请求 header 和路由。

## 开始之前

* 按照[安装指南](/zh/docs/setup/kubernetes/)中的说明在 Kubernetes 上安装 Istio。

    {{< warning >}}
    必须在群集中为此任务启用策略实施。按照[启用策略强制执行](/zh/docs/tasks/policy-enforcement/enabling-policy/)中的步骤操作，确保已启用策略实施。
    {{< /warning >}}

* 按照 [Ingress 任务](/zh/docs/tasks/traffic-management/ingress/) 中的设置说明使用网关配置入口。

* 自定义 `httpbin` 服务的[虚拟服务](/docs/reference/config/networking/v1alpha3/virtual-service/)配置，该服务包含允许路径 `/headers` 和 `/status` 的流量的两个路由规则：

    {{< text yaml >}}
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

## 产生输出的适配器

在此任务中，我们使用示例策略适配器 `keyval`。除了策略检查结果之外，此适配器还返回一个名为 `value` 的单个字段的输出。
适配器配置有查找表，用于填充输出值，或者如果查找表中不存在输入实例键，则返回 `NOT_FOUND` 错误状态。

1. 部署演示适配器：

    {{< text bash >}}
    $ kubectl run keyval --image=gcr.io/istio-testing/keyval:release-1.1 --namespace istio-system --port 9070 --expose
    {{< /text >}}

1. 通过部署其模板和配置描述符来启用 `keyval` 适配器：

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/policy/keyval-template.yaml@
    $ kubectl apply -f @samples/httpbin/policy/keyval.yaml@
    {{< /text >}}

1. 使用固定的查找表为演示适配器创建处理程序：

    {{< text yaml >}}
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

1. 使用 header 中的 `user` 作为查找键为处理程序创建一个实例：

    {{< text yaml >}}
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

## 请求 header 操作

1. 确保可以通过入口网关访问 _httpbin_ 服务：

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

    输出应该是 _httpbin_ 服务接收的请求 header。

1. 为演示适配器创建规则：

    {{< text yaml >}}
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

1. 向入口网关发出新请求，header 中的 `key`(`user`) 的值设为 `jason`：

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

    请注意 header 中 `user-group`的存在，其值来自适配器的规则应用程序。规则中的表达式 `x.output.value` 计算为 `keyval` 适配器返回的填充的 `value` 字段。

1. 如果检查成功，请修改规则以将 URI 路径重写为其他虚拟服务路由：

    {{< text yaml >}}
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

1. 重复请求到 Ingress 网关：

    {{< text bash >}}
    $ curl -Huser:jason -I http://$INGRESS_HOST:$INGRESS_PORT/headers
    HTTP/1.1 418 Unknown
    server: istio-envoy
    ...
    {{< /text >}}

    注意，Ingress Gateway 在应用适配器策略**之后**修改了路由。被修改的请求受流量管理配置的影响，可能会发往不同的路由和目的地。

    策略引擎不会在同一代理中再次检查修改后的请求。因此我们建议在网关中使用这一功能，这样服务端的检查功能就可以继续使用了。

## 清理

删除演示适配器的策略资源：

{{< text bash >}}
$ kubectl delete rule/keyval handler/keyval instance/keyval adapter/keyval template/keyval -n istio-system
$ kubectl delete service keyval -n istio-system
$ kubectl delete deployment keyval -n istio-system
{{< /text >}}

完成 [ingress 任务](/zh/docs/tasks/traffic-management/ingress/)中的清理说明。

