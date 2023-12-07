---
title: 外部授权
description: 如何集成访问控制并将其委托给外部授权系统。
weight: 35
keywords: [security,access-control,rbac,authorization,custom, opa, oauth, oauth2-proxy]
owner: istio/wg-security-maintainers
test: yes
---

此任务介绍如何使用新的 [action](/zh/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-Action)
字段 - `CUSTOM`，设置 Istio 授权策略将访问控制委派给外部授权系统。这可以用来与
[OPA authorization](https://www.openpolicyagent.org/docs/latest/envoy-introduction/)、
[`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy) 或您自己定制的外部授权服务器集成。

## 开始之前  {#before-you-begin}

在您开始之前，请执行以下操作：

* 阅读 [Istio 授权概念](/zh/docs/concepts/security/#authorization)。

* 根据 [Istio 安装指南](/zh/docs/setup/install/istioctl/)安装 Istio。

* 部署测试工作负载：

    该任务使用两个工作负载，`httpbin` 和 `sleep`，部署在 `foo` 命名空间中。
    这两个工作负载都包含 Envoy 代理边车容器。使用以下命令部署示例命名空间和工作负载：

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label ns foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n foo
    {{< /text >}}

* 使用以下命令验证 `sleep` 是否可以访问 `httpbin`：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
如果您在执行此任务时，没有看见到预期的输出，请您在几秒后重试。缓存和传播成本可能会导致一些延迟。
{{< /warning >}}

## 部署外部授权器  {#deploy-the-external-authorizer}

首先，您需要部署一个外部授权器。为此，您只需将示例外部授权器部署在网格中的独立 Pod 中。

1. 运行以下命令以部署示例外部授权器：

    {{< text bash >}}
    $ kubectl apply -n foo -f {{< github_file >}}/samples/extauthz/ext-authz.yaml
    service/ext-authz created
    deployment.apps/ext-authz created
    {{< /text >}}

1. 验证示例外部授权器是否已启动并正在运行：

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    {{< /text >}}

或者，您也可以将外部授权器与需要外部授权的应用程序部署在同一 Pod 内，
甚至您也可以将其部署在网格之外。在这两种情况下，您还需要创建一个 ServiceEntry
资源来将服务注册到网格，并确保代理可以访问它。

以下是将外部授权器部署在需要外部授权的应用程序同一 Pod 内时，您需要配置的示例 ServiceEntry。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-authz-grpc-local
spec:
  hosts:
  - "external-authz-grpc.local" # 网格配置中的扩展提供程序中使用的服务名称
  endpoints:
  - address: "127.0.0.1"
  ports:
  - name: grpc
    number: 9191 # 网格配置中的扩展提供程序要使用的端口号
    protocol: GRPC
  resolution: STATIC
{{< /text >}}

## 定义外部授权者   {#define-the-external-authorizer}

为了使用授权策略中的 `CUSTOM` 操作，您必须定义允许在网格中使用的外部授权器。
这是目前在网格配置的[扩展提供程序](https://github.com/istio/api/blob/a205c627e4b955302bbb77dd837c8548e89e6e64/mesh/v1alpha1/config.proto#L534)中定义的。

目前，唯一支持的扩展提供程序类型是 [Envoy `ext_authz`](https://www.envoyproxy.io/docs/envoy/v1.16.2/intro/arch_overview/security/ext_authz_filter)。
外部授权者必须实现对应的 Envoy `ext_authz` 检查接口。

在本任务中，您将使用一个允许请求 Header 为 `x-ext-authz: allow`
的[示例外部授权器]({{< github_tree >}}/samples/extauthz)。

1. 使用以下命令编辑网格配置：

    {{< text bash >}}
    $ kubectl edit configmap istio -n istio-system
    {{< /text >}}

1. 在编辑器中，添加如下所示的扩展提供者定义：

    以下内容定义了使用同一个 Service `ext-authz.foo.svc.cluster.local` 的两个外部提供程序
    `sample-ext-authz-grpc` 和 `sample-ext-authz-http`。该服务实现了由 Envoy `ext_authz`
    过滤器定义的 HTTP 和 GRPC 检查 API。您将在接下来的步骤中部署该服务。

    {{< text yaml >}}
    data:
      mesh: |-
        # 添加以下内容以定义外部授权者。
        extensionProviders:
        - name: "sample-ext-authz-grpc"
          envoyExtAuthzGrpc:
            service: "ext-authz.foo.svc.cluster.local"
            port: "9000"
        - name: "sample-ext-authz-http"
          envoyExtAuthzHttp:
            service: "ext-authz.foo.svc.cluster.local"
            port: "8000"
            includeRequestHeadersInCheck: ["x-ext-authz"]
    {{< /text >}}

    或者，您可以修改扩展提供程序，以控制 EXT_AUTZ 过滤器的行为，
    例如将哪些标头发送到外部授权器、将哪些标头发送到应用程序后端、在出错时返回的状态等。

    例如，下面定义了可以与 [`oauth2-proxy`](https://github.com/oauth2-proxy/oauth2-proxy) 一起使用的扩展提供程序：

    {{< text yaml >}}
    data:
      mesh: |-
        extensionProviders:
        - name: "oauth2-proxy"
          envoyExtAuthzHttp:
            service: "oauth2-proxy.foo.svc.cluster.local"
            port: "4180" # oauth2-proxy 使用的默认端口
            includeRequestHeadersInCheck: ["authorization", "cookie"] # 检查请求中发送到 oauth2-proxy 的标头
            headersToUpstreamOnAllow: ["authorization", "path", "x-auth-request-user", "x-auth-request-email", "x-auth-request-access-token"] # 请求被允许时发送到后端应用程序的标头
            headersToDownstreamOnAllow: ["set-cookie"] # 请求被允许时发送回客户端的标头
            headersToDownstreamOnDeny: ["content-type", "set-cookie"] # 请求被拒绝时发送回客户端的标头
    {{< /text >}}

## 启用外部授权  {#enable-with-external-authorization}

现在外部授权器已准备好供授权策略使用。

1. 使用以下命令启用外部授权：

    以下命令将带有 `CUSTOM` 操作值的授权策略应用于 `httpbin` 工作负载。该策略支持使用
    `sample-ext-authz-grpc` 定义的外部授权器对指向路径 `/headers` 的请求进行外部授权。

    {{< text bash >}}
    $ kubectl apply -n foo -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: ext-authz
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: CUSTOM
      provider:
        # 提供程序名称必须与 MeshConfig 中定义的扩展提供程序匹配
        # 您还可以将其替换为 sample-ext-authz-http 以测试另一个外部授权器定义
        name: sample-ext-authz-grpc
      rules:
      # rules 指定何时触发外部授权器
      - to:
        - operation:
            paths: ["/headers"]
    EOF
    {{< /text >}}

    在运行时，`httpbin` 工作负载的 `/Headers` 路径的请求会被 `ext_authz` 过滤器暂停，
    并向外部授权者发送检查请求，以决定是允许还是拒绝该请求。

1. 验证 `ext_authz` 示例服务器拒绝了头部为 `x-ext-authz：deny` 的路径 `/headers` 的请求：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: deny" -s
    denied by ext_authz for not found header `x-ext-authz: allow` in the request
    {{< /text >}}

1. 验证 `ext_authz` 示例服务器是否允许头部为 `x-ext-authz：low` 的路径 `/headers` 的请求：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -H "x-ext-authz: allow" -s
    {
      "headers": {
        "Accept": "*/*",
        "Host": "httpbin:8000",
        "User-Agent": "curl/7.76.0-DEV",
        "X-B3-Parentspanid": "430f770aeb7ef215",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "60ff95c5acdf5288",
        "X-B3-Traceid": "fba72bb5765daf5a430f770aeb7ef215",
        "X-Envoy-Attempt-Count": "1",
        "X-Ext-Authz": "allow",
        "X-Ext-Authz-Check-Result": "allowed",
        "X-Forwarded-Client-Cert": "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=e5178ee79066bfbafb1d98044fcd0cf80db76be8714c7a4b630c7922df520bf2;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"
      }
    }
    {{< /text >}}

1. 确认允许 `/ip` 路径请求且不触发外部授权：

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. 查看 `ext_authz` 示例服务器的日志，确认它被调用了两次（针对这两次请求）。第一个被允许，第二个被拒绝：

    {{< text bash >}}
    $ kubectl logs "$(kubectl get pod -l app=ext-authz -n foo -o jsonpath={.items..metadata.name})" -n foo -c ext-authz
    2021/01/07 22:55:47 Starting HTTP server at [::]:8000
    2021/01/07 22:55:47 Starting gRPC server at [::]:9000
    2021/01/08 03:25:00 [gRPCv3][denied]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52088}}  principal:"spiffe://cluster.local/ns/foo/sa/sleep"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076306  nanos:473835000}  http:{id:"13869142855783664817"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"377ba0cdc2334270"}  headers:{key:"x-b3-traceid"  value:"635187cb20d92f62377ba0cdc2334270"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"deny"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"9609691a-4e9b-9545-ac71-3889bc2dffb0"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    2021/01/08 03:25:06 [gRPCv3][allowed]: httpbin.foo:8000/headers, attributes: source:{address:{socket_address:{address:"10.44.0.22"  port_value:52184}}  principal:"spiffe://cluster.local/ns/foo/sa/sleep"}  destination:{address:{socket_address:{address:"10.44.3.30"  port_value:80}}  principal:"spiffe://cluster.local/ns/foo/sa/httpbin"}  request:{time:{seconds:1610076300  nanos:925912000}  http:{id:"17995949296433813435"  method:"GET"  headers:{key:":authority"  value:"httpbin.foo:8000"}  headers:{key:":method"  value:"GET"}  headers:{key:":path"  value:"/headers"}  headers:{key:"accept"  value:"*/*"}  headers:{key:"content-length"  value:"0"}  headers:{key:"user-agent"  value:"curl/7.74.0-DEV"}  headers:{key:"x-b3-sampled"  value:"1"}  headers:{key:"x-b3-spanid"  value:"a66b5470e922fa80"}  headers:{key:"x-b3-traceid"  value:"300c2f2b90a618c8a66b5470e922fa80"}  headers:{key:"x-envoy-attempt-count"  value:"1"}  headers:{key:"x-ext-authz"  value:"allow"}  headers:{key:"x-forwarded-client-cert"  value:"By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=dd14782fa2f439724d271dbed846ef843ff40d3932b615da650d028db655fc8d;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/sleep"}  headers:{key:"x-forwarded-proto"  value:"http"}  headers:{key:"x-request-id"  value:"2b62daf1-00b9-97d9-91b8-ba6194ef58a4"}  path:"/headers"  host:"httpbin.foo:8000"  protocol:"HTTP/1.1"}}  metadata_context:{}
    {{< /text >}}

    您还可以从日志中看出，`ext-authz` 过滤器和 `ext-authz` 示例服务器之间的连接启用了
    mTLS，因为源主体填充了值 `spirffe：//cluster.local/ns/foo/sa/sleep`。

    现在，您可以对示例 `ext-authz` 服务器应用另一个授权策略，以控制允许谁访问它。

## 清理  {#clean-up}

1. 从配置中删除 foo 命名空间：

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

1. 从网格配置中删除扩展提供程序定义。

## 性能预期  {#performance-expectations}

请参阅[性能基准测试](https://github.com/istio/tools/tree/master/perf/benchmark/configs/istio/ext_authz)。
